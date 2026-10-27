"""
Fast, isolated unit tests for the modular `scripts/pdf_builder/` package.

Validates:
  - `PrintConfig` factory constructors, immutability, and computed geometry properties
  - `get_gold_box`, `get_content_box`, and `is_vervante_wide_page` coordinate math
    across odd (Recto), even (Verso), overhang cover, and 1/6-cut tab pages
  - `data_loader` (`get_project_version`, fallback versioning, and `load_all_data` cross-indexing)
  - `primitives` typography measurement and image cache lifecycle
  - 100% backwards-compatible symbol re-exports on `scripts.build_print_pdf` and `scripts.pdf_builder`
"""

import dataclasses
import sys
import tempfile
import unittest
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

import scripts.build_print_pdf as cli_module  # noqa: E402
import scripts.pdf_builder as pkg_module  # noqa: E402
from scripts.pdf_builder.config import (  # noqa: E402
    BLEED,
    LETTER_H,
    LETTER_W,
    PAGE_H,
    PAGE_W,
    TAB_EXT,
    TAB_PAGE_W,
    TAB_SPECS,
    VERVANTE_CROP_MARGIN,
    VERVANTE_TAB_EXT,
    PrintConfig,
    is_vervante_wide_page,
)
from scripts.pdf_builder.data_loader import get_project_version, load_all_data  # noqa: E402
from scripts.pdf_builder.primitives import (  # noqa: E402
    _IMAGE_CACHE,
    clear_image_cache,
    get_content_box,
    get_gold_box,
    make_style,
    measure_header_block,
    measure_para,
)


