"""Run a shell script inside a real pseudo-terminal and capture its output.

This is the piece that makes the screenshots honest: nothing here renders
text by hand. A bash process is attached to one end of a real pty, the moma
CLI runs inside it exactly as it would in a user's own terminal, and every
byte it writes - including the raw ANSI it uses for color, cursor movement,
and redraws - is read back and fed to a terminal emulator (pyte) to work out
what would actually be on screen once the program exits.

The pty is opened at a fixed, caller-chosen size (columns x rows) before the
process ever starts, and `COLUMNS`/`LINES` are exported to match. moma sizes
its own decorations (box width, scroll windows, ...) from that size, so
every capture happens inside an identically shaped terminal no matter how
much or how little a given command prints - which is what lets the renderer
produce identically sized images for every command.
"""

from __future__ import annotations

import fcntl
import os
import pty
import select
import struct
import subprocess
import termios
import time
from dataclasses import dataclass

import pyte


@dataclass
class CaptureResult:
    screen: pyte.Screen
    raw_bytes: bytes
    timed_out: bool


def _set_winsize(fd: int, rows: int, cols: int) -> None:
    packed = struct.pack("HHHH", rows, cols, 0, 0)
    fcntl.ioctl(fd, termios.TIOCSWINSZ, packed)


def run_in_pty(
    script: str,
    *,
    cols: int,
    rows: int,
    cwd: str,
    env: dict[str, str],
    timeout: float = 12.0,
) -> CaptureResult:
    """Execute `script` under bash inside a fresh pty sized cols x rows.

    Returns the settled pyte.Screen once the process exits (or once
    `timeout` elapses, whichever comes first).
    """
    master_fd, slave_fd = pty.openpty()
    _set_winsize(slave_fd, rows, cols)

    process = subprocess.Popen(
        ["bash", "-c", script],
        stdin=slave_fd,
        stdout=slave_fd,
        stderr=slave_fd,
        cwd=cwd,
        env=env,
        start_new_session=True,
    )
    # The child inherited its own copy; the parent must not keep this end
    # open or it will never see EOF once the child exits.
    os.close(slave_fd)

    chunks: list[bytes] = []
    deadline = time.monotonic() + timeout
    timed_out = False
    while True:
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            timed_out = True
            break
        ready, _, _ = select.select([master_fd], [], [], remaining)
        if not ready:
            timed_out = True
            break
        try:
            chunk = os.read(master_fd, 65536)
        except OSError:
            # The kernel raises EIO once the last writer (the child) has
            # closed its end - the normal, expected way this loop ends.
            break
        if not chunk:
            break
        chunks.append(chunk)

    if timed_out:
        try:
            os.killpg(process.pid, 15)
        except ProcessLookupError:
            pass

    try:
        process.wait(timeout=5)
    except subprocess.TimeoutExpired:
        try:
            os.killpg(process.pid, 9)
        except ProcessLookupError:
            pass
        process.wait(timeout=5)

    os.close(master_fd)

    raw = b"".join(chunks)
    screen = pyte.Screen(cols, rows)
    stream = pyte.Stream(screen)
    stream.feed(raw.decode("utf-8", errors="replace"))
    return CaptureResult(screen=screen, raw_bytes=raw, timed_out=timed_out)
