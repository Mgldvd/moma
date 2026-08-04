#!/usr/bin/env python3
"""Generate fixed-size terminal screenshots of the moma CLI.

Every command in `moma_screenshots/commands.py` is executed for real inside
a pseudo-terminal of a fixed size (see `RenderConfig`), so the resulting PNG
- one per command - always has the exact same pixel dimensions no matter how
short or long that command's actual output is: the pty (and therefore the
image) is sized in advance, not fitted to the content afterward.

Usage (via uv, from this directory):
    uv run generate.py                       # every catalog command
    uv run generate.py --list                # show what would run
    uv run generate.py --commands block box   # only these (by id suffix)
    uv run generate.py --output ../.img       # write straight into the repo docs

Requires the repo's dist/moma to be built (`../build.sh`) and the
dependencies declared in pyproject.toml (`uv sync`).
"""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent

sys.path.insert(0, str(SCRIPT_DIR))

from moma_screenshots import render  # noqa: E402
from moma_screenshots.capture import run_in_pty  # noqa: E402
from moma_screenshots.commands import COMMANDS, COMMANDS_BY_ID  # noqa: E402


def build_env(cols: int, rows: int) -> dict[str, str]:
    """A clean, deterministic environment for the captured process.

    Deliberately does not inherit NO_COLOR, MOMA_THEME, or MOMA_COLOR_* from
    the calling shell, so a screenshot always reflects moma's real defaults
    instead of whatever the machine generating it happens to have set.
    """
    keep = ("PATH", "HOME", "USER")
    env = {key: os.environ[key] for key in keep if key in os.environ}
    env.setdefault("PATH", "/usr/bin:/bin")
    env.setdefault("HOME", "/tmp")
    env["TERM"] = "xterm-256color"
    env["COLUMNS"] = str(cols)
    env["LINES"] = str(rows)
    env["LANG"] = "C.UTF-8"
    env["LC_ALL"] = "C.UTF-8"
    return env


def run_command(
    command,
    *,
    moma_dist: Path,
    cfg: render.RenderConfig,
    timeout: float,
) -> render.Image.Image:
    script = f'source "{moma_dist}"\n{command.script}\n'
    result = run_in_pty(
        script,
        cols=cfg.cols,
        rows=cfg.rows,
        cwd=str(REPO_ROOT),
        env=build_env(cfg.cols, cfg.rows),
        timeout=timeout,
    )
    if result.timed_out:
        print(f"  warning: {command.id} timed out; screenshot may be incomplete", file=sys.stderr)
    return render.render_screen(result.screen, command.title, cfg)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument(
        "--commands",
        nargs="+",
        metavar="ID",
        help="Only these commands (matched by id or id suffix, e.g. 'block' for 'moma-block'). Default: all.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=SCRIPT_DIR / "output",
        help="Output directory for PNGs (default: screenshots/output).",
    )
    parser.add_argument(
        "--moma",
        type=Path,
        default=REPO_ROOT / "dist" / "moma",
        help="Path to the built moma executable (default: ../dist/moma).",
    )
    parser.add_argument("--cols", type=int, default=render.RenderConfig.cols)
    parser.add_argument("--rows", type=int, default=render.RenderConfig.rows)
    parser.add_argument("--font-size", type=int, default=render.RenderConfig.font_size)
    parser.add_argument(
        "--timeout",
        type=float,
        default=12.0,
        help="Per-command capture timeout in seconds (default: 12).",
    )
    parser.add_argument(
        "--list", action="store_true", help="List available command ids and exit."
    )
    args = parser.parse_args()

    if args.list:
        for command in COMMANDS:
            print(command.id)
        return 0

    if not args.moma.is_file():
        print(
            f"error: {args.moma} not found - build it first with "
            f"'{REPO_ROOT}/build.sh'",
            file=sys.stderr,
        )
        return 1

    if args.commands:
        selected = []
        for wanted in args.commands:
            match = COMMANDS_BY_ID.get(wanted) or COMMANDS_BY_ID.get(f"moma-{wanted}")
            if not match:
                print(f"error: unknown command id: {wanted}", file=sys.stderr)
                return 1
            selected.append(match)
    else:
        selected = COMMANDS

    cfg = render.RenderConfig(
        cols=args.cols, rows=args.rows, font_size=args.font_size
    )
    args.output.mkdir(parents=True, exist_ok=True)

    width, height = render.canvas_size(cfg)
    print(f"Rendering {len(selected)} command(s) at a fixed {width}x{height}px...")

    for command in selected:
        image = run_command(
            command, moma_dist=args.moma, cfg=cfg, timeout=args.timeout
        )
        assert image.size == (width, height), (
            f"{command.id} produced {image.size}, expected {(width, height)}"
        )
        out_path = args.output / f"{command.id}.png"
        image.save(out_path)
        try:
            shown = out_path.resolve().relative_to(REPO_ROOT)
        except ValueError:
            shown = out_path
        print(f"  {shown}")

    print(f"Done. {len(selected)} screenshot(s) written to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
