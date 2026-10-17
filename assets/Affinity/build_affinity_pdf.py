"""
Generates the 50-page 6" x 9" starter PDF for Affinity Layout from the canonical
JSON data files (game/data/*.json), EB Garamond Book fonts (assets/Affinity/fonts/),
and archival public-domain master paintings (assets/2D/gimp/original_downloads/).
"""
import json
from pathlib import Path
from PIL import Image as PILImage
from reportlab.pdfgen import canvas
from reportlab.lib.units import inch
from reportlab.lib.colors import HexColor
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Paragraph
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_LEFT, TA_CENTER

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent
FONTS_DIR = SCRIPT_DIR / "fonts"
DATA_DIR = PROJECT_ROOT / "game" / "data"

# Register EBGaramondBook family using exact PostScript names
pdfmetrics.registerFont(TTFont("EBGaramond-Regular", str(FONTS_DIR / "EBGaramondBook-Regular.ttf")))
pdfmetrics.registerFont(TTFont("EBGaramond-Bold", str(FONTS_DIR / "EBGaramondBook-Bold.ttf")))
pdfmetrics.registerFont(TTFont("EBGaramond-Italic", str(FONTS_DIR / "EBGaramondBook-Italic.ttf")))
pdfmetrics.registerFont(TTFont("EBGaramond-BoldItalic", str(FONTS_DIR / "EBGaramondBook-BoldItalic.ttf")))
pdfmetrics.registerFontFamily(
    "EBGaramond-Regular",
    normal="EBGaramond-Regular",
    bold="EBGaramond-Bold",
    italic="EBGaramond-Italic",
    boldItalic="EBGaramond-BoldItalic",
)

# Palette
COLOR_PARCHMENT = HexColor("#F5EFE0")
COLOR_PARCHMENT_BOX = HexColor("#EDE3CE")
COLOR_GOLD = HexColor("#B8963E")
COLOR_CRIMSON = HexColor("#6B1D2F")
COLOR_CHARCOAL = HexColor("#2B1E16")
COLOR_UMBER = HexColor("#6E5A4F")

BACK_PRIMARY = HexColor("#4A1215")
BACK_GOLD = HexColor("#D4AF37")
BACK_IVORY = HexColor("#F7F2E7")

PAGE_W = 6.0 * inch   # 432 pt
PAGE_H = 9.0 * inch   # 648 pt
BLEED = 0.125 * inch  # 9 pt


def get_gold_box(page_num: int):
    """
    Returns (x, y, w, h) in ReportLab points (origin bottom-left) for the Master A gold border
    matching the 0.625" Inner spine margin and 0.5" Outer/Top/Bottom margins.
    Odd pages (1, 3, 5...): Right-hand pages (Recto) -> Inner is Left (0.625"), Outer is Right (0.5").
    Even pages (2, 4, 6...): Left-hand pages (Verso) -> Outer is Left (0.5"), Inner is Right (0.625").
    """
    if page_num % 2 == 1:
        x = 0.625 * inch
    else:
        x = 0.500 * inch
    y = 0.500 * inch
    w = 4.875 * inch
    h = 8.000 * inch
    return x, y, w, h


def get_content_box(page_num: int, pad_x: float = 16.0, pad_y: float = 14.0):
    gx, gy, gw, gh = get_gold_box(page_num)
    return gx + pad_x, gy + pad_y, gw - 2 * pad_x, gh - 2 * pad_y


def make_style(
    name: str,
    font_name: str = "EBGaramond-Regular",
    font_size: float = 10.5,
    leading: float = 13.0,
    text_color=COLOR_CHARCOAL,
    alignment=TA_LEFT,
) -> ParagraphStyle:
    return ParagraphStyle(
        name=name,
        fontName=font_name,
        fontSize=font_size,
        leading=leading,
        textColor=text_color,
        alignment=alignment,
    )


def draw_para(c: canvas.Canvas, text: str, style: ParagraphStyle, x: float, top_y: float, width: float) -> float:
    p = Paragraph(text, style)
    _, h = p.wrap(width, 2000)
    p.drawOn(c, x, top_y - h)
    return h


def measure_para(text: str, style: ParagraphStyle, width: float) -> float:
    p = Paragraph(text, style)
    _, h = p.wrap(width, 2000)
    return h


def draw_master_a_background_and_border(c: canvas.Canvas, page_num: int):
    c.saveState()
    c.setFillColor(COLOR_PARCHMENT)
    c.rect(-BLEED, -BLEED, PAGE_W + 2 * BLEED, PAGE_H + 2 * BLEED, stroke=0, fill=1)
    gx, gy, gw, gh = get_gold_box(page_num)
    c.setStrokeColor(COLOR_GOLD)
    c.setLineWidth(1.5)
    c.rect(gx, gy, gw, gh, stroke=1, fill=0)
    c.restoreState()


