"""
Low-level ReportLab drawing primitives, layout geometry calculations, typography
helpers, and 300-DPI artwork resampling for the Pray The Rosary print PDF pipeline.

Coordinate & Margin Notes for Non-Python Developers:
----------------------------------------------------
1. Gutter vs. Outer Margins (Recto / Verso Asymmetry):
   Because the physical book is spiral-bound along the spine:
   - Odd pages (1, 3, 5, ..., 49) are RIGHT-hand ("Recto") pages: the spiral binding
     is on their LEFT edge, so the left margin is 0.625" (45 pt) and the right margin
     is 0.500" (36 pt).
   - Even pages (2, 4, 6, ..., 50) are LEFT-hand ("Verso") pages: the spiral binding
     is on their RIGHT edge, so the left margin is 0.500" (36 pt) and the right margin
     is 0.625" (45 pt).
   - Top and bottom margins to the Master A gold border are 0.500" (36 pt) on all pages,
     producing a 4.875" x 8.000" (351 x 576 pt) gold frame on standard interior pages.

2. Paragraph Wrapping (`draw_para` and `measure_para`):
   ReportLab's low-level `canvas.drawString` does not wrap multi-line text. Instead, we
   construct a `reportlab.platypus.Paragraph` object, call `p.wrap(width, max_height)`
   to calculate how tall (`h`) the wrapped text block is, and then call `p.drawOn(c, x, top_y - h)`
   because `drawOn` expects the BOTTOM-LEFT `(x, y)` corner of the paragraph box.
"""

import io
from pathlib import Path
from typing import Any, Dict, Optional, Tuple

from PIL import Image as PILImage
from reportlab.lib.colors import HexColor
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import inch
from reportlab.lib.utils import ImageReader
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfgen import canvas
from reportlab.platypus import Paragraph

from .config import (
    BACK_GOLD,
    BACK_PRIMARY,
    BLEED,
    COLOR_CHARCOAL,
    COLOR_CRIMSON,
    COLOR_GOLD,
    COLOR_PARCHMENT,
    COLOR_UMBER,
    PAGE_H,
    PAGE_W,
    TAB_SPECS,
    PrintConfig,
)

# Bounded in-memory cache of 300-DPI resampled JPEG streams keyed by resolved file path.
# Since source paintings in `assets/2D/gimp/original_downloads/` are immutable during a build,
# caching avoids re-decoding and Lanczos-downsampling the same painting across multi-PDF batch runs.
_IMAGE_CACHE: Dict[str, Tuple[io.BytesIO, int, int]] = {}


def clear_image_cache() -> None:
    """Clears the in-memory resampled artwork cache."""
    _IMAGE_CACHE.clear()


def get_gold_box(page_num: int, cfg: Optional[PrintConfig] = None) -> Tuple[float, float, float, float]:
    """
    Returns `(x, y, w, h)` in points (origin bottom-left) for the Master A 1.5pt gold border,
    enforcing the 0.625" inner spiral-spine margin and 0.500" outer/top/bottom margins.

    - Odd pages (Recto): Inner spine margin on left (0.625" = 45 pt), outer on right (0.500" = 36 pt).
    - Even pages (Verso): Outer margin on left (0.500" = 36 pt), inner spine on right (0.625" = 45 pt).
    - In `--tabs` or `--Vervante` mode, Page 1 (Front Overhang Cover) and Page 50 (Back Overhang Cover)
      widen by `cfg.active_tab_ext` (0.375" or 0.50") so the gold border frames the full overhang cover.
    """
    active_cfg = cfg or PrintConfig.standard()

    if active_cfg.has_tabs and page_num == 1:
        ext = active_cfg.active_tab_ext
        return 0.625 * inch, 0.500 * inch, 4.875 * inch + ext, 8.000 * inch
    if active_cfg.has_tabs and page_num == 50:
        ext = active_cfg.active_tab_ext
        return -ext + 0.500 * inch, 0.500 * inch, 4.875 * inch + ext, 8.000 * inch

    if page_num % 2 == 1:
        x = 0.625 * inch  # 45.0 pt
    else:
        x = 0.500 * inch  # 36.0 pt
    y = 0.500 * inch      # 36.0 pt
    w = 4.875 * inch      # 351.0 pt
    h = 8.000 * inch      # 576.0 pt
    return x, y, w, h


