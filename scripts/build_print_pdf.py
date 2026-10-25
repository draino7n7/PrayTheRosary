"""
Automated 50-page 6" x 9" print PDF generator for Pray The Rosary.

Compiles canonical book content directly from:
  - game/data/book_layout.json
  - game/data/prayers.json
  - game/data/mysteries.json
  - game/project.godot (reading application/config/version)
  - assets/2D/gimp/original_downloads/ (300 DPI master paintings)
  - game/assets/fonts/EBGaramond-Regular.ttf & EBGaramond-Bold.ttf (zero italic fonts)

Supports:
  - Default: 6.0" x 9.0" (432 x 648 pt) 50-page print PDF -> assets/print/PrayTheRosary.pdf
  - --bleed: 6.25" x 9.25" (450 x 666 pt) pages with 0.125" bleed, setting PDF TrimBox and BleedBox
  - --office-depot / --letter: Centers 6" x 9" pages with 0.125" bleed and crop marks on 8.5" x 11.0" US Letter
"""

import argparse
import io
import json
import re
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import pymupdf
from PIL import Image as PILImage
from reportlab.lib.colors import HexColor
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT, TA_RIGHT
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import inch
from reportlab.lib.utils import ImageReader
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas
from reportlab.platypus import Paragraph

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent
FONTS_DIR = PROJECT_ROOT / "game" / "assets" / "fonts"
DATA_DIR = PROJECT_ROOT / "game" / "data"
ARTWORK_DIR = PROJECT_ROOT / "assets" / "2D" / "gimp" / "original_downloads"
DEFAULT_OUTPUT_PDF = PROJECT_ROOT / "assets" / "print" / "PrayTheRosary.pdf"
DEFAULT_OFFICE_DEPOT_PDF = PROJECT_ROOT / "assets" / "print" / "PrayTheRosary_OfficeDepot.pdf"

# Register upright EB Garamond fonts ONLY. Zero italic fonts anywhere.
pdfmetrics.registerFont(TTFont("EBGaramond-Regular", str(FONTS_DIR / "EBGaramond-Regular.ttf")))
pdfmetrics.registerFont(TTFont("EBGaramond-Bold", str(FONTS_DIR / "EBGaramond-Bold.ttf")))
pdfmetrics.registerFontFamily(
    "EBGaramond-Regular",
    normal="EBGaramond-Regular",
    bold="EBGaramond-Bold",
    italic="EBGaramond-Regular",
    boldItalic="EBGaramond-Bold",
)
pdfmetrics.registerFontFamily(
    "EBGaramond-Bold",
    normal="EBGaramond-Bold",
    bold="EBGaramond-Bold",
    italic="EBGaramond-Bold",
    boldItalic="EBGaramond-Bold",
)

# Color Palette
COLOR_PARCHMENT = HexColor("#FAF6EE")
COLOR_PARCHMENT_BOX = HexColor("#EDE3CE")
COLOR_GOLD = HexColor("#B89130")
COLOR_CRIMSON = HexColor("#6B1D21")
COLOR_CHARCOAL = HexColor("#1E1815")
COLOR_UMBER = HexColor("#5C4338")

# Cover / Back Cover Crimson Palette
BACK_PRIMARY = HexColor("#4A1215")
BACK_SECONDARY_BOX = HexColor("#2A090B")
BACK_GOLD = HexColor("#D4AF37")
BACK_IVORY = HexColor("#F7F2E7")

# Page Dimensions (in points: 72 points per inch)
PAGE_W = 6.0 * inch       # 432.0 pt
PAGE_H = 9.0 * inch       # 648.0 pt
BLEED = 0.125 * inch      # 9.0 pt

LETTER_W = 8.5 * inch     # 612.0 pt
LETTER_H = 11.0 * inch    # 792.0 pt

_IMAGE_CACHE: Dict[str, Tuple[io.BytesIO, int, int]] = {}


def get_project_version(root_dir: Path) -> str:
    """Dynamically extracts application/config/version from game/project.godot."""
    godot_file = root_dir / "game" / "project.godot"
    if godot_file.exists():
        content = godot_file.read_text(encoding="utf-8")
        match = re.search(r'config/version="([^"]+)"', content)
        if match:
            return match.group(1).strip()
    return "0.2.2"


def get_gold_box(page_num: int) -> Tuple[float, float, float, float]:
    """
    Returns (x, y, w, h) in points (origin bottom-left) for the Master A gold border
    matching 0.625" inner spiral spine margin and 0.500" outer/top/bottom margins.
    Odd pages (Recto): Inner margin on left (0.625" = 45 pt), outer on right (0.5" = 36 pt).
    Even pages (Verso): Outer margin on left (0.5" = 36 pt), inner on right (0.625" = 45 pt).
    """
    if page_num % 2 == 1:
        x = 0.625 * inch  # 45 pt
    else:
        x = 0.500 * inch  # 36 pt
    y = 0.500 * inch      # 36 pt
    w = 4.875 * inch      # 351 pt
    h = 8.000 * inch      # 576 pt
    return x, y, w, h


def get_content_box(page_num: int, pad_x: float = 16.0, pad_y: float = 14.0) -> Tuple[float, float, float, float]:
    """Returns the printable text content rectangle inside the gold border."""
    gx, gy, gw, gh = get_gold_box(page_num)
    return gx + pad_x, gy + pad_y, gw - 2 * pad_x, gh - 2 * pad_y


def make_style(
    name: str,
    font_name: str = "EBGaramond-Regular",
    font_size: float = 10.5,
    leading: float = 13.0,
    text_color: HexColor = COLOR_CHARCOAL,
    alignment: int = TA_LEFT,
) -> ParagraphStyle:
    """Helper to construct a ParagraphStyle using upright EB Garamond fonts."""
    return ParagraphStyle(
        name=name,
        fontName=font_name,
        fontSize=font_size,
        leading=leading,
        textColor=text_color,
        alignment=alignment,
    )


