"""
Automated 50-page 6" x 9" print PDF generator and CLI orchestrator for Pray The Rosary.

Delegates configuration, JSON data loading, ReportLab drawing primitives, page-type
rendering, and PyMuPDF TrimBox/BleedBox post-processing to the modular `scripts/pdf_builder/`
package while re-exporting all public symbols for 100% backwards compatibility.

Supported CLI Modes:
  - Default:        6.0" x 9.0" (432 x 648 pt) 50-page print PDF -> assets/print/PrayTheRosary.pdf
  - --bleed:        6.25" x 9.25" (450 x 666 pt) pages with 0.125" bleed, TrimBox & BleedBox
  - --tabs:         6.375" x 9.0" (459 x 648 pt) overhang covers & 6 stepped 1/6-cut index tabs -> assets/print/PrayTheRosary_Tabs.pdf
  - --tabs --bleed: 6.625" x 9.25" (477 x 666 pt) tabbed edition with 0.125" bleed -> assets/print/PrayTheRosary_Tabs_Bleed.pdf
  - -V / --Vervante: Vervante press-ready 50-page PDF (6.5" x 9.0" covers/tabs with full-length
                    crimson tab strips, 6.0" x 9.0" interior, 0.125" bleed & crop marks) ->
                    assets/print/Vervante/PrayTheRosary_Vervante.pdf plus 3 split component PDFs
                    (_Covers.pdf, _Interior.pdf, _Tabs.pdf) and README_Print_and_Assembly_Guide.pdf
  - --office-depot: Centers 6.0" x 9.0" pages with 0.125" bleed and crop marks on 8.5" x 11.0" US Letter
  - --all / -a:     Batch-builds all 8 tracked print PDF files across 4 editions in assets/print/
"""

import argparse
import sys
from pathlib import Path
from typing import List, Optional

# Ensure repository root is importable when invoked as `python scripts/build_print_pdf.py`
_REPO_ROOT = Path(__file__).resolve().parent.parent
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from reportlab.pdfgen import canvas  # noqa: E402

