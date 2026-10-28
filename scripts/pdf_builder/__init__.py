"""
Modular 50-Page Print PDF Builder Package for Pray The Rosary (`scripts/pdf_builder/`).

Package Architecture Overview:
------------------------------
This package separates the print book generation pipeline into five focused modules
orchestrated by `scripts/build_print_pdf.py`:

  1. `config.py`:
     - Physical page dimensions (`PAGE_W`, `PAGE_H`, `TAB_EXT`, `VERVANTE_TAB_EXT`, `BLEED`, `LETTER_W`, `LETTER_H`).
     - Illuminated parchment (`COLOR_*`) and Baroque crimson cover/tab (`BACK_*`) palettes.
     - 6-tab (1/6-cut) stepped index tab specification (`TAB_SPECS`) and `is_vervante_wide_page(page_num)`.
     - Upright EB Garamond TrueType font registration (`register_fonts()`).
     - Immutable `PrintConfig` dataclass and factory constructors (`standard()`, `bleed_only()`,
       `tabs_only()`, `tabs_and_bleed()`, `vervante_mode()`, `office_depot_mode()`).

  2. `data_loader.py`:
     - `get_project_version(root_dir)`: Extracts `config/version` from `game/project.godot`.
     - `load_all_data(project_root)`: Loads and cross-indexes `book_layout.json`, `prayers.json`,
       and `mysteries.json`.

  3. `primitives.py`:
     - Coordinate geometry helpers (`get_gold_box`, `get_content_box`).
     - ReportLab paragraph styling, measurement, and drawing (`make_style`, `draw_para`, `measure_para`).
     - Liturgical header blocks (`draw_header_block`, `measure_header_block`).
     - 300-DPI master artwork Lanczos resampling and caching (`draw_framed_image`, `clear_image_cache`).
     - Master A parchment background & 1.5pt gold border (`draw_master_a_background_and_border`).
     - Fore-edge cover overhang strips & 1/6-cut stepped index tabs (`draw_tab_or_overhang`).
     - Corner crop marks (`draw_crop_marks`).

  4. `page_renderers.py`:
     - Dedicated page-type renderers for Page 1 (Front Cover), Pages 2–3 (Front Matter),
       Pages 4 & 46 (Opening/Closing Prayer Sequences), Right-hand Artwork Pages,
       Left-hand Mystery Meditation Pages, Pages 48–49 (Sacred Artwork Credits & Colophons),
       and Page 50 (Back Cover).

  5. `postprocess.py`:
     - `postprocess_pdf(output_path, cfg, trans_x, trans_y)`: Configures PyMuPDF `TrimBox`
       and `BleedBox` metadata per print profile, performs PDF stream garbage collection
       and Flate compression, and invokes `split_vervante_pdfs()` in Vervante mode.
     - `split_vervante_pdfs(master_pdf_path)`: Losslessly splits a 50-page Vervante master PDF
       into `<stem>_Covers.pdf` (4 pages), `<stem>_Interior.pdf` (34 pages), and
       `<stem>_Tabs.pdf` (12 pages).
"""

from typing import Any