def draw_para(c: canvas.Canvas, text: str, style: ParagraphStyle, x: float, top_y: float, width: float) -> float:
    """Draws a paragraph below top_y and returns the rendered height."""
    p = Paragraph(text, style)
    _, h = p.wrap(width, 2000)
    p.drawOn(c, x, top_y - h)
    return h


def measure_para(text: str, style: ParagraphStyle, width: float) -> float:
    """Computes the rendered height of a paragraph without drawing it."""
    p = Paragraph(text, style)
    _, h = p.wrap(width, 2000)
    return h


def draw_master_a_background_and_border(c: canvas.Canvas, page_num: int) -> None:
    """Fills the parchment background with full bleed and draws the 1.5pt gold framing rectangle."""
    c.saveState()
    c.setFillColor(COLOR_PARCHMENT)
    c.rect(-BLEED, -BLEED, PAGE_W + 2 * BLEED, PAGE_H + 2 * BLEED, stroke=0, fill=1)
    gx, gy, gw, gh = get_gold_box(page_num)
    c.setStrokeColor(COLOR_GOLD)
    c.setLineWidth(1.5)
    c.rect(gx, gy, gw, gh, stroke=1, fill=0)
    c.restoreState()


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
    """Renders the standard top header block with subheading, crimson title, and gold rule."""
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
    cw: float, subheading: str, heading: str, sub_size: float = 10.5, head_size: float = 17.5
) -> float:
    """Measures total vertical height needed for the header block."""
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
) -> None:
    """
    Renders an archival master painting scaled with aspect ratio preserved,
    compressed using 300-DPI JPEG resampling, and framed with a 1.0pt gold border.
    """
    if not img_path.exists():
        raise FileNotFoundError(f"Missing master artwork image: {img_path}")

    cache_key = str(img_path.resolve())
    if cache_key in _IMAGE_CACHE:
        buf, iw, ih = _IMAGE_CACHE[cache_key]
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
            _IMAGE_CACHE[cache_key] = (buf, iw, ih)

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


def load_all_data(project_root: Path) -> Tuple[Dict[str, Any], Dict[str, Any], Dict[str, Any], Dict[str, Any], Dict[str, Any]]:
    """Loads all canonical JSON data files and cross-indexes artwork attributions."""
    data_dir = project_root / "game" / "data"
    with open(data_dir / "book_layout.json", "r", encoding="utf-8") as f:
        book_layout = json.load(f)
    with open(data_dir / "prayers.json", "r", encoding="utf-8") as f:
        prayers = json.load(f)["prayers"]
    with open(data_dir / "mysteries.json", "r", encoding="utf-8") as f:
        mysteries_raw = json.load(f)

    mysteries_by_id = {}
    artworks_by_id = {}
    ordinal_map = {1: "1st", 2: "2nd", 3: "3rd", 4: "4th", 5: "5th"}

    for mset in mysteries_raw["mystery_sets"]:
        short_title = mset.get("short_title", "").strip()
        for dec in mset["decades"]:
            mid = dec["id"]
            mysteries_by_id[mid] = dec
            art = dict(dec.get("artwork", {}))
            if art:
                dnum = int(dec.get("decade_number", 1))
                dtitle = dec.get("title", "").strip()
                art["section_label"] = f"{ordinal_map.get(dnum, f'{dnum}th')} {short_title} Mystery ({dtitle})"
                artworks_by_id[art.get("id", mid)] = art

    cover_art = dict(book_layout["front_cover"]["artwork"])
    cover_art["section_label"] = "Front Cover"
    artworks_by_id["cover"] = cover_art

    for sp in book_layout["spreads"]:
        rp_art = sp.get("right_page", {}).get("artwork")
        if rp_art:
            rp_art_copy = dict(rp_art)
            aid = rp_art_copy["id"]
            if aid == "opening_prayers":
                rp_art_copy["section_label"] = "Opening Prayers"
            elif aid == "closing_prayers":
                rp_art_copy["section_label"] = "Closing Prayers"
            artworks_by_id[aid] = rp_art_copy

    return book_layout, prayers, mysteries_raw, mysteries_by_id, artworks_by_id


def render_page_1_front_cover(c: canvas.Canvas, book_layout: dict, project_root: Path) -> None:
    """Page 1: Front Cover in deep Baroque crimson (#4A1215) and gold (#D4AF37) palette with Murillo painting."""
    c.saveState()
    c.setFillColor(BACK_PRIMARY)
    c.rect(-BLEED, -BLEED, PAGE_W + 2 * BLEED, PAGE_H + 2 * BLEED, stroke=0, fill=1)
    gx, gy, gw, gh = get_gold_box(1)
    c.setStrokeColor(BACK_GOLD)
    c.setLineWidth(1.5)
    c.rect(gx, gy, gw, gh, stroke=1, fill=0)
    c.restoreState()

    cx, cy, cw, ch = get_content_box(1, pad_x=16.0, pad_y=16.0)
    top_y = cy + ch

    fc = book_layout["front_cover"]
    title = fc.get("title", "Pray the Rosary").upper()
    subtitle = fc.get("subtitle", "")

    st_title = make_style("fc_title", "EBGaramond-Bold", 23.0, 27.0, BACK_GOLD, TA_CENTER)
    st_sub = make_style("fc_sub", "EBGaramond-Regular", 11.0, 14.0, BACK_IVORY, TA_CENTER)

    h1 = draw_para(c, title, st_title, cx, top_y, cw)
    top_y -= (h1 + 3.0)
    h2 = draw_para(c, subtitle, st_sub, cx + 12.0, top_y, cw - 24.0)
    top_y -= (h2 + 6.0)

    c.saveState()
    c.setStrokeColor(BACK_GOLD)
    c.setLineWidth(1.0)
    c.line(cx + cw * 0.12, top_y, cx + cw * 0.88, top_y)
    c.restoreState()
    top_y -= 10.0

    img_path = project_root / fc["artwork"]["master_file"]
    avail_h = top_y - cy
    draw_framed_image(c, img_path, cx, cy, cw, avail_h, border_color=BACK_GOLD)