def draw_header_block(c: canvas.Canvas, cx: float, top_y: float, cw: float, subheading: str, heading: str,
                      sub_size: float = 10.5, head_size: float = 17.5) -> float:
    used = 0.0
    if subheading:
        st_sub = make_style("h_sub", "EBGaramond-Italic", sub_size, sub_size * 1.25, COLOR_UMBER, TA_CENTER)
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


def measure_header_block(cw: float, subheading: str, heading: str, sub_size: float = 10.5, head_size: float = 17.5) -> float:
    used = 0.0
    if subheading:
        st_sub = make_style("h_sub", "EBGaramond-Italic", sub_size, sub_size * 1.25, COLOR_UMBER, TA_CENTER)
        used += measure_para(subheading, st_sub, cw - 20.0) + 2.0
    if heading:
        st_head = make_style("h_head", "EBGaramond-Bold", head_size, head_size * 1.18, COLOR_CRIMSON, TA_CENTER)
        used += measure_para(heading, st_head, cw - 12.0) + 5.0
    used += 7.0
    return used


def draw_framed_image(c: canvas.Canvas, img_path: Path, box_x: float, box_y: float, box_w: float, box_h: float):
    if not img_path.exists():
        raise FileNotFoundError(f"Missing image: {img_path}")
    with PILImage.open(img_path) as im:
        iw, ih = im.size
    scale = min(box_w / float(iw), box_h / float(ih))
    draw_w = iw * scale
    draw_h = ih * scale
    dx = box_x + (box_w - draw_w) / 2.0
    dy = box_y + (box_h - draw_h) / 2.0
    c.drawImage(str(img_path), dx, dy, width=draw_w, height=draw_h, preserveAspectRatio=True, mask='auto')
    c.saveState()
    c.setStrokeColor(COLOR_GOLD)
    c.setLineWidth(1.0)
    c.rect(dx, dy, draw_w, draw_h, stroke=1, fill=0)
    c.restoreState()


def load_all_data():
    with open(DATA_DIR / "book_layout.json", "r", encoding="utf-8") as f:
        book_layout = json.load(f)
    with open(DATA_DIR / "prayers.json", "r", encoding="utf-8") as f:
        prayers = json.load(f)["prayers"]
    with open(DATA_DIR / "mysteries.json", "r", encoding="utf-8") as f:
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


def render_page_1_front_cover(c: canvas.Canvas, book_layout: dict, include_master: bool):
    if include_master:
        draw_master_a_background_and_border(c, 1)
    cx, cy, cw, ch = get_content_box(1, pad_x=16.0, pad_y=16.0)
    top_y = cy + ch

    fc = book_layout["front_cover"]
    title = fc.get("title", "Pray the Rosary").upper()
    subtitle = fc.get("subtitle", "")

    st_title = make_style("fc_title", "EBGaramond-Bold", 23.0, 27.0, COLOR_CRIMSON, TA_CENTER)
    st_sub = make_style("fc_sub", "EBGaramond-Italic", 11.0, 14.0, COLOR_UMBER, TA_CENTER)

    h1 = draw_para(c, title, st_title, cx, top_y, cw)
    top_y -= (h1 + 3.0)
    h2 = draw_para(c, subtitle, st_sub, cx + 12.0, top_y, cw - 24.0)
    top_y -= (h2 + 6.0)

    c.saveState()
    c.setStrokeColor(COLOR_GOLD)
    c.setLineWidth(1.0)
    c.line(cx + cw * 0.12, top_y, cx + cw * 0.88, top_y)
    c.restoreState()
    top_y -= 10.0

    img_path = PROJECT_ROOT / fc["artwork"]["master_file"]
    avail_h = top_y - cy
    draw_framed_image(c, img_path, cx, cy, cw, avail_h)


def render_front_matter_page(c: canvas.Canvas, page_num: int, page_data: dict, include_master: bool):
    if include_master:
        draw_master_a_background_and_border(c, page_num)
    cx, cy, cw, ch = get_content_box(page_num, pad_x=16.0, pad_y=14.0)
    top_y = cy + ch

    heading = page_data.get("heading", "")
    subheading = page_data.get("subheading", "")
    sections = page_data.get("sections", [])
    text_w = cw - 12.0

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