def get_content_box(
    page_num: int,
    pad_x: Any = 16.0,
    pad_y: Any = 14.0,
    cfg: Any = None,
) -> Tuple[float, float, float, float]:
    """
    Returns `(cx, cy, cw, ch)` for the printable text/artwork content rectangle inset
    inside the Master A gold border by `(pad_x, pad_y)` points on each side.

    Supports both `(page_num, pad_x=16.0, pad_y=14.0, cfg=cfg)` and `(page_num, cfg, pad_x, pad_y)`
    calling conventions for convenience.
    """
    if isinstance(pad_x, PrintConfig):
        active_cfg: Optional[PrintConfig] = pad_x
        if cfg is not None:
            actual_pad_x = float(pad_y)
            actual_pad_y = float(cfg)
        elif pad_y != 14.0:
            actual_pad_x = float(pad_y)
            actual_pad_y = 14.0
        else:
            actual_pad_x = 16.0
            actual_pad_y = 14.0
    else:
        active_cfg = cfg if isinstance(cfg, PrintConfig) else None
        actual_pad_x = float(pad_x)
        actual_pad_y = float(pad_y)

    gx, gy, gw, gh = get_gold_box(page_num, active_cfg)
    return gx + actual_pad_x, gy + actual_pad_y, gw - 2 * actual_pad_x, gh - 2 * actual_pad_y


def make_style(
    name: str,
    font_name: str = "EBGaramond-Regular",
    font_size: float = 10.5,
    leading: float = 13.0,
    text_color: HexColor = COLOR_CHARCOAL,
    alignment: int = TA_LEFT,
) -> ParagraphStyle:
    """Constructs a ReportLab `ParagraphStyle` using upright EB Garamond fonts exclusively."""
    return ParagraphStyle(
        name=name,
        fontName=font_name,
        fontSize=font_size,
        leading=leading,
        textColor=text_color,
        alignment=alignment,
    )


def draw_para(
    c: canvas.Canvas,
    text: str,
    style: ParagraphStyle,
    x: float,
    top_y: float,
    width: float,
) -> float:
    """
    Wraps and draws an XML-safe `Paragraph` whose top edge aligns with `top_y`,
    returning the rendered vertical height in points so the caller can advance `top_y`.
    """
    p = Paragraph(text, style)
    _, h = p.wrap(width, 2000)
    p.drawOn(c, x, top_y - h)
    return h


def measure_para(text: str, style: ParagraphStyle, width: float) -> float:
    """Computes the wrapped vertical height of a `Paragraph` in points without drawing it."""
    p = Paragraph(text, style)
    _, h = p.wrap(width, 2000)
    return h


def draw_header_block(
    c: canvas.Canvas,
    cx: float,
    top_y: float,
    cw: float,
    subheading: str,
    heading: str,
    sub_size: float = 10.5,
    head_size: float = 17.5,
) -> float:
    """
    Renders the standard page header block (umber subheading, bold crimson title,
    and centered gold horizontal rule) and returns the total vertical height consumed.
    """
    used = 0.0
    if subheading:
        st_sub = make_style("h_sub", "EBGaramond-Regular", sub_size, sub_size * 1.25, COLOR_UMBER, TA_CENTER)
        h_s = draw_para(c, subheading, st_sub, cx + 10.0, top_y - used, cw - 20.0)
        used += h_s + 2.0
    if heading:
        st_head = make_style("h_head", "EBGaramond-Bold", head_size, head_size * 1.18, COLOR_CRIMSON, TA_CENTER)
        h_h = draw_para(c, heading, st_head, cx + 6.0, top_y - used, cw - 12.0)
        used += h_h + 5.0
    c.saveState()
    c.setStrokeColor(COLOR_GOLD)
    c.setLineWidth(0.9)
    rule_margin = cw * 0.08
    c.line(cx + rule_margin, top_y - used, cx + cw - rule_margin, top_y - used)
    c.restoreState()
    used += 7.0
    return used