def render_front_matter_page(c: canvas.Canvas, page_num: int, page_data: dict) -> None:
    """Pages 2-3: Front Matter introduction and theological structure."""
    draw_master_a_background_and_border(c, page_num)
    cx, cy, cw, ch = get_content_box(page_num, pad_x=16.0, pad_y=14.0)
    top_y = cy + ch

    heading = page_data.get("heading", "")
    subheading = page_data.get("subheading", "")
    sections = page_data.get("sections", [])
    text_w = cw - 12.0

    st_st = make_style("fm_st", "EBGaramond-Bold", 11.8, 14.2, COLOR_CRIMSON, TA_LEFT)
    st_bd = make_style("fm_bd", "EBGaramond-Regular", 10.0, 12.8, COLOR_CHARCOAL, TA_LEFT)

    for body_sz in [10.4, 10.0, 9.6, 9.2]:
        sec_title_sz = body_sz + 1.8
        lead = body_sz * 1.28
        h_head = measure_header_block(cw, subheading, heading, sub_size=10.5, head_size=16.5)
        st_st = make_style("fm_st", "EBGaramond-Bold", sec_title_sz, sec_title_sz * 1.2, COLOR_CRIMSON, TA_LEFT)
        st_bd = make_style("fm_bd", "EBGaramond-Regular", body_sz, lead, COLOR_CHARCOAL, TA_LEFT)
        total_sec_h = 0.0
        for sec in sections:
            total_sec_h += measure_para(sec["title"], st_st, text_w) + 3.0
            for para_line in sec["body"].split("\n"):
                total_sec_h += measure_para(para_line, st_bd, text_w) + 2.5
        if h_head + total_sec_h + (len(sections) - 1) * 8.0 <= ch:
            break

    used_head = draw_header_block(c, cx, top_y, cw, subheading, heading, sub_size=10.5, head_size=16.5)
    curr_y = top_y - used_head

    leftover = max(0.0, (ch - used_head) - total_sec_h)
    gap = min(18.0, max(6.0, leftover / max(1, len(sections))))

    for i, sec in enumerate(sections):
        h_t = draw_para(c, sec["title"], st_st, cx, curr_y, text_w)
        curr_y -= (h_t + 3.0)
        lines = sec["body"].split("\n")
        for j, para_line in enumerate(lines):
            h_b = draw_para(c, para_line, st_bd, cx, curr_y, text_w)
            curr_y -= (h_b + (2.5 if j < len(lines) - 1 else 0.0))
        if i < len(sections) - 1:
            curr_y -= gap


