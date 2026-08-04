"""Render a captured pyte terminal screen into a framed PNG image.

The output size is a pure function of the render config (columns, rows,
font size, padding) - never of how much text a command actually produced.
Short output leaves blank terminal rows; output that overflows the
configured rows scrolls off the top exactly as it would in a real terminal.
That is what guarantees every generated screenshot is pixel-identical in
size for a given config, regardless of the command behind it.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

from . import palette

ASSETS_DIR = Path(__file__).resolve().parent.parent / "assets" / "fonts"
FONT_REGULAR = ASSETS_DIR / "DejaVuSansMono.ttf"
FONT_BOLD = ASSETS_DIR / "DejaVuSansMono-Bold.ttf"

# Margin reserved around the window for its drop shadow, at 1x scale. Shared
# by canvas_size() and render_screen() so their size math can never drift
# apart.
SHADOW_MARGIN = 24


@dataclass(frozen=True)
class RenderConfig:
    # Wide/tall enough for the tallest (moma-multi-select-groups, ~20 lines)
    # and widest (moma-block, ~66 columns) entries in the command catalog,
    # with a little headroom - see screenshots/README.md for how this was
    # measured.
    cols: int = 84
    rows: int = 23
    font_size: int = 16
    line_height: float = 1.45
    pad_x: int = 22
    pad_top: int = 28
    pad_bottom: int = 18
    titlebar_height: int = 42
    corner_radius: int = 14
    supersample: int = 2
    shadow: bool = True


def _cell_metrics(
    font: ImageFont.FreeTypeFont, font_size: int, cfg: RenderConfig
) -> tuple[int, int]:
    cell_width = round(font.getlength("M"))
    cell_height = round(font_size * cfg.line_height)
    return cell_width, cell_height


def canvas_size(cfg: RenderConfig) -> tuple[int, int]:
    """The fixed pixel size every screenshot produced with `cfg` will have."""
    font = ImageFont.truetype(str(FONT_REGULAR), cfg.font_size)
    cell_width, cell_height = _cell_metrics(font, cfg.font_size, cfg)
    shadow_margin = SHADOW_MARGIN if cfg.shadow else 0
    width = cell_width * cfg.cols + cfg.pad_x * 2 + shadow_margin * 2
    height = (
        cfg.titlebar_height
        + cell_height * cfg.rows
        + cfg.pad_top
        + cfg.pad_bottom
        + shadow_margin * 2
    )
    return width, height


# Unicode Block Elements moma paints with (pagga ASCII art in header.sh).
# General-purpose fonts like DejaVu Sans Mono hint these with a hair of
# internal padding, which leaves visible seams between adjacent cells; real
# terminal emulators special-case this block and draw it edge-to-edge
# instead of trusting the font's own glyph outlines. We do the same: full,
# half, and shaded blocks are drawn as plain filled rectangles sized to the
# cell, not rendered as font glyphs.
_BLOCK_HALVES = {
    "█": (0.0, 0.0, 1.0, 1.0),  # █ full block
    "▀": (0.0, 0.0, 1.0, 0.5),  # ▀ upper half
    "▄": (0.0, 0.5, 1.0, 1.0),  # ▄ lower half
    "▌": (0.0, 0.0, 0.5, 1.0),  # ▌ left half
    "▐": (0.5, 0.0, 1.0, 1.0),  # ▐ right half
}
_BLOCK_SHADES = {
    "░": 0.25,  # ░ light shade
    "▒": 0.50,  # ▒ medium shade
    "▓": 0.75,  # ▓ dark shade
}
# U+23BA HORIZONTAL SCAN LINE-1 (moma-rabbit's ground line) is outside
# DejaVu Sans Mono's coverage and would otherwise render as a tofu box; draw
# it as the thin line near the top of the cell its name describes.
_SCAN_LINE_1 = "⎺"


def _draw_block_glyph(draw, cx, cy, cell_w, cell_h, data, fg, bg) -> bool:
    """Draw one Block Elements glyph as geometry. Returns False for any
    other character, leaving it to the caller's normal font rendering."""
    box = _BLOCK_HALVES.get(data)
    if box is not None:
        x0, y0, x1, y1 = box
        draw.rectangle(
            [
                cx + x0 * cell_w,
                cy + y0 * cell_h,
                cx + x1 * cell_w - 1,
                cy + y1 * cell_h - 1,
            ],
            fill=(*fg, 255),
        )
        return True

    alpha = _BLOCK_SHADES.get(data)
    if alpha is not None:
        base = bg if bg is not None else palette.BACKGROUND
        blended = tuple(
            round(base[i] + (fg[i] - base[i]) * alpha) for i in range(3)
        )
        draw.rectangle(
            [cx, cy, cx + cell_w - 1, cy + cell_h - 1],
            fill=(*blended, 255),
        )
        return True

    if data == _SCAN_LINE_1:
        line_y = cy + cell_h * 0.12
        draw.line(
            [(cx, line_y), (cx + cell_w, line_y)],
            fill=(*fg, 255),
            width=max(1, round(cell_h * 0.08)),
        )
        return True

    return False