def measure_header_block(
    cw: float,
    subheading: str,
    heading: str,
    sub_size: float = 10.5,
    head_size: float = 17.5,
) -> float:
    """Measures the total vertical height required by `draw_header_block` without drawing."""
    used = 0.0
    if subheading:
        st_sub = make_style("h_sub", "EBGaramond-Regular", sub_size, sub_size * 1.25, COLOR_UMBER, TA_CENTER)
        used += measure_para(subheading, st_sub, cw - 20.0) + 2.0
    if heading:
        st_head = make_style("h_head", "EBGaramond-Bold", head_size, head_size * 1.18, COLOR_CRIMSON, TA_CENTER)
        used += measure_para(heading, st_head, cw - 12.0) + 5.0
    used += 7.0
    return used


def draw_framed_image(
    c: canvas.Canvas,
    img_path: Path,
    box_x: float,
    box_y: float,
    box_w: float,
    box_h: float,
    border_color: HexColor = COLOR_GOLD,
    image_cache: Optional[Dict[str, Tuple[io.BytesIO, int, int]]] = None,
) -> None:
    """
    Renders an archival master painting centered inside `(box_x, box_y, box_w, box_h)`
    with aspect ratio preserved, resampled to 300 DPI (max 1500x2400 px for a 5"x8" frame)
    using Lanczos filtering, and framed with a 1.0pt gold border hugging the image edges.
    """
    if not img_path.exists():
        raise FileNotFoundError(f"Missing master artwork image: {img_path}")

    cache = image_cache if image_cache is not None else _IMAGE_CACHE
    cache_key = str(img_path.resolve())
    if cache_key in cache:
        buf, iw, ih = cache[cache_key]
        buf.seek(0)
    else:
        with PILImage.open(img_path) as im:
            if im.mode != "RGB":
                im = im.convert("RGB")
            orig_w, orig_h = im.size
            # Calculate max pixels needed at 300 DPI for a 5" x 8" box
            max_px_w = int(5.0 * 300)   # 1500 px
            max_px_h = int(8.0 * 300)   # 2400 px
            scale = min(max_px_w / float(orig_w), max_px_h / float(orig_h), 1.0)
            if scale < 1.0:
                new_w = max(1, int(round(orig_w * scale)))
                new_h = max(1, int(round(orig_h * scale)))
                im = im.resize((new_w, new_h), PILImage.Resampling.LANCZOS)
            buf = io.BytesIO()
            im.save(buf, format="JPEG", quality=88, optimize=True)
            iw, ih = im.size
            buf.seek(0)
            cache[cache_key] = (buf, iw, ih)

    scale_render = min(box_w / float(iw), box_h / float(ih))
    draw_w = iw * scale_render
    draw_h = ih * scale_render
    dx = box_x + (box_w - draw_w) / 2.0
    dy = box_y + (box_h - draw_h) / 2.0

    buf.seek(0)
    reader = ImageReader(buf)
    c.drawImage(reader, dx, dy, width=draw_w, height=draw_h, preserveAspectRatio=True, mask="auto")

    c.saveState()
    c.setStrokeColor(border_color)
    c.setLineWidth(1.0)
    c.rect(dx, dy, draw_w, draw_h, stroke=1, fill=0)
    c.restoreState()


def draw_master_a_background_and_border(
    c: canvas.Canvas,
    page_num: int,
    cfg: Optional[PrintConfig] = None,
) -> None:
    """
    Fills the warm parchment (`#FAF6EE`) background across the 6" x 9" interior body
    (including 0.125" bleed when applicable) and strokes the Master A 1.5pt gold border.
    """
    active_cfg = cfg or PrintConfig.standard()
    c.saveState()
    c.setFillColor(COLOR_PARCHMENT)
    if active_cfg.tabs and not active_cfg.bleed and not active_cfg.vervante:
        c.rect(0.0, 0.0, PAGE_W, PAGE_H, stroke=0, fill=1)
        if 3 <= page_num <= 48:
            c.setStrokeColor(HexColor("#D6CBB8"))
            c.setLineWidth(0.5)
            cut_x = PAGE_W if (page_num % 2 == 1) else 0.0
            c.line(cut_x, 0.0, cut_x, PAGE_H)
    else:
        c.rect(-BLEED, -BLEED, PAGE_W + 2 * BLEED, PAGE_H + 2 * BLEED, stroke=0, fill=1)
    gx, gy, gw, gh = get_gold_box(page_num, active_cfg)
    c.setStrokeColor(COLOR_GOLD)
    c.setLineWidth(1.5)
    c.rect(gx, gy, gw, gh, stroke=1, fill=0)
    c.restoreState()