def render_prayer_sequence_page(c: canvas.Canvas, page_num: int, page_data: dict, prayers: dict) -> None:
    """Pages 4 & 46: Opening Prayers and Closing Prayers step sequence."""
    draw_master_a_background_and_border(c, page_num)
    cx, cy, cw, ch = get_content_box(page_num, pad_x=16.0, pad_y=14.0)
    top_y = cy + ch

    heading = page_data.get("heading", "")
    subheading = page_data.get("subheading", "")
    steps = page_data.get("prayer_steps", [])
    is_five_step = len(steps) >= 5
    text_w = cw - 12.0
    rubric_w = cw - 28.0

    candidates = [9.5, 9.2, 8.9, 8.6] if is_five_step else [10.8, 10.4, 10.0, 9.6]

    st_rub = make_style("ps_rub", "EBGaramond-Regular", 9.0, 11.0, COLOR_UMBER, TA_LEFT)
    st_tit = make_style("ps_tit", "EBGaramond-Bold", 10.5, 12.5, COLOR_CRIMSON, TA_LEFT)
    st_ldr = make_style("ps_ldr", "EBGaramond-Regular", 9.5, 12.0, COLOR_CHARCOAL, TA_LEFT)
    st_rsp = make_style("ps_rsp", "EBGaramond-Bold", 9.5, 12.0, COLOR_CHARCOAL, TA_LEFT)

    for body_sz in candidates:
        rubric_sz = body_sz - 1.0
        title_sz = body_sz + 0.8
        lead = body_sz * 1.24

        st_rub = make_style("ps_rub", "EBGaramond-Regular", rubric_sz, rubric_sz * 1.2, COLOR_UMBER, TA_LEFT)
        st_tit = make_style("ps_tit", "EBGaramond-Bold", title_sz, title_sz * 1.2, COLOR_CRIMSON, TA_LEFT)
        st_ldr = make_style("ps_ldr", "EBGaramond-Regular", body_sz, lead, COLOR_CHARCOAL, TA_LEFT)
        st_rsp = make_style("ps_rsp", "EBGaramond-Bold", body_sz, lead, COLOR_CHARCOAL, TA_LEFT)

        h_head = measure_header_block(cw, subheading, heading, sub_size=10.5, head_size=16.5)
        steps_h = 0.0
        for st in steps:
            bead = st.get("bead_label", "")
            rub = st.get("rubric", "")
            rub_line = f"[{bead}] {rub}" if bead else rub
            p_obj = prayers[st["prayer_id"]]
            p_title = p_obj.get("title", "")
            reps = st.get("repetitions", 1)
            if reps > 1 and p_title:
                p_title = f"{reps}× {p_title}"
            l_txt = p_obj.get("leader_text", "")
            r_txt = p_obj.get("response_text", "") or p_obj.get("text", "")

            if rub_line:
                steps_h += measure_para(rub_line, st_rub, rubric_w) + 1.5
            if p_title:
                steps_h += measure_para(p_title, st_tit, text_w) + 1.5
            if l_txt:
                steps_h += measure_para(l_txt, st_ldr, text_w) + 1.5
            if r_txt:
                steps_h += measure_para(r_txt, st_rsp, text_w) + 1.5

            append_pid = st.get("append_prayer_id", "")
            if append_pid and append_pid in prayers:
                app_p = prayers[append_pid]
                if app_p.get("leader_text"):
                    steps_h += measure_para(app_p["leader_text"], st_ldr, text_w) + 1.5
                if app_p.get("response_text"):
                    steps_h += measure_para(app_p["response_text"], st_rsp, text_w) + 1.5

        if h_head + steps_h + (len(steps) - 1) * 5.0 <= ch:
            break

    used_head = draw_header_block(c, cx, top_y, cw, subheading, heading, sub_size=10.5, head_size=16.5)
    curr_y = top_y - used_head
    leftover = max(0.0, (ch - used_head) - steps_h)
    gap = min(16.0, max(4.5, leftover / max(1, len(steps) - 1)))

    for i, st in enumerate(steps):
        bead = st.get("bead_label", "")
        rub = st.get("rubric", "")
        rub_line = f"[{bead}] {rub}" if bead else rub
        p_obj = prayers[st["prayer_id"]]
        p_title = p_obj.get("title", "")
        reps = st.get("repetitions", 1)
        if reps > 1 and p_title:
            p_title = f"{reps}× {p_title}"
        l_txt = p_obj.get("leader_text", "")
        r_txt = p_obj.get("response_text", "") or p_obj.get("text", "")

        if rub_line:
            h = draw_para(c, rub_line, st_rub, cx, curr_y, rubric_w)
            curr_y -= (h + 1.5)
        if p_title:
            h = draw_para(c, p_title, st_tit, cx, curr_y, text_w)
            curr_y -= (h + 1.5)
        if l_txt:
            h = draw_para(c, l_txt, st_ldr, cx, curr_y, text_w)
            curr_y -= (h + 1.5)
        if r_txt:
            h = draw_para(c, r_txt, st_rsp, cx, curr_y, text_w)
            curr_y -= (h + 1.5)

        append_pid = st.get("append_prayer_id", "")
        if append_pid and append_pid in prayers:
            app_p = prayers[append_pid]
            if app_p.get("leader_text"):
                h = draw_para(c, app_p["leader_text"], st_ldr, cx, curr_y, text_w)
                curr_y -= (h + 1.5)
            if app_p.get("response_text"):
                h = draw_para(c, app_p["response_text"], st_rsp, cx, curr_y, text_w)
                curr_y -= (h + 1.5)

        if i < len(steps) - 1:
            curr_y -= gap


def render_artwork_page(
    c: canvas.Canvas, page_num: int, subheading: str, heading: str, artwork: dict, project_root: Path
) -> None:
    """Right-hand artwork page (Pages 5, 7, 9, ..., 47) displaying master painting with top identifier header."""
    draw_master_a_background_and_border(c, page_num)
    cx, cy, cw, ch = get_content_box(page_num, pad_x=16.0, pad_y=14.0)
    top_y = cy + ch

    used_head = draw_header_block(c, cx, top_y, cw, subheading, heading, sub_size=10.5, head_size=16.5)
    avail_h = (top_y - used_head) - cy
    img_path = project_root / artwork["master_file"]
    draw_framed_image(c, img_path, cx, cy, cw, avail_h)


