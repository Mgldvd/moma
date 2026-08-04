"""Color resolution for captured terminal cells.

pyte reports each cell's foreground/background as either the string
``"default"``, a named ANSI color (``"red"``, ``"brightblue"``, ...), or a
6-digit hex string for 24-bit truecolor (moma emits truecolor for its pink
accent and gray muted text). This module turns any of those into an RGB
tuple, using a palette tuned to match moma's own website theme
(``web/src/styles/_tokens.scss``) so screenshots feel like part of the same
product regardless of which color scheme happens to be installed on the
machine that runs this tool.
"""

from __future__ import annotations

import re

RGB = tuple[int, int, int]

_HEX_RE = re.compile(r"^[0-9a-fA-F]{6}$")

# Terminal window chrome, matched to the moma docs site's dark theme.
BACKGROUND: RGB = (15, 32, 56)  # --terminal
FOREGROUND: RGB = (245, 241, 247)  # --terminal-ink
CHROME_BG: RGB = (13, 49, 104)  # --terminal-chrome
CHROME_INK: RGB = (143, 180, 232)  # --terminal-chrome-ink
BORDER: RGB = (47, 111, 209)  # --terminal-border
TITLE_INK: RGB = (232, 240, 252)  # bright, high-contrast title text

# Window controls: three tones of the chrome's own blue rather than the
# usual red/yellow/green traffic lights, so they read as a quiet detail
# instead of competing with the title text for attention.
CONTROL_BLUE_DARK: RGB = (34, 66, 122)
CONTROL_BLUE_MID: RGB = (66, 116, 191)
CONTROL_BLUE_LIGHT: RGB = (120, 172, 235)

# Standard 16-color ANSI palette, as named by pyte ("brown" == yellow).
ANSI16: dict[str, RGB] = {
    "black": (28, 35, 51),
    "red": (255, 118, 118),
    "green": (115, 245, 154),
    "brown": (249, 220, 102),
    "blue": (79, 139, 224),
    "magenta": (179, 137, 249),
    "cyan": (104, 228, 255),
    "white": (245, 241, 247),
    "brightblack": (107, 114, 128),
    "brightred": (255, 148, 148),
    "brightgreen": (157, 255, 192),
    "brightbrown": (255, 233, 153),
    "brightblue": (143, 180, 232),
    "brightmagenta": (217, 179, 255),
    "brightcyan": (160, 240, 255),
    "brightwhite": (255, 255, 255),
}


def resolve(value: str | None, default: RGB) -> RGB:
    """Resolve one pyte fg/bg cell value to an RGB tuple.

    ``value`` is ``None``/``"default"`` for an unset cell, a 6-digit hex
    string for a truecolor escape, or a named ANSI color otherwise.
    """
    if not value or value == "default":
        return default
    if _HEX_RE.match(value):
        return (int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16))
    return ANSI16.get(value, default)