def draw_tab_or_overhang(
    c: canvas.Canvas,
    page_num: int,
    cfg: Optional[PrintConfig] = None,
) -> None:
    """
    In `--tabs` or `--Vervante` mode, renders fore-edge cover overhang strips and protruding
    1/6-cut stepped index tabs:
      - Page 2 (Inside Front Cover) & Page 49 (Inside Back Cover): Deep Baroque Crimson (`#4A1215`)
        wrap-around overhang strip on the outer fore-edge with a 1.5pt gold divider at the 6.0" mark.
      - Pages in `TAB_SPECS` (Sheets 2, 3, 8, 13, 18, 23): Protruding 1/6-cut stepped index tab ear
        in Deep Baroque Crimson (`#4A1215`) with Antique Gold (`#D4AF37`) inset border and upright
        `EBGaramond-Bold` monogram (`O`, `J`, `L`, `S`, `G`, `C`) on both front (odd) and back (even) sides.
        In `--Vervante` mode, the crimson background extends the full 9.0" height (+ bleed) of the
        0.50" tab strip for Vervante's physical tab die-cutter.
    """
    active_cfg = cfg or PrintConfig.standard()
    if not active_cfg.has_tabs:
        return

    c.saveState()
    ext = active_cfg.active_tab_ext
    bleed_pad = BLEED if (active_cfg.bleed or active_cfg.vervante) else 0.0

    # 1. Inside Cover Overhang Wrap-Around Strips (Page 2 on left edge, Page 49 on right edge)
    if page_num == 2:
        c.setFillColor(BACK_PRIMARY)
        c.rect(-ext - bleed_pad, -bleed_pad, ext + bleed_pad, PAGE_H + 2 * bleed_pad, stroke=0, fill=1)
        c.setStrokeColor(BACK_GOLD)
        c.setLineWidth(1.5)
        c.line(0.0, -bleed_pad, 0.0, PAGE_H + bleed_pad)
        c.restoreState()
        return

    if page_num == 49:
        c.setFillColor(BACK_PRIMARY)
        c.rect(PAGE_W, -bleed_pad, ext + bleed_pad, PAGE_H + 2 * bleed_pad, stroke=0, fill=1)
        c.setStrokeColor(BACK_GOLD)
        c.setLineWidth(1.5)
        c.line(PAGE_W, -bleed_pad, PAGE_W, PAGE_H + bleed_pad)
        c.restoreState()
        return

    # 2. Protruding 1/6-Cut Stepped Index Tabs on Sheets 2, 3, 8, 13, 18, 23
    if page_num in TAB_SPECS:
        tab_idx, monogram = TAB_SPECS[page_num]
        bank_top = 8.500 * inch         # 612.0 pt (aligned with top of Master A gold frame)
        tab_h = (8.000 * inch) / 6.0    # 96.0 pt (1.3333" per tab)
        tab_top = bank_top - tab_idx * tab_h
        tab_bot = tab_top - tab_h
        is_odd = (page_num % 2 == 1)

        c.setFillColor(BACK_PRIMARY)
        if is_odd:
            # Protrudes on the RIGHT fore-edge (x = PAGE_W .. PAGE_W + ext)
            if active_cfg.vervante:
                # Full-length crimson strip down entire 9.0" height (+ bleed) for Vervante tab die-cutter
                c.rect(PAGE_W, -BLEED, ext + BLEED, PAGE_H + 2 * BLEED, stroke=0, fill=1)
            elif active_cfg.bleed:
                c.rect(PAGE_W, tab_bot - BLEED, ext + BLEED, tab_h + 2 * BLEED, stroke=0, fill=1)
            else:
                c.roundRect(PAGE_W - 6.0, tab_bot, ext + 6.0, tab_h, 4.5, stroke=0, fill=1)
                # Clean up the inner 6pt overlap on the parchment side
                c.setFillColor(COLOR_PARCHMENT)
                c.rect(PAGE_W - 6.5, tab_bot - 1.0, 6.5, tab_h + 2.0, stroke=0, fill=1)

            # Gold divider along 6.0" shoulder & inset gold frame inside tab ear
            c.setStrokeColor(BACK_GOLD)
            c.setLineWidth(1.5)
            c.line(PAGE_W, tab_bot, PAGE_W, tab_top)
            c.setLineWidth(1.0)
            c.roundRect(PAGE_W + 2.8, tab_bot + 3.5, ext - 5.8, tab_h - 7.0, 2.5, stroke=1, fill=0)
            center_x = PAGE_W + ext / 2.0
        else:
            # Protrudes on the LEFT fore-edge (x = -ext .. 0)
            if active_cfg.vervante:
                # Full-length crimson strip down entire 9.0" height (+ bleed) for Vervante tab die-cutter
                c.rect(-ext - BLEED, -BLEED, ext + BLEED, PAGE_H + 2 * BLEED, stroke=0, fill=1)
            elif active_cfg.bleed:
                c.rect(-ext - BLEED, tab_bot - BLEED, ext + BLEED, tab_h + 2 * BLEED, stroke=0, fill=1)
            else:
                c.roundRect(-ext, tab_bot, ext + 6.0, tab_h, 4.5, stroke=0, fill=1)
                c.setFillColor(COLOR_PARCHMENT)
                c.rect(0.0, tab_bot - 1.0, 6.5, tab_h + 2.0, stroke=0, fill=1)

            c.setStrokeColor(BACK_GOLD)
            c.setLineWidth(1.5)
            c.line(0.0, tab_bot, 0.0, tab_top)
            c.setLineWidth(1.0)
            c.roundRect(-ext + 3.0, tab_bot + 3.5, ext - 5.8, tab_h - 7.0, 2.5, stroke=1, fill=0)
            center_x = -ext / 2.0

        # Upright EBGaramond-Bold Gold Monogram (O, J, L, S, G, C)
        font_sz = 17.5
        c.setFillColor(BACK_GOLD)
        c.setFont("EBGaramond-Bold", font_sz)
        char_w = pdfmetrics.stringWidth(monogram, "EBGaramond-Bold", font_sz)
        center_y = (tab_bot + tab_top) / 2.0 - (font_sz * 0.34)
        c.drawString(center_x - char_w / 2.0, center_y, monogram)

    c.restoreState()