from .config import (
    ARTWORK_DIR,
    BACK_GOLD,
    BACK_IVORY,
    BACK_PRIMARY,
    BACK_SECONDARY_BOX,
    BLEED,
    COLOR_CHARCOAL,
    COLOR_CRIMSON,
    COLOR_GOLD,
    COLOR_PARCHMENT,
    COLOR_PARCHMENT_BOX,
    COLOR_UMBER,
    DATA_DIR,
    DEFAULT_OFFICE_DEPOT_PDF,
    DEFAULT_OUTPUT_PDF,
    DEFAULT_TABS_BLEED_PDF,
    DEFAULT_TABS_PDF,
    DEFAULT_VERVANTE_COVERS_PDF,
    DEFAULT_VERVANTE_INTERIOR_PDF,
    DEFAULT_VERVANTE_PDF,
    DEFAULT_VERVANTE_TABS_PDF,
    FONTS_DIR,
    LETTER_H,
    LETTER_W,
    PAGE_H,
    PAGE_W,
    PROJECT_ROOT,
    SCRIPT_DIR,
    TAB_EXT,
    TAB_PAGE_W,
    TAB_SPECS,
    VERVANTE_COVER_PAGES,
    VERVANTE_CROP_MARGIN,
    VERVANTE_INTERIOR_PAGES,
    VERVANTE_TAB_EXT,
    VERVANTE_TAB_PAGES,
    PrintConfig,
    is_vervante_wide_page,
    register_fonts,
)
from .data_loader import get_project_version, load_all_data
from .page_renderers import (
    render_artwork_page,
    render_credits_page,
    render_front_matter_page,
    render_mystery_prayer_page,
    render_page_1_front_cover,
    render_page_50_back_cover,
    render_prayer_sequence_page,
)
from .postprocess import postprocess_pdf, split_vervante_pdfs
from .primitives import (
    clear_image_cache,
    draw_crop_marks,
    draw_framed_image,
    draw_header_block,
    draw_master_a_background_and_border,
    draw_para,
    draw_tab_or_overhang,
    get_content_box,
    get_gold_box,
    make_style,
    measure_header_block,
    measure_para,
)

__all__ = [
    "ARTWORK_DIR",
    "BACK_GOLD",
    "BACK_IVORY",
    "BACK_PRIMARY",
    "BACK_SECONDARY_BOX",
    "BLEED",
    "COLOR_CHARCOAL",
    "COLOR_CRIMSON",
    "COLOR_GOLD",
    "COLOR_PARCHMENT",
    "COLOR_PARCHMENT_BOX",
    "COLOR_UMBER",
    "DATA_DIR",
    "DEFAULT_OFFICE_DEPOT_PDF",
    "DEFAULT_OUTPUT_PDF",
    "DEFAULT_TABS_BLEED_PDF",
    "DEFAULT_TABS_PDF",
    "DEFAULT_VERVANTE_COVERS_PDF",
    "DEFAULT_VERVANTE_INTERIOR_PDF",
    "DEFAULT_VERVANTE_PDF",
    "DEFAULT_VERVANTE_TABS_PDF",
    "FONTS_DIR",
    "LETTER_H",
    "LETTER_W",
    "PAGE_H",
    "PAGE_W",
    "PROJECT_ROOT",
    "PrintConfig",
    "SCRIPT_DIR",
    "TAB_EXT",
    "TAB_PAGE_W",
    "TAB_SPECS",
    "VERVANTE_COVER_PAGES",
    "VERVANTE_CROP_MARGIN",
    "VERVANTE_INTERIOR_PAGES",
    "VERVANTE_TAB_EXT",
    "VERVANTE_TAB_PAGES",
    "build_all_print_pdfs",
    "build_print_pdf",
    "clear_image_cache",
    "draw_crop_marks",
    "draw_framed_image",
    "draw_header_block",
    "draw_master_a_background_and_border",
    "draw_para",
    "draw_tab_or_overhang",
    "get_content_box",
    "get_gold_box",
    "get_project_version",
    "is_vervante_wide_page",
    "load_all_data",
    "make_style",
    "measure_header_block",
    "measure_para",
    "postprocess_pdf",
    "register_fonts",
    "render_artwork_page",
    "render_credits_page",
    "render_front_matter_page",
    "render_mystery_prayer_page",
    "render_page_1_front_cover",
    "render_page_50_back_cover",
    "render_prayer_sequence_page",
    "split_vervante_pdfs",
]


def __getattr__(name: str) -> Any:
    """Lazily resolves `build_print_pdf` and `build_all_print_pdfs` to avoid circular imports."""
    if name in ("build_print_pdf", "build_all_print_pdfs"):
        from scripts.build_print_pdf import build_all_print_pdfs, build_print_pdf

        globals()["build_print_pdf"] = build_print_pdf
        globals()["build_all_print_pdfs"] = build_all_print_pdfs
        return globals()[name]
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")