def render_prayer_sequence_page(c: canvas.Canvas, page_num: int, page_data: dict, prayers: dict, include_master: bool):
    if include_master:
        draw_master_a_background_and_border(c, page_num)
    cx, cy, cw, ch = get_content_box(page_num, pad_x=16.0, pad_y=14.0)
    top_y = cy + ch

    heading = page_data.get("heading", "")
    subheading = page_data.get("subheading", "")
    steps = page_data.get("prayer_steps", [])
    is_five_step = len(steps) >= 5
    text_w = cw - 12.0
    italic_w = cw - 28.0

    candidates = [9.5, 9.2, 8.9, 8.6] if is_five_step else [10.8, 10.4, 10.0, 9.6]

    for body_sz in candidates:
        rubric_sz = body_sz - 1.0
        title_sz = body_sz + 0.8
        lead = body_sz * 1.24

        st_rub = make_style("ps_rub", "EBGaramond-Italic", rubric_sz, rubric_sz * 1.2, COLOR_UMBER, TA_LEFT)
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
            l_txt = p_obj.get("leader_text", "")
            r_txt = p_obj.get("response_text", "") or p_obj.get("text", "")

            if rub_line:
                steps_h += measure_para(rub_line, st_rub, italic_w) + 1.5
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
        l_txt = p_obj.get("leader_text", "")
        r_txt = p_obj.get("response_text", "") or p_obj.get("text", "")

        if rub_line:
            h = draw_para(c, rub_line, st_rub, cx, curr_y, italic_w)
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


def render_artwork_page(c: canvas.Canvas, page_num: int, subheading: str, heading: str, artwork: dict, include_master: bool):
    if include_master:
        draw_master_a_background_and_border(c, page_num)
    cx, cy, cw, ch = get_content_box(page_num, pad_x=16.0, pad_y=14.0)
    top_y = cy + ch

    used_head = draw_header_block(c, cx, top_y, cw, subheading, heading, sub_size=10.5, head_size=16.5)
    avail_h = (top_y - used_head) - cy
    img_path = PROJECT_ROOT / artwork["master_file"]
    draw_framed_image(c, img_path, cx, cy, cw, avail_h)


def render_mystery_prayer_page(c: canvas.Canvas, page_num: int, mys: dict, decade_seq: list, prayers: dict, include_master: bool):
    if include_master:
        draw_master_a_background_and_border(c, page_num)
    cx, cy, cw, ch = get_content_box(page_num, pad_x=16.0, pad_y=14.0)
    top_y = cy + ch

    subheading = mys.get("ordinal_label", "")
    heading = mys.get("title", "")
    fruit_str = f"Fruit of the Mystery: {mys.get('fruit', '')}"
    cite_str = mys.get("scripture_reference", "")
    scrip_str = f"“{mys.get('scripture_text', '')}”"
    med_str = mys.get("meditation", "")

    scrip_wrap_w = cw - 30.0
    cite_wrap_w = cw - 20.0
    body_wrap_w = cw - 10.0

    for body_sz in [10.0, 9.7, 9.4, 9.1, 8.8]:
        lead = body_sz * 1.22
        rub_sz = body_sz - 0.5
        cite_sz = body_sz - 0.7
        fruit_sz = 9.0

        st_cite = make_style("m_ci", "EBGaramond-Bold", cite_sz, cite_sz * 1.2, COLOR_UMBER, TA_LEFT)
        st_scrip = make_style("m_sc", "EBGaramond-Italic", body_sz, lead, COLOR_CHARCOAL, TA_LEFT)
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

    f_box_h = 20.0
    raw_fruit_w = pdfmetrics.stringWidth(fruit_str, "EBGaramond-Italic", fruit_sz)
    pill_w = min(cw, max(180.0, raw_fruit_w + 32.0))
    pill_x = cx + (cw - pill_w) / 2.0
    text_start_x = pill_x + (pill_w - raw_fruit_w) / 2.0

    c.saveState()
    c.setFillColor(COLOR_PARCHMENT_BOX)
    c.setStrokeColor(COLOR_GOLD)
    c.setLineWidth(0.6)
    c.roundRect(pill_x, curr_y - f_box_h, pill_w, f_box_h, 3.0, stroke=1, fill=1)
    c.setFillColor(COLOR_CHARCOAL)
    c.setFont("EBGaramond-Italic", fruit_sz)
    c.drawString(text_start_x, curr_y - f_box_h + 6.5, fruit_str)
    c.restoreState()
    curr_y -= (f_box_h + 5.5)

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

    h_m = draw_para(c, med_str, st_med, cx, curr_y, body_wrap_w)
    curr_y -= (h_m + 5.5)

    c.saveState()
    c.setStrokeColor(COLOR_GOLD)
    c.setLineWidth(0.5)
    c.line(cx, curr_y, cx + cw, curr_y)
    c.restoreState()
    curr_y -= 5.5

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


