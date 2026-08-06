#!/usr/bin/env python3
"""Generate fixed-size terminal screenshots of the moma CLI.

Every shot in `catalog.yaml` is executed for real inside a pseudo-terminal
of a fixed size (see `RenderConfig`), so the resulting PNG - one per shot -
always has the exact same pixel dimensions no matter how short or long that
shot's actual output is: the pty (and therefore the image) is sized in
advance, not fitted to the content afterward.

Usage (via uv, from this directory):
    uv run generate.py                       # every catalog component
    uv run generate.py --list                # show what would run
    uv run generate.py --commands resume box  # only these (by id suffix)
    uv run generate.py --output ../.img       # write straight into the repo docs

After reviewing the staged output/ folder, `uv run sync.py` publishes it
into the docs site's own asset tree (`web/src/assets/screenshots/`).

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
from moma_screenshots.catalog import load_catalog_or_exit  # noqa: E402


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


def render_script(
    script: str,
    title: str,
    *,
    label: str,
    moma_dist: Path,
    cfg: render.RenderConfig,
    timeout: float,
) -> render.Image.Image:
    full_script = f'source "{moma_dist}"\n{script}\n'
    result = run_in_pty(
        full_script,
        cols=cfg.cols,
        rows=cfg.rows,
        cwd=str(REPO_ROOT),
        env=build_env(cfg.cols, cfg.rows),
        timeout=timeout,
    )
    if result.timed_out:
        print(f"  warning: {label} timed out; screenshot may be incomplete", file=sys.stderr)
    return render.render_screen(result.screen, title, cfg)


def _relative_to_repo(path: Path) -> Path:
    try:
        return path.resolve().relative_to(REPO_ROOT)
    except ValueError:
        return path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument(
        "--commands",
        nargs="+",
        metavar="ID",
        help="Only these commands (matched by id or id suffix, e.g. 'resume' for 'moma-resume'). Default: all.",
    )
    parser.add_argument(
        "--catalog",
        type=Path,
        default=SCRIPT_DIR / "catalog.yaml",
        help="Path to the screenshot catalog (default: screenshots/catalog.yaml).",
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

    components = load_catalog_or_exit(args.catalog)
    components_by_id = {component.id: component for component in components}

    if args.list:
        for component in components:
            print(component.id)
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
            match = components_by_id.get(wanted) or components_by_id.get(f"moma-{wanted}")
            if not match:
                print(f"error: unknown command id: {wanted}", file=sys.stderr)
                return 1
            selected.append(match)
    else:
        selected = components

    cfg = render.RenderConfig(
        cols=args.cols, rows=args.rows, font_size=args.font_size
    )
    args.output.mkdir(parents=True, exist_ok=True)

    width, height = render.canvas_size(cfg)
    print(f"Rendering {len(selected)} component(s) at a fixed {width}x{height}px...")

    complementary_total = 0
    for component in selected:
        principal_shot = component.principal_shot
        image = render_script(
            "\n".join(principal_shot.commands), component.title, label=component.id,
            moma_dist=args.moma, cfg=cfg, timeout=args.timeout,
        )
        assert image.size == (width, height), (
            f"{component.id} produced {image.size}, expected {(width, height)}"
        )
        out_path = args.output / f"{component.id}.png"
        image.save(out_path)
        print(f"  {_relative_to_repo(out_path)}")

        complementary_shots = component.complementary_shots
        if complementary_shots:
            shot_dir = args.output / "carousel" / component.id
            shot_dir.mkdir(parents=True, exist_ok=True)
            for index, shot in enumerate(complementary_shots):
                shot_image = render_script(
                    "\n".join(shot.commands), component.title, label=f"{component.id} shot {index}",
                    moma_dist=args.moma, cfg=cfg, timeout=args.timeout,
                )
                assert shot_image.size == (width, height), (
                    f"{component.id} shot {index} produced {shot_image.size}, expected {(width, height)}"
                )
                shot_path = shot_dir / f"{index}.png"
                shot_image.save(shot_path)
                print(f"  {_relative_to_repo(shot_path)}")
                complementary_total += 1

    print(
        f"Done. {len(selected)} screenshot(s)"
        + (f" + {complementary_total} carousel frame(s)" if complementary_total else "")
        + f" written to {args.output}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