def render_screen(screen, title: str, cfg: RenderConfig) -> Image.Image:
    """Render one pyte Screen into a titled terminal-window PNG.

    Layout (cell size, padding, final canvas size) is always computed at
    1x - exactly matching `canvas_size()` - and only then multiplied up by
    the supersample factor for internal rendering. Fonts are loaded at the
    supersampled point size purely for crisper glyphs; they never feed back
    into the layout math, so the downsampled result is always exactly the
    size `canvas_size()` predicted, never off by a stray rounding pixel.
    """
    scale = max(1, cfg.supersample)
    base_font = ImageFont.truetype(str(FONT_REGULAR), cfg.font_size)
    cell_width_1x, cell_height_1x = _cell_metrics(base_font, cfg.font_size, cfg)
    cell_width = cell_width_1x * scale
    cell_height = cell_height_1x * scale

    font = ImageFont.truetype(str(FONT_REGULAR), cfg.font_size * scale)
    bold_font = ImageFont.truetype(str(FONT_BOLD), cfg.font_size * scale)

    pad_x = cfg.pad_x * scale
    pad_top = cfg.pad_top * scale
    pad_bottom = cfg.pad_bottom * scale
    titlebar_h = cfg.titlebar_height * scale
    radius = cfg.corner_radius * scale

    grid_w = cell_width * cfg.cols
    grid_h = cell_height * cfg.rows
    win_w = grid_w + pad_x * 2
    win_h = titlebar_h + grid_h + pad_top + pad_bottom

    shadow_margin = (SHADOW_MARGIN * scale) if cfg.shadow else 0
    canvas_w = win_w + shadow_margin * 2
    canvas_h = win_h + shadow_margin * 2

    canvas = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))

    if cfg.shadow:
        shadow_layer = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
        shadow_draw = ImageDraw.Draw(shadow_layer)
        shadow_draw.rounded_rectangle(
            [
                shadow_margin,
                shadow_margin + 6 * scale,
                shadow_margin + win_w,
                shadow_margin + win_h + 6 * scale,
            ],
            radius=radius,
            fill=(0, 0, 0, 110),
        )
        shadow_layer = shadow_layer.filter(
            ImageFilter.GaussianBlur(radius=8 * scale)
        )
        canvas.alpha_composite(shadow_layer)

    window = Image.new("RGBA", (win_w, win_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(window)

    # Window body.
    draw.rounded_rectangle(
        [0, 0, win_w - 1, win_h - 1],
        radius=radius,
        fill=(*palette.BACKGROUND, 255),
        outline=(*palette.BORDER, 255),
        width=max(1, scale),
    )

    # Title bar, clipped to the window's rounded top corners.
    titlebar = Image.new("RGBA", (win_w, win_h), (0, 0, 0, 0))
    tb_draw = ImageDraw.Draw(titlebar)
    tb_draw.rounded_rectangle(
        [0, 0, win_w - 1, win_h - 1],
        radius=radius,
        fill=(*palette.CHROME_BG, 255),
    )
    mask = Image.new("L", (win_w, win_h), 0)
    ImageDraw.Draw(mask).rectangle([0, 0, win_w, titlebar_h], fill=255)
    window.paste(titlebar, (0, 0), mask)
    draw.line(
        [(0, titlebar_h), (win_w, titlebar_h)],
        fill=(*palette.BORDER, 255),
        width=max(1, scale),
    )

    # Window controls: three quiet blue tones, right-aligned, rather than
    # loud macOS-style traffic lights competing with the title for
    # attention.
    dot_r = 5 * scale
    dot_y = titlebar_h // 2
    dot_gap = 18 * scale
    right_margin = 20 * scale
    dot_x0 = win_w - right_margin - 2 * dot_gap
    for i, color in enumerate(
        (
            palette.CONTROL_BLUE_DARK,
            palette.CONTROL_BLUE_MID,
            palette.CONTROL_BLUE_LIGHT,
        )
    ):
        cx = dot_x0 + i * dot_gap
        draw.ellipse(
            [cx - dot_r, dot_y - dot_r, cx + dot_r, dot_y + dot_r],
            fill=(*color, 255),
        )

    # Command title, left-aligned and bright so it reads clearly now that
    # the controls no longer anchor the bar's left edge.
    if title:
        title_font = ImageFont.truetype(str(FONT_BOLD), round(cfg.font_size * 0.95 * scale))
        bbox = draw.textbbox((0, 0), title, font=title_font)
        tx = pad_x
        ty = (titlebar_h - (bbox[3] - bbox[1])) / 2 - bbox[1]
        draw.text((tx, ty), title, font=title_font, fill=(*palette.TITLE_INK, 255))

    # Terminal content grid, top-aligned just below the title bar - matches
    # where a real terminal starts printing.
    origin_x = pad_x
    origin_y = titlebar_h + pad_top
    for y in range(cfg.rows):
        line = screen.buffer[y]
        for x in range(cfg.cols):
            char = line[x]
            data = char.data
            has_bg = char.bg not in (None, "default")
            if not data or data == " ":
                if not (has_bg or char.reverse):
                    continue

            fg = palette.resolve(char.fg, palette.FOREGROUND)
            bg = palette.resolve(char.bg, palette.BACKGROUND) if has_bg else None
            if char.reverse:
                fg, bg = (bg or palette.BACKGROUND), fg

            cx = origin_x + x * cell_width
            cy = origin_y + y * cell_height

            if bg is not None:
                draw.rectangle(
                    [cx, cy, cx + cell_width - 1, cy + cell_height - 1],
                    fill=(*bg, 255),
                )

            if not data or data == " ":
                continue

            if _draw_block_glyph(draw, cx, cy, cell_width, cell_height, data, fg, bg):
                continue

            glyph_font = bold_font if char.bold else font
            draw.text((cx, cy), data, font=glyph_font, fill=(*fg, 255))
            if char.underscore:
                underline_y = cy + cell_height - max(1, scale)
                draw.line(
                    [(cx, underline_y), (cx + cell_width, underline_y)],
                    fill=(*fg, 255),
                    width=max(1, scale),
                )

    canvas.alpha_composite(window, (shadow_margin, shadow_margin))

    if scale > 1:
        canvas = canvas.resize(
            (canvas_w // scale, canvas_h // scale), Image.LANCZOS
        )
    return canvas