def render_mystery_prayer_page(
    c: canvas.Canvas, page_num: int, mys: dict, decade_seq: list, prayers: dict
) -> None:
    """Left-hand Mystery page (Pages 6, 8, ..., 44): Fruit pill, CPDV Scripture box, meditation, and decade prayers."""
    draw_master_a_background_and_border(c, page_num)
    cx, cy, cw, ch = get_content_box(page_num, pad_x=16.0, pad_y=14.0)
    top_y = cy + ch

    subheading = mys.get("ordinal_label", "")
    heading = mys.get("title", "")
    fruit_str = f"Fruit of the Mystery: {mys.get('fruit', '')}"
    cite_str = mys.get("scripture_reference", "")
    scrip_str = mys.get("scripture_text", "")
    med_str = mys.get("meditation", "")

    scrip_wrap_w = cw - 30.0
    cite_wrap_w = cw - 20.0
    body_wrap_w = cw - 10.0

    st_cite = make_style("m_ci", "EBGaramond-Bold", 8.8, 10.5, COLOR_UMBER, TA_LEFT)
    st_scrip = make_style("m_sc", "EBGaramond-Regular", 9.5, 11.8, COLOR_CHARCOAL, TA_LEFT)
    st_med = make_style("m_md", "EBGaramond-Regular", 9.5, 11.8, COLOR_CHARCOAL, TA_LEFT)
    st_rub = make_style("m_rb", "EBGaramond-Bold", 9.0, 11.0, COLOR_CRIMSON, TA_LEFT)
    st_ldr = make_style("m_ld", "EBGaramond-Regular", 9.5, 11.8, COLOR_CHARCOAL, TA_LEFT)
    st_rsp = make_style("m_rs", "EBGaramond-Bold", 9.5, 11.8, COLOR_CHARCOAL, TA_LEFT)
    fruit_sz = 9.0

    for body_sz in [10.0, 9.7, 9.4, 9.1, 8.8]:
        lead = body_sz * 1.22
        rub_sz = body_sz - 0.5
        cite_sz = body_sz - 0.7
        fruit_sz = 9.0

        st_cite = make_style("m_ci", "EBGaramond-Bold", cite_sz, cite_sz * 1.2, COLOR_UMBER, TA_LEFT)
        st_scrip = make_style("m_sc", "EBGaramond-Regular", body_sz, lead, COLOR_CHARCOAL, TA_LEFT)
        st_med = make_style("m_md", "EBGaramond-Regular", body_sz, lead, COLOR_CHARCOAL, TA_LEFT)
        st_rub = make_style("m_rb", "EBGaramond-Bold", rub_sz, rub_sz * 1.18, COLOR_CRIMSON, TA_LEFT)
        st_ldr = make_style("m_ld", "EBGaramond-Regular", body_sz, lead, COLOR_CHARCOAL, TA_LEFT)
        st_rsp = make_style("m_rs", "EBGaramond-Bold", body_sz, lead, COLOR_CHARCOAL, TA_LEFT)

        h_head = measure_header_block(cw, subheading, heading, sub_size=10.5, head_size=16.0)
        h_fruit = 20.0
        h_scrip = measure_para(cite_str, st_cite, cite_wrap_w) + 2.5 + measure_para(scrip_str, st_scrip, scrip_wrap_w) + 14.0
        h_med = measure_para(med_str, st_med, body_wrap_w)

        h_prayers = 0.0
        for item in decade_seq:
            pid = item["prayer_id"]
            reps = int(item.get("repetitions", 1))
            p_obj = prayers[pid]
            p_title = f"{reps}× {p_obj.get('title', '')}"
            l_txt = p_obj.get("leader_text", "")
            r_txt = p_obj.get("response_text", "") or p_obj.get("text", "")
            h_prayers += measure_para(p_title, st_rub, body_wrap_w) + 1.2
            if l_txt:
                h_prayers += measure_para(l_txt, st_ldr, body_wrap_w) + 1.2
            if r_txt:
                h_prayers += measure_para(r_txt, st_rsp, body_wrap_w) + 1.2

        total_needed = h_head + h_fruit + h_scrip + h_med + h_prayers + 30.0
        if total_needed <= ch:
            break

    used_head = draw_header_block(c, cx, top_y, cw, subheading, heading, sub_size=10.5, head_size=16.0)
    curr_y = top_y - used_head

    # Fruit Pill (Upright EBGaramond-Regular)
    f_box_h = 20.0
    raw_fruit_w = pdfmetrics.stringWidth(fruit_str, "EBGaramond-Regular", fruit_sz)
    pill_w = min(cw, max(180.0, raw_fruit_w + 32.0))
    pill_x = cx + (cw - pill_w) / 2.0
    text_start_x = pill_x + (pill_w - raw_fruit_w) / 2.0

    c.saveState()
    c.setFillColor(COLOR_PARCHMENT_BOX)
    c.setStrokeColor(COLOR_GOLD)
    c.setLineWidth(0.6)
    c.roundRect(pill_x, curr_y - f_box_h, pill_w, f_box_h, 3.0, stroke=1, fill=1)
    c.setFillColor(COLOR_CRIMSON)
    c.setFont("EBGaramond-Regular", fruit_sz)
    c.drawString(text_start_x, curr_y - f_box_h + 6.5, fruit_str)
    c.restoreState()
    curr_y -= (f_box_h + 5.5)

    # CPDV Scripture Box (Upright EBGaramond-Regular)
    s_cite_h = measure_para(cite_str, st_cite, cite_wrap_w)
    s_body_h = measure_para(scrip_str, st_scrip, scrip_wrap_w)
    s_box_h = s_cite_h + 2.5 + s_body_h + 14.0
    c.saveState()
    c.setFillColor(COLOR_PARCHMENT_BOX)
    c.setStrokeColor(COLOR_GOLD)
    c.setLineWidth(0.6)
    c.roundRect(cx, curr_y - s_box_h, cw, s_box_h, 3.0, stroke=1, fill=1)
    c.restoreState()
    sy = curr_y - 6.0
    h_c = draw_para(c, cite_str, st_cite, cx + 10.0, sy, cite_wrap_w)
    sy -= (h_c + 2.5)
    draw_para(c, scrip_str, st_scrip, cx + 10.0, sy, scrip_wrap_w)
    curr_y -= (s_box_h + 5.5)

    # Meditation
    h_m = draw_para(c, med_str, st_med, cx, curr_y, body_wrap_w)
    curr_y -= (h_m + 5.5)

    # Divider
    c.saveState()
    c.setStrokeColor(COLOR_GOLD)
    c.setLineWidth(0.5)
    c.line(cx, curr_y, cx + cw, curr_y)
    c.restoreState()
    curr_y -= 5.5

    # Decade Prayers
    avail_for_prayers = (curr_y - cy) - h_prayers
    p_gap = min(12.0, max(2.5, avail_for_prayers / max(1, len(decade_seq) - 1)))

    for idx, item in enumerate(decade_seq):
        pid = item["prayer_id"]
        reps = int(item.get("repetitions", 1))
        p_obj = prayers[pid]
        p_title = f"{reps}× {p_obj.get('title', '')}"
        l_txt = p_obj.get("leader_text", "")
        r_txt = p_obj.get("response_text", "") or p_obj.get("text", "")

        ht = draw_para(c, p_title, st_rub, cx, curr_y, body_wrap_w)
        curr_y -= (ht + 1.2)
        if l_txt:
            hl = draw_para(c, l_txt, st_ldr, cx, curr_y, body_wrap_w)
            curr_y -= (hl + 1.2)
        if r_txt:
            hr = draw_para(c, r_txt, st_rsp, cx, curr_y, body_wrap_w)
            curr_y -= (hr + 1.2)
        if idx < len(decade_seq) - 1:
            curr_y -= p_gap


