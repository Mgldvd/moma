"""Load the screenshot catalog from `catalog.yaml`.

A component is one moma CLI feature (`moma-msg-simple`, `moma-resume`, ...).
Each component has one or more `Shot`s - a shot is a group of one or more
commands rendered together, as real shell source after `source dist/moma`,
into a single screenshot. Exactly one shot per component is `principal`
(its screenshot is embedded in README.md, docs/moma-docs.md, and is always
the docs site's carousel frame 0); every other shot is "complementary" and
becomes an additional carousel frame there. See `catalog.yaml`'s own header
comment for the full schema.
"""

from __future__ import annotations

import sys
from dataclasses import dataclass
from pathlib import Path

import yaml


@dataclass(frozen=True)
class Shot:
    commands: tuple[str, ...]
    principal: bool = False


@dataclass(frozen=True)
class Component:
    id: str
    title: str
    shots: tuple[Shot, ...]

    @property
    def principal_shot(self) -> Shot:
        return next(shot for shot in self.shots if shot.principal)

    @property
    def complementary_shots(self) -> tuple[Shot, ...]:
        return tuple(shot for shot in self.shots if not shot.principal)


class CatalogError(ValueError):
    """Raised for a malformed or invalid catalog.yaml."""


def _load_shot(raw: dict, *, component_id: str, shot_index: int) -> Shot:
    commands = raw.get("commands")
    if not isinstance(commands, list) or not commands:
        raise CatalogError(
            f"{component_id}: shot {shot_index} must have a non-empty 'commands' list"
        )
    if not all(isinstance(command, str) and command.strip() for command in commands):
        raise CatalogError(
            f"{component_id}: shot {shot_index} has a blank or non-string command"
        )
    return Shot(commands=tuple(commands), principal=bool(raw.get("principal", False)))


def _load_component(raw: dict) -> Component:
    component_id = raw.get("id")
    title = raw.get("title")
    if not isinstance(component_id, str) or not component_id:
        raise CatalogError(f"component is missing a string 'id': {raw!r}")
    if not isinstance(title, str) or not title:
        raise CatalogError(f"{component_id}: missing a string 'title'")

    raw_shots = raw.get("shots")
    if not isinstance(raw_shots, list) or not raw_shots:
        raise CatalogError(f"{component_id}: must have a non-empty 'shots' list")

    shots = tuple(
        _load_shot(raw_shot, component_id=component_id, shot_index=index)
        for index, raw_shot in enumerate(raw_shots)
    )
    principal_count = sum(1 for shot in shots if shot.principal)
    if principal_count != 1:
        raise CatalogError(
            f"{component_id}: expected exactly one shot with 'principal: true', "
            f"found {principal_count}"
        )
    return Component(id=component_id, title=title, shots=shots)


def load_catalog(path: Path) -> list[Component]:
    """Parse and validate `path` (catalog.yaml) into a list of Components.

    Raises CatalogError on any schema violation - unknown/missing fields,
    duplicate ids, a shot with no commands, or a component that doesn't have
    exactly one principal shot - so a bad edit to catalog.yaml fails loudly
    instead of silently producing a mismatched catalog.
    """
    try:
        raw = yaml.safe_load(path.read_text())
    except OSError as error:
        raise CatalogError(f"could not read {path}: {error}") from error
    except yaml.YAMLError as error:
        raise CatalogError(f"{path} is not valid YAML: {error}") from error

    raw_components = (raw or {}).get("components")
    if not isinstance(raw_components, list) or not raw_components:
        raise CatalogError(f"{path}: must have a non-empty top-level 'components' list")

    components = [_load_component(raw_component) for raw_component in raw_components]

    seen_ids: set[str] = set()
    for component in components:
        if component.id in seen_ids:
            raise CatalogError(f"duplicate component id: {component.id}")
        seen_ids.add(component.id)

    return components


def load_catalog_or_exit(path: Path) -> list[Component]:
    """Like `load_catalog`, but prints a clear error and exits instead of
    raising - the convenience entry point for CLI scripts."""
    try:
        return load_catalog(path)
    except CatalogError as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(1) from error