def render_credits_page(c: canvas.Canvas, page_num: int, page_data: dict, artworks_by_id: dict, include_master: bool):
    if include_master:
        draw_master_a_background_and_border(c, page_num)
    cx, cy, cw, ch = get_content_box(page_num, pad_x=14.0, pad_y=12.0)
    top_y = cy + ch

    heading = page_data.get("heading", "")
    subheading = page_data.get("subheading", "")
    aids = page_data.get("attribution_ids", [])
    colophon = page_data.get("colophon", {})
    text_w = cw - 12.0
    italic_w = cw - 28.0

    used_head = draw_header_block(c, cx, top_y, cw, subheading, heading, sub_size=9.5, head_size=14.5)
    curr_y = top_y - used_head

    st_title = make_style("cr_t", "EBGaramond-Bold", 8.5, 10.0, COLOR_CRIMSON, TA_LEFT)
    st_det = make_style("cr_d", "EBGaramond-Regular", 7.8, 9.2, COLOR_CHARCOAL, TA_LEFT)
    st_col_i = make_style("cr_ci", "EBGaramond-Italic", 7.5, 9.0, COLOR_UMBER, TA_LEFT)
    st_col_r = make_style("cr_cr", "EBGaramond-Regular", 7.3, 8.8, COLOR_CHARCOAL, TA_LEFT)

    items_h = 0.0
    rendered_items = []
    for aid in aids:
        art = artworks_by_id[aid]
        sec_lbl = art.get("section_label", "")
        art_title = art.get("title", "")
        t_line = f"{sec_lbl} — {art_title}" if sec_lbl else art_title
        d_line = f"{art.get('artist', '')} ({art.get('artist_dates', '')}), {art.get('creation_date', '')} • {art.get('medium', '')} • {art.get('current_location', '')}"
        items_h += measure_para(t_line, st_title, text_w) + measure_para(d_line, st_det, text_w)
        rendered_items.append((t_line, d_line))

    col_h = 0.0
    if colophon:
        col_h += 8.0
        if colophon.get("scripture_notice"):
            col_h += measure_para(colophon["scripture_notice"], st_col_i, italic_w) + 3.0
        if colophon.get("artwork_notice"):
            col_h += measure_para(colophon["artwork_notice"], st_col_r, text_w)

    avail_h = (curr_y - cy) - items_h - col_h
    gap = min(6.0, max(1.8, avail_h / max(1, len(rendered_items) - 1)))

    for i, (t_line, d_line) in enumerate(rendered_items):
        ht = draw_para(c, t_line, st_title, cx, curr_y, text_w)
        curr_y -= ht
        hd = draw_para(c, d_line, st_det, cx, curr_y, text_w)
        curr_y -= hd
        if i < len(rendered_items) - 1:
            curr_y -= gap

    if colophon:
        curr_y -= 4.0
        c.saveState()
        c.setStrokeColor(COLOR_GOLD)
        c.setLineWidth(0.6)
        c.line(cx, curr_y, cx + cw, curr_y)
        c.restoreState()
        curr_y -= 4.0
        if colophon.get("scripture_notice"):
            hs = draw_para(c, colophon["scripture_notice"], st_col_i, cx, curr_y, italic_w)
            curr_y -= (hs + 2.5)
        if colophon.get("artwork_notice"):
            draw_para(c, colophon["artwork_notice"], st_col_r, cx, curr_y, text_w)