def draw_crop_marks(
    c: canvas.Canvas,
    trim_x: float,
    trim_y: float,
    trim_w: float,
    trim_h: float,
    cfg: Optional[PrintConfig] = None,
) -> None:
    """
    Renders 0.5pt charcoal corner crop marks at the 4 corners of the `(trim_x, trim_y, trim_w, trim_h)`
    trim rectangle, offset outwards so they never intrude into the bleed zone.
    """
    active_cfg = cfg or PrintConfig.standard()
    c.saveState()
    c.setStrokeColor(COLOR_CHARCOAL)
    c.setLineWidth(0.5)

    x0 = trim_x
    x1 = trim_x + trim_w
    y0 = trim_y
    y1 = trim_y + trim_h

    offset = BLEED if active_cfg.vervante else 4.0     # offset from trim boundary (9pt = 0.125" bleed boundary)
    length = 15.0 if active_cfg.vervante else 20.0     # length of crop mark line

    # Bottom-Left
    c.line(x0 - offset - length, y0, x0 - offset, y0)
    c.line(x0, y0 - offset - length, x0, y0 - offset)

    # Bottom-Right
    c.line(x1 + offset, y0, x1 + offset + length, y0)
    c.line(x1, y0 - offset - length, x1, y0 - offset)

    # Top-Left
    c.line(x0 - offset - length, y1, x0 - offset, y1)
    c.line(x0, y1 + offset, x0, y1 + offset + length)

    # Top-Right
    c.line(x1 + offset, y1, x1 + offset + length, y1)
    c.line(x1, y1 + offset, x1, y1 + offset + length)

    c.restoreState()