def render_credits_page(
    c: canvas.Canvas,
    page_num: int,
    page_data: dict,
    artworks_by_id: dict,
    project_version: str,
) -> None:
    """
    Pages 48 & 49: Sacred Artwork Credits & Colophon.
    - Page 48: 12 attributions + gold divider + 'This edition of “Pray The Rosary” was created and is maintained by Kevin Audrain.' + 'Version <X.Y.Z>'.
    - Page 49: 11 attributions + gold divider + CPDV Scripture notice + Public Domain artwork notice.
    """
    draw_master_a_background_and_border(c, page_num)
    cx, cy, cw, ch = get_content_box(page_num, pad_x=14.0, pad_y=12.0)
    top_y = cy + ch

    heading = page_data.get("heading", "")
    subheading = page_data.get("subheading", "")
    aids = page_data.get("attribution_ids", [])
    colophon = page_data.get("colophon", {})
    text_w = cw - 12.0

    used_head = draw_header_block(c, cx, top_y, cw, subheading, heading, sub_size=9.5, head_size=14.5)
    curr_y = top_y - used_head

    st_title = make_style("cr_t", "EBGaramond-Bold", 8.5, 10.0, COLOR_CRIMSON, TA_LEFT)
    st_det = make_style("cr_d", "EBGaramond-Regular", 7.6, 9.0, COLOR_CHARCOAL, TA_LEFT)
    st_col_r = make_style("cr_cr", "EBGaramond-Regular", 7.4, 8.8, COLOR_CHARCOAL, TA_LEFT)
    st_col_u = make_style("cr_cu", "EBGaramond-Regular", 7.4, 8.8, COLOR_UMBER, TA_LEFT)

    rendered_items = []
    items_h = 0.0
    for aid in aids:
        art = artworks_by_id[aid]
        sec_lbl = art.get("section_label", "")
        art_title = art.get("title", "")
        disp_sec = sec_lbl
        if " Mystery (" in disp_sec:
            disp_sec = disp_sec.split(" (")[0]
        t_line = f"{disp_sec} — {art_title}" if disp_sec else art_title

        raw_artist = art.get("artist", "").strip()
        artist_dates = art.get("artist_dates", "").strip()
        if artist_dates:
            if raw_artist.endswith(")"):
                artist_str = f"{raw_artist[:-1]}, {artist_dates})"
            else:
                artist_str = f"{raw_artist} ({artist_dates})"
        else:
            artist_str = raw_artist

        d_line = (
            f"{artist_str}, "
            f"{art.get('creation_date', '')} • {art.get('medium', '')} • {art.get('current_location', '')}"
        )
        items_h += measure_para(t_line, st_title, text_w) + measure_para(d_line, st_det, text_w)
        rendered_items.append((t_line, d_line))

    # Calculate colophon notice height below gold divider
    col_h = 0.0
    colophon_lines: List[Tuple[str, ParagraphStyle]] = []
    if colophon:
        col_h += 8.0  # spacing and divider rule
        if page_num == 48:
            creator_text = colophon.get("creator_notice", "")
            if creator_text:
                colophon_lines.append((creator_text, st_col_u))
                col_h += measure_para(creator_text, st_col_u, text_w) + 2.0
            if colophon.get("show_version"):
                version_text = f"Version {project_version}"
                colophon_lines.append((version_text, st_col_u))
                col_h += measure_para(version_text, st_col_u, text_w) + 2.0
        else:
            sn_text = colophon.get("scripture_notice", "")
            if sn_text:
                colophon_lines.append((sn_text, st_col_u))
                col_h += measure_para(sn_text, st_col_u, text_w) + 3.0
            an_text = colophon.get("artwork_notice", "")
            if an_text:
                colophon_lines.append((an_text, st_col_u))
                col_h += measure_para(an_text, st_col_u, text_w) + 2.0

    avail_h = (curr_y - cy) - items_h - col_h
    gap = min(6.0, max(1.8, avail_h / max(1, len(rendered_items) - 1)))

    for i, (t_line, d_line) in enumerate(rendered_items):
        ht = draw_para(c, t_line, st_title, cx, curr_y, text_w)
        curr_y -= ht
        hd = draw_para(c, d_line, st_det, cx, curr_y, text_w)
        curr_y -= hd
        if i < len(rendered_items) - 1:
            curr_y -= gap

    if colophon_lines:
        curr_y -= 4.0
        c.saveState()
        c.setStrokeColor(COLOR_GOLD)
        c.setLineWidth(0.6)
        c.line(cx, curr_y, cx + cw, curr_y)
        c.restoreState()
        curr_y -= 4.0

        for line_txt, line_style in colophon_lines:
            hl = draw_para(c, line_txt, line_style, cx, curr_y, text_w)
            curr_y -= (hl + 2.5)