class TestPdfBuilderModules(unittest.TestCase):
    """Unit tests for `scripts.pdf_builder` submodules and configuration geometry."""

    def test_print_config_factory_presets_and_properties(self) -> None:
        """Verifies all PrintConfig factory constructors and computed canvas/trim dimensions."""
        # 1. Standard 6.0" x 9.0" (432 x 648 pt)
        std = PrintConfig.standard()
        self.assertFalse(std.tabs)
        self.assertFalse(std.bleed)
        self.assertFalse(std.vervante)
        self.assertFalse(std.office_depot)
        self.assertFalse(std.has_tabs)
        self.assertFalse(std.has_bleed)
        self.assertEqual(std.active_tab_ext, 0.0)
        self.assertAlmostEqual(std.effective_width, 432.0)
        self.assertAlmostEqual(std.total_width, 432.0)
        self.assertAlmostEqual(std.total_height, 648.0)
        self.assertEqual(std.mode_label, "Standard 6x9")

        # 2. Bleed only: 6.25" x 9.25" (450 x 666 pt)
        bld = PrintConfig.bleed_only()
        self.assertEqual(bld, PrintConfig.bleed())
        self.assertFalse(bld.tabs)
        self.assertTrue(bld.bleed)
        self.assertTrue(bld.has_bleed)
        self.assertAlmostEqual(bld.effective_width, 432.0)
        self.assertAlmostEqual(bld.total_width, 450.0)
        self.assertAlmostEqual(bld.total_height, 666.0)
        self.assertEqual(bld.mode_label, "Bleed")

        # 3. Tabs only: 6.375" x 9.0" (459 x 648 pt)
        tbs = PrintConfig.tabs_only()
        self.assertEqual(tbs, PrintConfig.tabs())
        self.assertTrue(tbs.tabs)
        self.assertFalse(tbs.bleed)
        self.assertTrue(tbs.has_tabs)
        self.assertFalse(tbs.has_bleed)
        self.assertAlmostEqual(tbs.active_tab_ext, 27.0)
        self.assertAlmostEqual(tbs.effective_width, 459.0)
        self.assertAlmostEqual(tbs.total_width, 459.0)
        self.assertAlmostEqual(tbs.total_height, 648.0)
        self.assertEqual(tbs.mode_label, "Tabs 6.375x9")

        # 4. Tabs + Bleed: 6.625" x 9.25" (477 x 666 pt)
        tb = PrintConfig.tabs_and_bleed()
        self.assertEqual(tb, PrintConfig.tabs_bleed())
        self.assertTrue(tb.tabs)
        self.assertTrue(tb.bleed)
        self.assertTrue(tb.has_tabs)
        self.assertTrue(tb.has_bleed)
        self.assertAlmostEqual(tb.active_tab_ext, 27.0)
        self.assertAlmostEqual(tb.effective_width, 459.0)
        self.assertAlmostEqual(tb.total_width, 477.0)
        self.assertAlmostEqual(tb.total_height, 666.0)
        self.assertEqual(tb.mode_label, "Tabs+Bleed")

        # 5. Vervante mode: 6.5" x 9.0" wide pages (468 pt trim, 522 pt canvas),
        #    6.0" x 9.0" interior pages (432 pt trim, 486 pt canvas)
        vrv = PrintConfig.vervante_mode()
        self.assertEqual(vrv, PrintConfig.vervante())
        self.assertTrue(vrv.vervante)
        self.assertTrue(vrv.has_tabs)
        self.assertTrue(vrv.has_bleed)
        self.assertAlmostEqual(vrv.active_tab_ext, 36.0)
        # Page 1 (wide cover)
        self.assertAlmostEqual(vrv.effective_page_width(1), 468.0)
        self.assertAlmostEqual(vrv.total_canvas_width(1), 468.0 + 2 * VERVANTE_CROP_MARGIN)
        # Page 7 (standard interior page)
        self.assertAlmostEqual(vrv.effective_page_width(7), 432.0)
        self.assertAlmostEqual(vrv.total_canvas_width(7), 432.0 + 2 * VERVANTE_CROP_MARGIN)
        self.assertAlmostEqual(vrv.total_canvas_height(), 648.0 + 2 * VERVANTE_CROP_MARGIN)
        self.assertEqual(vrv.mode_label, "Vervante Press-Ready")

        # 6. Office Depot mode: 8.5" x 11.0" US Letter (612 x 792 pt)
        od = PrintConfig.office_depot_mode()
        self.assertEqual(od, PrintConfig.office_depot())
        self.assertTrue(od.office_depot)
        self.assertTrue(od.has_bleed)
        self.assertAlmostEqual(od.effective_width, 432.0)
        self.assertAlmostEqual(od.total_width, LETTER_W)
        self.assertAlmostEqual(od.total_height, LETTER_H)
        self.assertEqual(od.mode_label, "Office Depot")

    def test_print_config_is_immutable(self) -> None:
        """Verifies PrintConfig instances are frozen and cannot be mutated in place."""
        cfg = PrintConfig.standard()
        with self.assertRaises(dataclasses.FrozenInstanceError):
            cfg.tabs = True  # type: ignore[misc]

    def test_is_vervante_wide_page_classification(self) -> None:
        """Verifies exactly 16 pages (4 cover pages + 12 tab pages) are wide in Vervante mode."""
        wide_pages = [p for p in range(1, 51) if is_vervante_wide_page(p)]
        expected_wide = sorted({1, 2, 49, 50} | set(TAB_SPECS.keys()))
        self.assertEqual(len(expected_wide), 16)
        self.assertEqual(wide_pages, expected_wide)
        # Standard interior pages (e.g. Page 7, Page 10, Page 48) must be False
        for p in (7, 8, 10, 20, 47, 48):
            self.assertFalse(is_vervante_wide_page(p), f"Page {p} should be 6.0x9.0 interior page")

    def test_gold_box_and_content_box_geometry(self) -> None:
        """Verifies get_gold_box and get_content_box across odd, even, and overhang cover pages."""
        std = PrintConfig.standard()
        tabs_cfg = PrintConfig.tabs_only()
        verv_cfg = PrintConfig.vervante_mode()

        # 1. Standard mode: Odd page (Recto) has 0.625" (45 pt) left spine margin
        gx_odd, gy_odd, gw_odd, gh_odd = get_gold_box(1, std)
        self.assertAlmostEqual(gx_odd, 45.0)
        self.assertAlmostEqual(gy_odd, 36.0)
        self.assertAlmostEqual(gw_odd, 351.0)
        self.assertAlmostEqual(gh_odd, 576.0)

        # 2. Standard mode: Even page (Verso) has 0.500" (36 pt) left outer margin
        gx_even, gy_even, gw_even, gh_even = get_gold_box(2, std)
        self.assertAlmostEqual(gx_even, 36.0)
        self.assertAlmostEqual(gy_even, 36.0)
        self.assertAlmostEqual(gw_even, 351.0)
        self.assertAlmostEqual(gh_even, 576.0)

        # 3. Tabs mode: Page 1 Front Cover widens by TAB_EXT (27 pt) -> width = 378 pt
        gx_t1, gy_t1, gw_t1, gh_t1 = get_gold_box(1, tabs_cfg)
        self.assertAlmostEqual(gx_t1, 45.0)
        self.assertAlmostEqual(gw_t1, 351.0 + TAB_EXT)

        # 4. Tabs mode: Page 50 Back Cover shifts left by -TAB_EXT (-27 + 36 = 9 pt) and widens by TAB_EXT
        gx_t50, gy_t50, gw_t50, gh_t50 = get_gold_box(50, tabs_cfg)
        self.assertAlmostEqual(gx_t50, 36.0 - TAB_EXT)
        self.assertAlmostEqual(gw_t50, 351.0 + TAB_EXT)

        # 5. Vervante mode: Page 1 widens by VERVANTE_TAB_EXT (36 pt) -> width = 387 pt
        gx_v1, _, gw_v1, _ = get_gold_box(1, verv_cfg)
        self.assertAlmostEqual(gx_v1, 45.0)
        self.assertAlmostEqual(gw_v1, 351.0 + VERVANTE_TAB_EXT)

        # 6. Content box inset math (both keyword and positional cfg calling conventions)
        cx1, cy1, cw1, ch1 = get_content_box(1, pad_x=16.0, pad_y=14.0, cfg=std)
        cx2, cy2, cw2, ch2 = get_content_box(1, std, 16.0, 14.0)
        self.assertAlmostEqual(cx1, 45.0 + 16.0)
        self.assertAlmostEqual(cy1, 36.0 + 14.0)
        self.assertAlmostEqual(cw1, 351.0 - 32.0)
        self.assertAlmostEqual(ch1, 576.0 - 28.0)
        self.assertEqual((cx1, cy1, cw1, ch1), (cx2, cy2, cw2, ch2))

    def test_data_loader_cross_indexing_and_version_extraction(self) -> None:
        """Verifies load_all_data cross-indexes 20 mysteries and 23 artworks, and get_project_version works."""
        version = get_project_version(PROJECT_ROOT)
        self.assertRegex(version, r"^\d+\.\d+\.\d+$")

        with tempfile.TemporaryDirectory() as tmp_dir:
            tmp_path = Path(tmp_dir)
            self.assertEqual(get_project_version(tmp_path), "1.0.2")
            # Custom synthetic project.godot version
            (tmp_path / "game").mkdir(parents=True, exist_ok=True)
            (tmp_path / "game" / "project.godot").write_text(
                '[application]\nconfig/name="Pray The Rosary"\nconfig/version="9.8.7"\n',
                encoding="utf-8",
            )
            self.assertEqual(get_project_version(tmp_path), "9.8.7")

        book_layout, prayers, mysteries_raw, mysteries_by_id, artworks_by_id = load_all_data(PROJECT_ROOT)
        self.assertIn("front_cover", book_layout)
        self.assertIn("back_cover", book_layout)
        self.assertEqual(len(book_layout["spreads"]), 24)
        self.assertEqual(len(mysteries_by_id), 20)
        self.assertEqual(len(artworks_by_id), 23)
        self.assertEqual(artworks_by_id["cover"]["section_label"], "Front Cover")
        self.assertEqual(artworks_by_id["opening_prayers"]["section_label"], "Opening Prayers")
        self.assertEqual(artworks_by_id["closing_prayers"]["section_label"], "Closing Prayers")
        self.assertIn("1st Joyful Mystery", artworks_by_id["joyful_1_annunciation"]["section_label"])
        self.assertIn("joyful_1_annunciation", mysteries_by_id)
        self.assertIn("hail_mary", prayers)

    def test_primitives_measurement_and_image_cache_clear(self) -> None:
        """Verifies typography measurement helpers and image cache lifecycle."""
        st = make_style("test_style", "EBGaramond-Regular", 10.5, 13.0)
        h = measure_para("Hail Mary, full of grace, the Lord is with thee.", st, 300.0)
        self.assertGreater(h, 10.0)

        h_head = measure_header_block(319.0, "First Joyful Mystery", "The Annunciation")
        self.assertGreater(h_head, 25.0)

        clear_image_cache()
        self.assertEqual(len(_IMAGE_CACHE), 0)

    def test_backwards_compatible_symbol_reexports(self) -> None:
        """Verifies scripts.build_print_pdf and scripts.pdf_builder expose all public symbols."""
        expected_symbols = [
            "build_print_pdf",
            "build_all_print_pdfs",
            "PrintConfig",
            "get_project_version",
            "load_all_data",
            "TAB_SPECS",
            "is_vervante_wide_page",
            "get_gold_box",
            "get_content_box",
            "make_style",
            "draw_para",
            "measure_para",
            "draw_header_block",
            "measure_header_block",
            "draw_framed_image",
            "draw_master_a_background_and_border",
            "draw_tab_or_overhang",
            "draw_crop_marks",
            "render_page_1_front_cover",
            "render_front_matter_page",
            "render_prayer_sequence_page",
            "render_artwork_page",
            "render_mystery_prayer_page",
            "render_credits_page",
            "render_page_50_back_cover",
            "postprocess_pdf",
            "PAGE_W",
            "PAGE_H",
            "TAB_EXT",
            "TAB_PAGE_W",
            "VERVANTE_TAB_EXT",
            "VERVANTE_CROP_MARGIN",
            "BLEED",
            "COLOR_PARCHMENT",
            "COLOR_GOLD",
            "COLOR_CRIMSON",
            "BACK_PRIMARY",
            "BACK_GOLD",
        ]
        for sym in expected_symbols:
            self.assertTrue(hasattr(cli_module, sym), f"scripts.build_print_pdf missing re-export: {sym}")
            self.assertTrue(hasattr(pkg_module, sym), f"scripts.pdf_builder missing export: {sym}")
            self.assertIs(getattr(cli_module, sym), getattr(pkg_module, sym))


if __name__ == "__main__":
    unittest.main()