def render_page_50_back_cover(c: canvas.Canvas, book_layout: dict):
    bc = book_layout["back_cover"]
    c.saveState()
    c.setFillColor(BACK_PRIMARY)
    c.rect(-BLEED, -BLEED, PAGE_W + 2 * BLEED, PAGE_H + 2 * BLEED, stroke=0, fill=1)
    gx, gy, gw, gh = get_gold_box(50)
    c.setStrokeColor(BACK_GOLD)
    c.setLineWidth(1.5)
    c.rect(gx, gy, gw, gh, stroke=1, fill=0)
    c.restoreState()

    cx, cy, cw, ch = get_content_box(50, pad_x=22.0, pad_y=28.0)
    top_y = cy + ch

    title = bc.get("title", "Pray the Rosary").upper()
    subtitle = bc.get("subtitle", "")

    st_title = make_style("bc_t", "EBGaramond-Bold", 22.0, 26.0, BACK_GOLD, TA_CENTER)
    st_sub = make_style("bc_s", "EBGaramond-Italic", 11.0, 14.0, BACK_IVORY, TA_CENTER)
    st_quote = make_style("bc_q", "EBGaramond-Italic", 11.0, 15.0, BACK_IVORY, TA_CENTER)
    st_attr = make_style("bc_a", "EBGaramond-Bold", 9.5, 12.5, BACK_GOLD, TA_CENTER)
    st_syn = make_style("bc_syn", "EBGaramond-Regular", 10.8, 14.8, BACK_IVORY, TA_CENTER)

    ht = draw_para(c, title, st_title, cx, top_y, cw)
    top_y -= (ht + 4.0)
    hs = draw_para(c, subtitle, st_sub, cx + 14.0, top_y, cw - 28.0)
    top_y -= (hs + 12.0)

    c.saveState()
    c.setStrokeColor(BACK_GOLD)
    c.setLineWidth(0.9)
    c.line(cx + cw * 0.15, top_y, cx + cw * 0.85, top_y)
    c.restoreState()
    top_y -= 28.0

    epi = bc.get("epigraph", {})
    hq1 = draw_para(c, f"“{epi.get('quote', '')}”", st_quote, cx + 14.0, top_y, cw - 28.0)
    top_y -= (hq1 + 6.0)
    ha1 = draw_para(c, f"— {epi.get('attribution', '')}", st_attr, cx, top_y, cw)
    top_y -= (ha1 + 28.0)

    hsyn = draw_para(c, bc.get("synopsis", ""), st_syn, cx + 8.0, top_y, cw - 16.0)
    top_y -= (hsyn + 28.0)

    coun = bc.get("marian_counsel", {})
    hq2 = draw_para(c, f"“{coun.get('quote', '')}”", st_quote, cx + 14.0, top_y, cw - 28.0)
    top_y -= (hq2 + 6.0)
    draw_para(c, f"— {coun.get('attribution', '')}", st_attr, cx, top_y, cw)


def build_pdf(output_path: Path, include_master_background: bool = True):
    book_layout, prayers, mysteries_raw, mysteries_by_id, artworks_by_id = load_all_data()
    decade_seq = mysteries_raw["decade_prayer_sequence"]

    c = canvas.Canvas(str(output_path), pagesize=(PAGE_W, PAGE_H))
    c.setTitle("Pray the Rosary - A Contemplative Visual Guide to the Twenty Mysteries")
    c.setAuthor("Pray the Rosary")

    # Page 1: Front Cover
    render_page_1_front_cover(c, book_layout, include_master_background)
    c.showPage()

    # Spreads 1..24 -> Pages 2..49
    for sp in book_layout["spreads"]:
        sp_type = sp["type"]
        if sp_type == "front_matter_spread":
            lp = sp["left_page"]
            rp = sp["right_page"]
            render_front_matter_page(c, lp["page_number"], lp, include_master_background)
            c.showPage()
            render_front_matter_page(c, rp["page_number"], rp, include_master_background)
            c.showPage()
        elif sp_type == "prayer_art_spread":
            lp = sp["left_page"]
            rp = sp["right_page"]
            render_prayer_sequence_page(c, lp["page_number"], lp, prayers, include_master_background)
            c.showPage()
            render_artwork_page(c, rp["page_number"], rp.get("subheading", ""), rp.get("heading", ""), rp["artwork"], include_master_background)
            c.showPage()
        elif sp_type == "mystery_spread":
            mid = sp["id"]
            mys = mysteries_by_id[mid]
            lp_num = int(sp["left_page_number"])
            rp_num = int(sp["right_page_number"])
            render_mystery_prayer_page(c, lp_num, mys, decade_seq, prayers, include_master_background)
            c.showPage()
            render_artwork_page(c, rp_num, mys.get("ordinal_label", ""), mys.get("title", ""), mys["artwork"], include_master_background)
            c.showPage()
        elif sp_type == "credits_spread":
            lp = sp["left_page"]
            rp = sp["right_page"]
            render_credits_page(c, lp["page_number"], lp, artworks_by_id, include_master_background)
            c.showPage()
            render_credits_page(c, rp["page_number"], rp, artworks_by_id, include_master_background)
            c.showPage()

    # Page 50: Back Cover
    render_page_50_back_cover(c, book_layout)
    c.showPage()

    c.save()
    print(f"Saved: {output_path} ({output_path.stat().st_size / (1024*1024):.2f} MB)")


if __name__ == "__main__":
    build_pdf(SCRIPT_DIR / "PrayTheRosary_Affinity_Starter.pdf", include_master_background=True)