def render_page_50_back_cover(c: canvas.Canvas, book_layout: dict) -> None:
    """
    Page 50: Back Cover in deep Baroque crimson (#4A1215) and gold (#D4AF37) palette.
    Encapsulates both the epigraph and marian_counsel in subtle gold-bordered callout boxes
    (#2A090B background fill, #D4AF37 border, 3.5pt rounded corners) matching BackCoverPageCard.
    Zero italic fonts: uses EBGaramond-Regular and EBGaramond-Bold exclusively.
    """
    bc = book_layout["back_cover"]
    c.saveState()
    c.setFillColor(BACK_PRIMARY)
    c.rect(-BLEED, -BLEED, PAGE_W + 2 * BLEED, PAGE_H + 2 * BLEED, stroke=0, fill=1)
    gx, gy, gw, gh = get_gold_box(50)
    c.setStrokeColor(BACK_GOLD)
    c.setLineWidth(1.5)
    c.rect(gx, gy, gw, gh, stroke=1, fill=0)
    c.restoreState()

    cx, cy, cw, ch = get_content_box(50, pad_x=22.0, pad_y=24.0)
    top_y = cy + ch

    title = bc.get("title", "Pray the Rosary").upper()
    subtitle = bc.get("subtitle", "")

    st_title = make_style("bc_t", "EBGaramond-Bold", 22.0, 26.0, BACK_GOLD, TA_CENTER)
    st_sub = make_style("bc_s", "EBGaramond-Regular", 11.0, 14.0, BACK_IVORY, TA_CENTER)

    # Callout box text styles
    st_quote = make_style("bc_q", "EBGaramond-Regular", 10.5, 14.5, BACK_IVORY, TA_LEFT)
    st_attr = make_style("bc_a", "EBGaramond-Regular", 9.5, 13.0, BACK_GOLD, TA_RIGHT)
    st_syn = make_style("bc_syn", "EBGaramond-Regular", 10.5, 14.5, BACK_IVORY, TA_LEFT)

    # 1. Header block
    ht = draw_para(c, title, st_title, cx, top_y, cw)
    top_y -= (ht + 4.0)
    hs = draw_para(c, subtitle, st_sub, cx + 14.0, top_y, cw - 28.0)
    top_y -= (hs + 10.0)

    c.saveState()
    c.setStrokeColor(BACK_GOLD)
    c.setLineWidth(0.9)
    c.line(cx + cw * 0.15, top_y, cx + cw * 0.85, top_y)
    c.restoreState()
    top_y -= 18.0

    # Box specifications
    box_pad_x = 14.0
    box_pad_y = 10.0
    box_w = cw
    inner_text_w = box_w - 2 * box_pad_x

    # Measure Epigraph Callout Box
    epi = bc.get("epigraph", {})
    epi_q = f"“{epi.get('quote', '')}”"
    epi_a = f"— {epi.get('attribution', '')}"
    h_eq = measure_para(epi_q, st_quote, inner_text_w)
    h_ea = measure_para(epi_a, st_attr, inner_text_w)
    epi_box_h = box_pad_y + h_eq + 5.0 + h_ea + box_pad_y

    # Measure Synopsis
    syn_text = bc.get("synopsis", "")
    h_syn = measure_para(syn_text, st_syn, cw - 12.0)

    # Measure Marian Counsel Callout Box
    coun = bc.get("marian_counsel", {})
    coun_q = f"“{coun.get('quote', '')}”"
    coun_a = f"— {coun.get('attribution', '')}"
    h_cq = measure_para(coun_q, st_quote, inner_text_w)
    h_ca = measure_para(coun_a, st_attr, inner_text_w)
    coun_box_h = box_pad_y + h_cq + 5.0 + h_ca + box_pad_y

    # Calculate vertical distribution
    avail_vert = (top_y - cy) - (epi_box_h + h_syn + coun_box_h)
    box_gap = min(22.0, max(12.0, avail_vert / 3.0))

    # 2. Render Epigraph Callout Box
    c.saveState()
    c.setFillColor(BACK_SECONDARY_BOX)
    c.setStrokeColor(BACK_GOLD)
    c.setLineWidth(0.9)
    c.roundRect(cx, top_y - epi_box_h, box_w, epi_box_h, 3.5, stroke=1, fill=1)
    c.restoreState()

    box_curr_y = top_y - box_pad_y
    he_drawn = draw_para(c, epi_q, st_quote, cx + box_pad_x, box_curr_y, inner_text_w)
    box_curr_y -= (he_drawn + 5.0)
    draw_para(c, epi_a, st_attr, cx + box_pad_x, box_curr_y, inner_text_w)
    top_y -= (epi_box_h + box_gap)

    # 3. Render Synopsis
    hs_drawn = draw_para(c, syn_text, st_syn, cx + 6.0, top_y, cw - 12.0)
    top_y -= (hs_drawn + box_gap)

    # 4. Render Marian Counsel Callout Box
    c.saveState()
    c.setFillColor(BACK_SECONDARY_BOX)
    c.setStrokeColor(BACK_GOLD)
    c.setLineWidth(0.9)
    c.roundRect(cx, top_y - coun_box_h, box_w, coun_box_h, 3.5, stroke=1, fill=1)
    c.restoreState()

    box_curr_y = top_y - box_pad_y
    hc_drawn = draw_para(c, coun_q, st_quote, cx + box_pad_x, box_curr_y, inner_text_w)
    box_curr_y -= (hc_drawn + 5.0)
    draw_para(c, coun_a, st_attr, cx + box_pad_x, box_curr_y, inner_text_w)


def draw_crop_marks(c: canvas.Canvas, trim_x: float, trim_y: float, trim_w: float, trim_h: float) -> None:
    """
    Renders subtle corner crop marks at the 4 corners of the 6" x 9" trim boundary
    offset outwards so they do not penetrate the bleed area.
    """
    c.saveState()
    c.setStrokeColor(COLOR_CHARCOAL)
    c.setLineWidth(0.5)

    x0 = trim_x
    x1 = trim_x + trim_w
    y0 = trim_y
    y1 = trim_y + trim_h

    offset = 4.0   # offset from trim boundary
    length = 20.0  # length of crop mark line

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