import scripts.pdf_builder as _pdf_builder_pkg  # noqa: E402
from scripts.pdf_builder.config import (  # noqa: E402
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
    DEFAULT_VERVANTE_GUIDE_PDF,
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
from scripts.pdf_builder.data_loader import get_project_version, load_all_data  # noqa: E402
from scripts.pdf_builder.page_renderers import (  # noqa: E402
    render_artwork_page,
    render_credits_page,
    render_front_matter_page,
    render_mystery_prayer_page,
    render_page_1_front_cover,
    render_page_50_back_cover,
    render_prayer_sequence_page,
)
from scripts.pdf_builder.postprocess import postprocess_pdf, split_vervante_pdfs  # noqa: E402
from scripts.pdf_builder.primitives import (  # noqa: E402
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
from scripts.pdf_builder.vervante_guide import build_vervante_assembly_guide  # noqa: E402


def build_print_pdf(
    output_path: Path,
    bleed: bool = False,
    office_depot: bool = False,
    tabs: bool = False,
    vervante: bool = False,
    project_root: Optional[Path] = None,
    config: Optional[PrintConfig] = None,
) -> Path:
    """
    Orchestrates the 50-page print PDF build for the requested configuration profile.

    Coordinate Translation Summary:
      - In standard 6" x 9" mode, `(trans_x, trans_y) = (0, 0)`.
      - In `--bleed` mode, the canvas expands by `2 * BLEED` (18 pt) and the trim origin
        is translated by `(BLEED, BLEED)` = `(9, 9)`.
      - In `--tabs` or `--Vervante` mode, even (Verso) wide pages shift their 6.0" body
        origin rightwards by `active_tab_ext` (`0.375"` or `0.50"`) so the left-hand
        protruding tab/overhang occupies `x in [-ext, 0]` while the 6.0" page body
        occupies `x in [0, PAGE_W]`.
    """
    cfg = config or PrintConfig(tabs=tabs, bleed=bleed, vervante=vervante, office_depot=office_depot)
    root = project_root if project_root is not None else PROJECT_ROOT
    data_root = root if (root / "game" / "data").exists() else PROJECT_ROOT

    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    version = get_project_version(data_root)
    book_layout, prayers, mysteries_raw, mysteries_by_id, artworks_by_id = load_all_data(data_root)
    decade_seq = mysteries_raw["decade_prayer_sequence"]

    eff_w = cfg.effective_width
    pagesize = (cfg.total_width, cfg.total_height)
    if cfg.vervante:
        trans_x, trans_y = VERVANTE_CROP_MARGIN, VERVANTE_CROP_MARGIN
    elif cfg.office_depot:
        trans_x, trans_y = (LETTER_W - eff_w) / 2.0, (LETTER_H - PAGE_H) / 2.0
    elif cfg.bleed:
        trans_x, trans_y = BLEED, BLEED
    else:
        trans_x, trans_y = 0.0, 0.0

    c = canvas.Canvas(str(output_path), pagesize=pagesize)
    c.setTitle("Pray the Rosary - A Contemplative Visual Guide to the Twenty Mysteries")
    c.setAuthor("Pray the Rosary")

    def start_page(page_num: int) -> None:
        if cfg.vervante:
            wide = cfg.is_vervante_wide_page(page_num)
            pw = cfg.effective_page_width(page_num)
            c.setPageSize(( cfg.total_canvas_width(page_num), cfg.total_canvas_height() ))
            draw_crop_marks(c, VERVANTE_CROP_MARGIN, VERVANTE_CROP_MARGIN, pw, PAGE_H, cfg)
            even_shift = VERVANTE_TAB_EXT if (wide and page_num % 2 == 0) else 0.0
            c.saveState()
            c.translate(VERVANTE_CROP_MARGIN + even_shift, VERVANTE_CROP_MARGIN)
            return

        if cfg.office_depot:
            draw_crop_marks(c, trans_x, trans_y, eff_w, PAGE_H, cfg)
        even_shift = TAB_EXT if (cfg.tabs and page_num % 2 == 0) else 0.0
        c.saveState()
        if (trans_x + even_shift) != 0.0 or trans_y != 0.0:
            c.translate(trans_x + even_shift, trans_y)

    def finish_page(page_num: int) -> None:
        if cfg.has_tabs:
            draw_tab_or_overhang(c, page_num, cfg)
        c.restoreState()
        c.showPage()

    # 1. Page 1: Front Cover
    start_page(1)
    render_page_1_front_cover(c, book_layout, data_root, cfg)
    finish_page(1)

    # 2. Spreads 1..24 -> Pages 2..49
    for sp in book_layout["spreads"]:
        sp_type = sp["type"]
        if sp_type == "front_matter_spread":
            for page_obj in (sp["left_page"], sp["right_page"]):
                pnum = page_obj["page_number"]
                start_page(pnum)
                render_front_matter_page(c, pnum, page_obj, cfg)
                finish_page(pnum)
        elif sp_type == "prayer_art_spread":
            lp, rp = sp["left_page"], sp["right_page"]
            start_page(lp["page_number"])
            render_prayer_sequence_page(c, lp["page_number"], lp, prayers, cfg)
            finish_page(lp["page_number"])
            start_page(rp["page_number"])
            render_artwork_page(
                c, rp["page_number"], rp.get("subheading", ""), rp.get("heading", ""), rp["artwork"], data_root, cfg
            )
            finish_page(rp["page_number"])
        elif sp_type == "mystery_spread":
            mys = mysteries_by_id[sp["id"]]
            lp_num, rp_num = int(sp["left_page_number"]), int(sp["right_page_number"])
            start_page(lp_num)
            render_mystery_prayer_page(c, lp_num, mys, decade_seq, prayers, cfg)
            finish_page(lp_num)
            start_page(rp_num)
            render_artwork_page(
                c, rp_num, mys.get("ordinal_label", ""), mys.get("title", ""), mys["artwork"], data_root, cfg
            )
            finish_page(rp_num)
        elif sp_type == "credits_spread":
            for page_obj in (sp["left_page"], sp["right_page"]):
                pnum = page_obj["page_number"]
                start_page(pnum)
                render_credits_page(c, pnum, page_obj, artworks_by_id, version, cfg)
                finish_page(pnum)

    # 3. Page 50: Back Cover
    start_page(50)
    render_page_50_back_cover(c, book_layout, cfg)
    finish_page(50)

    c.save()
    postprocess_pdf(output_path, cfg, trans_x=trans_x, trans_y=trans_y)

    size_mb = output_path.stat().st_size / (1024 * 1024)
    if cfg.vervante:
        guide_path = build_vervante_assembly_guide(
            output_path.parent / "README_Print_and_Assembly_Guide.pdf",
            project_root=data_root,
        )
        print(f"Generated ({cfg.mode_label}): {output_path} (50 pages, {size_mb:.2f} MB)")
        for split_label, split_suffix, page_count in (
            ("Vervante Covers", "_Covers", len(VERVANTE_COVER_PAGES)),
            ("Vervante Interior", "_Interior", len(VERVANTE_INTERIOR_PAGES)),
            ("Vervante Tabs", "_Tabs", len(VERVANTE_TAB_PAGES)),
        ):
            split_path = output_path.with_name(f"{output_path.stem}{split_suffix}{output_path.suffix}")
            if split_path.exists():
                split_mb = split_path.stat().st_size / (1024 * 1024)
                print(f"Generated ({split_label}): {split_path} ({page_count} pages, {split_mb:.2f} MB)")
        if guide_path.exists():
            guide_kb = guide_path.stat().st_size / 1024.0
            print(f"Generated (Vervante Assembly Guide): {guide_path} (2 pages, {guide_kb:.1f} KB)")
    else:
        print(f"Generated ({cfg.mode_label}): {output_path} ({size_mb:.2f} MB)")
    return output_path


def build_all_print_pdfs(
    project_root: Optional[Path] = None,
    output_dir: Optional[Path] = None,
) -> List[Path]:
    """
    Sequentially builds all 8 tracked print PDF files across 4 editions under `assets/print/`:
      1. `PrayTheRosary.pdf` (Standard 6.0" x 9.0", 50 pages)
      2. `PrayTheRosary_Tabs.pdf` (Tabbed 6.375" x 9.0", 50 pages)
      3. `PrayTheRosary_Tabs_Bleed.pdf` (Tabbed + Bleed 6.625" x 9.25", 50 pages)
      4. `Vervante/PrayTheRosary_Vervante.pdf` (Vervante Press-Ready Combined, 50 pages)
      5. `Vervante/PrayTheRosary_Vervante_Covers.pdf` (Vervante Covers, 4 pages at 6.5" x 9.0")
      6. `Vervante/PrayTheRosary_Vervante_Interior.pdf` (Vervante Interior, 34 pages at 6.0" x 9.0")
      7. `Vervante/PrayTheRosary_Vervante_Tabs.pdf` (Vervante Tabs, 12 pages at 6.5" x 9.0")
      8. `Vervante/README_Print_and_Assembly_Guide.pdf` (Vervante Print & Bindery Assembly Guide, 2 pages at 8.5" x 11.0")
    """
    root = Path(project_root) if project_root is not None else PROJECT_ROOT
    print_dir = Path(output_dir) if output_dir is not None else (root / "assets" / "print")
    vervante_dir = print_dir / "Vervante"
    vervante_master = vervante_dir / "PrayTheRosary_Vervante.pdf"
    return [
        build_print_pdf(print_dir / "PrayTheRosary.pdf", project_root=root, config=PrintConfig.standard()),
        build_print_pdf(print_dir / "PrayTheRosary_Tabs.pdf", project_root=root, config=PrintConfig.tabs_only()),
        build_print_pdf(print_dir / "PrayTheRosary_Tabs_Bleed.pdf", project_root=root, config=PrintConfig.tabs_and_bleed()),
        build_print_pdf(vervante_master, project_root=root, config=PrintConfig.vervante_mode()),
        vervante_dir / "PrayTheRosary_Vervante_Covers.pdf",
        vervante_dir / "PrayTheRosary_Vervante_Interior.pdf",
        vervante_dir / "PrayTheRosary_Vervante_Tabs.pdf",
        vervante_dir / "README_Print_and_Assembly_Guide.pdf",
    ]


# Bind orchestrator functions onto `scripts.pdf_builder` for direct package imports
_pdf_builder_pkg.build_print_pdf = build_print_pdf  # type: ignore[attr-defined]
_pdf_builder_pkg.build_all_print_pdfs = build_all_print_pdfs  # type: ignore[attr-defined]


def main(argv: Optional[List[str]] = None) -> None:
    """CLI entry point supporting single-mode builds and `--all` (`-a`) batch generation."""
    parser = argparse.ArgumentParser(description="Pray The Rosary Print PDF Generator")
    parser.add_argument("--output", "-o", type=str, default=None, help="Custom output PDF path")
    parser.add_argument("--bleed", action="store_true", help='Generate pages with 0.125" bleed and TrimBox')
    parser.add_argument("--tabs", action="store_true", help='Generate 6.375" x 9.0" overhang covers and 6 stepped index tabs')
    parser.add_argument(
        "-V", "--Vervante", "--vervante",
        action="store_true",
        dest="vervante",
        help='Generate Vervante press-ready PDFs (50-page combined + Covers, Interior, Tabs, and Assembly Guide PDFs)',
    )
    parser.add_argument(
        "--office-depot", "--letter",
        action="store_true",
        dest="office_depot",
        help='Center pages onto 8.5" x 11.0" US Letter with crop marks',
    )
    parser.add_argument(
        "--all", "-a",
        action="store_true",
        dest="build_all",
        help="Batch-generate all 8 tracked print PDF files in assets/print/",
    )
    args = parser.parse_args(argv)

    if args.build_all:
        build_all_print_pdfs(output_dir=Path(args.output).resolve() if args.output else None)
        return

    if args.output:
        out_path = Path(args.output).resolve()
    elif args.vervante:
        out_path = DEFAULT_VERVANTE_PDF
    elif args.office_depot:
        out_path = DEFAULT_OFFICE_DEPOT_PDF
    elif args.tabs and args.bleed:
        out_path = DEFAULT_TABS_BLEED_PDF
    elif args.tabs:
        out_path = DEFAULT_TABS_PDF
    else:
        out_path = DEFAULT_OUTPUT_PDF

    build_print_pdf(out_path, bleed=args.bleed, office_depot=args.office_depot, tabs=args.tabs, vervante=args.vervante)


if __name__ == "__main__":
    main()
