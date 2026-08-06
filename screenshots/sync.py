#!/usr/bin/env python3
"""Publish staged screenshots into the docs site's asset tree.

`generate.py` writes into a staging folder (`output/` by default) so new or
changed screenshots can be reviewed before they reach the site. Once that
review is done, this script copies the reviewed files into
`web/src/assets/screenshots/` - the flat `<id>.png` per component plus its
`carousel/<id>/<index>.png` complementary shots, exactly as
`web/src/data/screenshots.ts` expects them - which is a separate, deliberate
step from generating them.

Usage (via uv, from this directory):
    uv run sync.py                # output/ -> ../web/src/assets/screenshots
    uv run sync.py --dry-run      # show what would change, copy nothing
    uv run sync.py --prune        # also delete destination files with no
                                   # matching source (e.g. after removing a
                                   # component or shrinking a component's
                                   # complementary shot count)
"""

from __future__ import annotations

import argparse
import filecmp
import shutil
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent


def _relative_to_repo(path: Path) -> Path:
    try:
        return path.resolve().relative_to(REPO_ROOT)
    except ValueError:
        return path


def _catalog_pngs(root: Path) -> list[Path]:
    """Every screenshot PNG under `root`, relative to `root`: the flat
    `<id>.png` files plus the whole `carousel/` subtree - the same two file
    sets `web/src/data/screenshots.ts` globs for."""
    top_level = sorted(path.relative_to(root) for path in root.glob("*.png"))
    carousel = sorted(path.relative_to(root) for path in root.glob("carousel/*/*.png"))
    return [*top_level, *carousel]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument(
        "--source",
        type=Path,
        default=SCRIPT_DIR / "output",
        help="Staged screenshots to publish (default: screenshots/output).",
    )
    parser.add_argument(
        "--dest",
        type=Path,
        default=REPO_ROOT / "web" / "src" / "assets" / "screenshots",
        help="Docs site asset directory (default: web/src/assets/screenshots).",
    )
    parser.add_argument(
        "--dry-run", action="store_true", help="Show what would change without copying or deleting."
    )
    parser.add_argument(
        "--prune",
        action="store_true",
        help="Also delete destination files with no corresponding source file.",
    )
    args = parser.parse_args()

    if not args.source.is_dir():
        print(
            f"error: {args.source} does not exist - run generate.py first",
            file=sys.stderr,
        )
        return 1

    source_files = _catalog_pngs(args.source)
    if not source_files:
        print(f"error: no PNGs found under {args.source}", file=sys.stderr)
        return 1

    args.dest.mkdir(parents=True, exist_ok=True)

    added = updated = unchanged = 0
    for relative_path in source_files:
        src_path = args.source / relative_path
        dst_path = args.dest / relative_path

        if not dst_path.exists():
            action, added = "add", added + 1
        elif not filecmp.cmp(src_path, dst_path, shallow=False):
            action, updated = "update", updated + 1
        else:
            unchanged += 1
            continue

        print(f"  {action} {_relative_to_repo(dst_path)}")
        if not args.dry_run:
            dst_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src_path, dst_path)

    removed = 0
    if args.prune:
        source_set = set(source_files)
        dest_files = _catalog_pngs(args.dest)
        for relative_path in dest_files:
            if relative_path in source_set:
                continue
            dst_path = args.dest / relative_path
            print(f"  remove {_relative_to_repo(dst_path)}")
            removed += 1
            if not args.dry_run:
                dst_path.unlink()

        if not args.dry_run:
            for carousel_dir in sorted(args.dest.glob("carousel/*"), reverse=True):
                if carousel_dir.is_dir() and not any(carousel_dir.iterdir()):
                    carousel_dir.rmdir()

    verb = "Would change" if args.dry_run else "Changed"
    print(
        f"{verb}: {added} added, {updated} updated, {removed} removed "
        f"({unchanged} already up to date)."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