def build_print_pdf(
    output_path: Path,
    bleed: bool = False,
    office_depot: bool = False,
    project_root: Optional[Path] = None,
) -> Path:
    """
    Builds the canonical 50-page print PDF.
    Modes:
      - Default: 6.0" x 9.0" (432 x 648 pt)
      - Bleed: 6.25" x 9.25" (450 x 666 pt) with PyMuPDF TrimBox (9, 9, 441, 657) and BleedBox (0, 0, 450, 666)
      - Office Depot: 8.5" x 11.0" (612 x 792 pt) US Letter with centered 6" x 9" page, 0.125" bleed, and crop marks
    """
    if project_root is None:
        project_root = PROJECT_ROOT

    output_path.parent.mkdir(parents=True, exist_ok=True)
    version = get_project_version(project_root)
    book_layout, prayers, mysteries_raw, mysteries_by_id, artworks_by_id = load_all_data(project_root)
    decade_seq = mysteries_raw["decade_prayer_sequence"]

    if office_depot:
        pagesize = (LETTER_W, LETTER_H)
        trans_x = (LETTER_W - PAGE_W) / 2.0  # 90.0 pt
        trans_y = (LETTER_H - PAGE_H) / 2.0  # 72.0 pt
    elif bleed:
        pagesize = (PAGE_W + 2 * BLEED, PAGE_H + 2 * BLEED)  # 450 x 666 pt
        trans_x = BLEED  # 9.0 pt
        trans_y = BLEED  # 9.0 pt
    else:
        pagesize = (PAGE_W, PAGE_H)  # 432 x 648 pt
        trans_x = 0.0
        trans_y = 0.0

    c = canvas.Canvas(str(output_path), pagesize=pagesize)
    c.setTitle("Pray the Rosary - A Contemplative Visual Guide to the Twenty Mysteries")
    c.setAuthor("Pray the Rosary")

    def start_page():
        if office_depot:
            draw_crop_marks(c, trans_x, trans_y, PAGE_W, PAGE_H)
        if trans_x != 0.0 or trans_y != 0.0:
            c.saveState()
            c.translate(trans_x, trans_y)

    def finish_page():
        if trans_x != 0.0 or trans_y != 0.0:
            c.restoreState()
        c.showPage()

    # --- Page 1: Front Cover ---
    start_page()
    render_page_1_front_cover(c, book_layout, project_root)
    finish_page()

    # --- Spreads 1..24 -> Pages 2..49 ---
    for sp in book_layout["spreads"]:
        sp_type = sp["type"]
        if sp_type == "front_matter_spread":
            lp = sp["left_page"]
            rp = sp["right_page"]
            start_page()
            render_front_matter_page(c, lp["page_number"], lp)
            finish_page()
            start_page()
            render_front_matter_page(c, rp["page_number"], rp)
            finish_page()
        elif sp_type == "prayer_art_spread":
            lp = sp["left_page"]
            rp = sp["right_page"]
            start_page()
            render_prayer_sequence_page(c, lp["page_number"], lp, prayers)
            finish_page()
            start_page()
            render_artwork_page(
                c, rp["page_number"], rp.get("subheading", ""), rp.get("heading", ""), rp["artwork"], project_root
            )
            finish_page()
        elif sp_type == "mystery_spread":
            mid = sp["id"]
            mys = mysteries_by_id[mid]
            lp_num = int(sp["left_page_number"])
            rp_num = int(sp["right_page_number"])
            start_page()
            render_mystery_prayer_page(c, lp_num, mys, decade_seq, prayers)
            finish_page()
            start_page()
            render_artwork_page(
                c, rp_num, mys.get("ordinal_label", ""), mys.get("title", ""), mys["artwork"], project_root
            )
            finish_page()
        elif sp_type == "credits_spread":
            lp = sp["left_page"]
            rp = sp["right_page"]
            start_page()
            render_credits_page(c, lp["page_number"], lp, artworks_by_id, version)
            finish_page()
            start_page()
            render_credits_page(c, rp["page_number"], rp, artworks_by_id, version)
            finish_page()

    # --- Page 50: Back Cover ---
    start_page()
    render_page_50_back_cover(c, book_layout)
    finish_page()

    c.save()

    # Post-process with PyMuPDF to configure TrimBox, BleedBox, and optimize streams
    doc = pymupdf.open(str(output_path))
    if bleed:
        trim_rect = pymupdf.Rect(9, 9, 441, 657)
        bleed_rect = pymupdf.Rect(0, 0, 450, 666)
        for page in doc:
            page.set_trimbox(trim_rect)
            page.set_bleedbox(bleed_rect)
    elif office_depot:
        trim_rect = pymupdf.Rect(90, 72, 522, 720)
        bleed_rect = pymupdf.Rect(81, 63, 531, 729)
        for page in doc:
            page.set_trimbox(trim_rect)
            page.set_bleedbox(bleed_rect)

    # Save optimized and deflated PDF
    temp_path = output_path.with_suffix(".tmp.pdf")
    doc.save(str(temp_path), garbage=3, deflate=True)
    doc.close()
    temp_path.replace(output_path)

    size_mb = output_path.stat().st_size / (1024 * 1024)
    print(f"Generated ({'Office Depot' if office_depot else ('Bleed' if bleed else 'Standard 6x9')}): {output_path} ({size_mb:.2f} MB)")
    return output_path


def main() -> None:
    parser = argparse.ArgumentParser(description="Pray The Rosary Print PDF Generator")
    parser.add_argument("--output", "-o", type=str, default=None, help="Custom output PDF path")
    parser.add_argument("--bleed", action="store_true", help="Generate 6.25\" x 9.25\" pages with 0.125\" bleed and TrimBox")
    parser.add_argument(
        "--office-depot",
        "--letter",
        action="store_true",
        dest="office_depot",
        help="Center 6\" x 9\" pages onto 8.5\" x 11.0\" US Letter with crop marks",
    )
    args = parser.parse_args()

    if args.output:
        out_path = Path(args.output).resolve()
    elif args.office_depot:
        out_path = DEFAULT_OFFICE_DEPOT_PDF
    else:
        out_path = DEFAULT_OUTPUT_PDF

    build_print_pdf(out_path, bleed=args.bleed, office_depot=args.office_depot)


if __name__ == "__main__":
    main()
