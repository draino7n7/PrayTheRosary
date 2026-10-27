"""
Unit tests for the automated print PDF pipeline (scripts/build_print_pdf.py).
Validates page geometry, typography standards, text content, and CLI flags.
"""

import os
import re
import sys
import tempfile
import unittest
from pathlib import Path

import pymupdf

PROJECT_ROOT = Path(__file__).resolve().parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))
SCRIPTS_DIR = PROJECT_ROOT / "scripts"
CANONICAL_PDF = PROJECT_ROOT / "assets" / "print" / "PrayTheRosary.pdf"
GODOT_PROJECT = PROJECT_ROOT / "game" / "project.godot"
AFFINITY_DIR = PROJECT_ROOT / "assets" / "Affinity"
GITATTRIBUTES = PROJECT_ROOT / ".gitattributes"


class TestBuildPrintPdf(unittest.TestCase):
    """Validates the canonical print PDF and the PDF generator pipeline."""

    @classmethod
    def setUpClass(cls):
        # Ensure the canonical PDF exists before running tests
        if not CANONICAL_PDF.exists():
            from scripts.build_print_pdf import build_print_pdf
            build_print_pdf(CANONICAL_PDF)

    def test_affinity_files_removed(self):
        """Verifies assets/Affinity has been completely deleted."""
        self.assertFalse(
            AFFINITY_DIR.exists(),
            f"assets/Affinity directory should not exist, but found at {AFFINITY_DIR}",
        )

    def test_gitattributes_rules(self):
        """Verifies .gitattributes has no *.af rules and preserves *.pdf under Git LFS."""
        self.assertTrue(GITATTRIBUTES.exists(), ".gitattributes file is missing")
        content = GITATTRIBUTES.read_text(encoding="utf-8")
        self.assertNotIn("*.af ", content)
        self.assertNotIn("*.afpub", content)
        self.assertNotIn("*.afdesign", content)
        self.assertNotIn("*.afphoto", content)
        self.assertIn("*.pdf filter=lfs diff=lfs merge=lfs -text", content)

    def test_canonical_pdf_page_count_and_geometry(self):
        """Verifies PrayTheRosary.pdf has exactly 50 pages at 6.0" x 9.0" (432 x 648 pt)."""
        self.assertTrue(CANONICAL_PDF.exists(), f"Missing canonical PDF: {CANONICAL_PDF}")
        doc = pymupdf.open(str(CANONICAL_PDF))
        try:
            self.assertEqual(len(doc), 50, f"Expected 50 pages, got {len(doc)}")
            for idx, page in enumerate(doc):
                rect = page.rect
                self.assertAlmostEqual(rect.width, 432.0, delta=1.0, msg=f"Page {idx+1} width mismatch")
                self.assertAlmostEqual(rect.height, 648.0, delta=1.0, msg=f"Page {idx+1} height mismatch")
        finally:
            doc.close()

    def test_zero_italic_fonts_embedded(self):
        """Verifies zero italic fonts are embedded anywhere in the generated 50 pages."""
        doc = pymupdf.open(str(CANONICAL_PDF))
        try:
            embedded_fonts = set()
            for page in doc:
                for font_entry in page.get_fonts():
                    base_name = font_entry[3]
                    embedded_fonts.add(base_name)
                    self.assertNotIn(
                        "italic",
                        base_name.lower(),
                        f"Page {page.number+1} embeds italic font: {base_name}",
                    )
            # Ensure upright EB Garamond fonts are indeed used
            has_regular = any("EBGaramond-Regular" in f for f in embedded_fonts)
            has_bold = any("EBGaramond-Bold" in f for f in embedded_fonts)
            self.assertTrue(has_regular, "Expected EBGaramond-Regular to be embedded")
            self.assertTrue(has_bold, "Expected EBGaramond-Bold to be embedded")
        finally:
            doc.close()

    def test_page_48_creator_attribution_and_version(self):
        """Verifies Page 48 bottom colophon displays Kevin Audrain attribution and dynamic version."""
        # Read target version from game/project.godot
        godot_content = GODOT_PROJECT.read_text(encoding="utf-8")
        match = re.search(r'config/version="([^"]+)"', godot_content)
        self.assertIsNotNone(match, "Could not extract config/version from game/project.godot")
        version_str = match.group(1).strip()

        doc = pymupdf.open(str(CANONICAL_PDF))
        try:
            p48_text = doc[47].get_text()
            self.assertIn("This edition of “Pray the Rosary” was created and is maintained by Kevin Audrain.", p48_text)
            self.assertIn(f"Version {version_str}", p48_text)
        finally:
            doc.close()

    def test_page_49_cpdv_and_artwork_colophon(self):
        """Verifies Page 49 colophon includes CPDV scripture notice and artwork acknowledgments."""
        doc = pymupdf.open(str(CANONICAL_PDF))
        try:
            p49_text = doc[48].get_text()
            self.assertIn("Catholic Public Domain Version (CPDV)", p49_text)
            self.assertIn("sacredbible.org", p49_text)
            self.assertIn("public-domain masterworks", p49_text)
            self.assertIn("Dulwich Picture Gallery (London)", p49_text)
            self.assertIn("Museo Nacional del Prado (Madrid)", p49_text)
            self.assertIn("Princeton University Art Museum (Princeton)", p49_text)
            self.assertIn("Frederiksborg Castle (Hillerød)", p49_text)
        finally:
            doc.close()

    def test_credits_pages_museum_attributions(self):
        """Verifies updated museum attributions on Page 48 and Page 49 credits."""
        doc = pymupdf.open(str(CANONICAL_PDF))
        try:
            p48_text = " ".join(doc[47].get_text().split())
            self.assertIn("The Madonna of the Rosary (The Virgin of the Rosary)", p48_text)
            self.assertIn("Dulwich Picture Gallery, London, UK", p48_text)
            self.assertIn("The Marriage Feast at Cana", p48_text)

            p49_text = " ".join(doc[48].get_text().split())
            self.assertIn("The Crowning with Thorns (La coronación de espinas)", p49_text)
            self.assertIn("The Assumption of the Virgin (The Walpole Immaculate Conception)", p49_text)
        finally:
            doc.close()

    def test_page_50_back_cover_quotes_and_synopsis(self):
        """Verifies Page 50 displays epigraph, synopsis, and Marian counsel."""
        doc = pymupdf.open(str(CANONICAL_PDF))
        try:
            p50_text = " ".join(doc[49].get_text().split())
            self.assertIn("Pope St. John Paul II", p50_text)
            self.assertIn("Christocentric prayer", p50_text)
            self.assertIn("St. Louis Marie de Montfort", p50_text)
            self.assertIn("The Secret of the Rosary", p50_text)
            self.assertIn("breathtaking Renaissance and Baroque masterworks", p50_text)
            self.assertNotIn("twenty-three breathtaking", p50_text)
        finally:
            doc.close()

    def test_prayers_and_scripture_content(self):
        """Verifies modernized Apostles' Creed, USCCB Fruits, and CPDV Scripture verses."""
        doc = pymupdf.open(str(CANONICAL_PDF))
        try:
            # Modernized Apostles' Creed on Page 4 (Spread 2 left page)
            p4_text = " ".join(doc[3].get_text().split())
            self.assertIn("He rose again from the dead", p4_text)
            self.assertIn("ascended into heaven", p4_text.lower())

            # Check 1st Joyful Mystery on Page 6 (Spread 3 left page)
            p6_text = " ".join(doc[5].get_text().split())
            self.assertIn("Fruit of the Mystery: Humility", p6_text)
            self.assertIn("Luke 1:28, 38", p6_text)
            self.assertIn("Hail, full of grace", p6_text)
        finally:
            doc.close()

    def test_issue_85_pdf_refinements(self):
        """Verifies rubrics, titles, and prose refinements across the generated PDF."""
        doc = pymupdf.open(str(CANONICAL_PDF))
        try:
            # Page 2: prose refinement
            p2_text = " ".join(doc[1].get_text().split())
            self.assertIn("Paternoster cords—a devotion later adapted to 150 Hail Marys as Our Lady's Psalter", p2_text)

            # Page 4: rubrics
            p4_text = " ".join(doc[3].get_text().split())
            self.assertIn("Profess the Apostles' Creed:", p4_text)
            self.assertIn("Pray the Our Father for the intentions of the Holy Father and the Church:", p4_text)

            # Page 46: rubrics and titles
            p46_text = " ".join(doc[45].get_text().split())
            self.assertIn("The Hail, Holy Queen", p46_text)
            self.assertIn("Conclude with the Concluding Rosary Prayer:", p46_text)
            self.assertIn("The Concluding Rosary Prayer", p46_text)
            self.assertIn("Most Holy Rosary", p46_text)
        finally:
            doc.close()

    def test_page_2_history_content(self):
        """Verifies Page 2 displays the updated mystery summaries and feast note."""
        doc = pymupdf.open(str(CANONICAL_PDF))
        try:
            p2_text = " ".join(doc[1].get_text().split())
            self.assertIn("From the earliest centuries of the Church, monastic communities chanted the 150 Psalms of David daily.", p2_text)
            self.assertIn("Paternoster cords—a devotion later adapted to 150 Hail Marys as Our Lady's Psalter (the Psalter of the Blessed Virgin Mary).", p2_text)
            self.assertIn("paired the Marian Psalter (the 150 Hail Marys) with structured meditations on the life of Christ.", p2_text)
            self.assertIn("In 1569, Pope St. Pius V formally established the traditional fifteen decades and Mysteries", p2_text)
            self.assertIn("Joyful Mysteries (Christ's Incarnation and early life)", p2_text)
            self.assertIn("Sorrowful Mysteries (His Passion and Death)", p2_text)
            self.assertIn("Glorious Mysteries (His Resurrection and Ascension, Pentecost, and Mary's Assumption and Coronation)", p2_text)
            self.assertIn("Following the Christian naval victory at Lepanto in 1571, he instituted the feast of Our Lady of Victory (renamed the Feast of Our Lady of the Rosary by Pope Gregory XIII in 1573).", p2_text)
            self.assertIn("Pope St. John Paul II expanded the Mysteries of the Rosary to include the five Luminous Mysteries", p2_text)
            self.assertNotIn("(the Mysteries of Light)", p2_text)
        finally:
            doc.close()

    def test_bleed_flag_geometry(self):
        """Verifies --bleed generates 450 x 666 pt pages with TrimBox (9, 9, 441, 657) and BleedBox."""
        from scripts.build_print_pdf import build_print_pdf
        with tempfile.TemporaryDirectory() as tmp_dir:
            tmp_pdf = Path(tmp_dir) / "bleed_test.pdf"
            build_print_pdf(tmp_pdf, bleed=True)
            self.assertTrue(tmp_pdf.exists())

            doc = pymupdf.open(str(tmp_pdf))
            try:
                self.assertEqual(len(doc), 50)
                for idx, page in enumerate(doc):
                    self.assertAlmostEqual(page.rect.width, 450.0, delta=1.0)
                    self.assertAlmostEqual(page.rect.height, 666.0, delta=1.0)
                    trim = page.trimbox
                    self.assertAlmostEqual(trim.x0, 9.0, delta=1.0)
                    self.assertAlmostEqual(trim.y0, 9.0, delta=1.0)
                    self.assertAlmostEqual(trim.x1, 441.0, delta=1.0)
                    self.assertAlmostEqual(trim.y1, 657.0, delta=1.0)
                    bleed = page.bleedbox
                    self.assertAlmostEqual(bleed.x0, 0.0, delta=1.0)
                    self.assertAlmostEqual(bleed.y0, 0.0, delta=1.0)
                    self.assertAlmostEqual(bleed.x1, 450.0, delta=1.0)
                    self.assertAlmostEqual(bleed.y1, 666.0, delta=1.0)
            finally:
                doc.close()

    def test_office_depot_flag_geometry(self):
        """Verifies --office-depot generates 612 x 792 pt (US Letter) pages with centered trim."""
        from scripts.build_print_pdf import build_print_pdf
        with tempfile.TemporaryDirectory() as tmp_dir:
            tmp_pdf = Path(tmp_dir) / "office_depot_test.pdf"
            build_print_pdf(tmp_pdf, office_depot=True)
            self.assertTrue(tmp_pdf.exists())

            doc = pymupdf.open(str(tmp_pdf))
            try:
                self.assertEqual(len(doc), 50)
                for idx, page in enumerate(doc):
                    self.assertAlmostEqual(page.rect.width, 612.0, delta=1.0)
                    self.assertAlmostEqual(page.rect.height, 792.0, delta=1.0)
                    trim = page.trimbox
                    self.assertAlmostEqual(trim.x0, 90.0, delta=1.0)
                    self.assertAlmostEqual(trim.y0, 72.0, delta=1.0)
                    self.assertAlmostEqual(trim.x1, 522.0, delta=1.0)
                    self.assertAlmostEqual(trim.y1, 720.0, delta=1.0)
            finally:
                doc.close()


    def test_issue_87_page_1_front_cover_crimson_palette_and_typography(self):
        """Verifies Page 1 renders deep Baroque crimson background, gold border, and ivory subtitle."""
        doc = pymupdf.open(str(CANONICAL_PDF))
        try:
            p1 = doc[0]
            p1_text = " ".join(p1.get_text().split())
            self.assertIn("PRAY THE ROSARY", p1_text)
            self.assertIn("A Contemplative Visual Guide to the Twenty Mysteries", p1_text)

            drawings = p1.get_drawings()
            self.assertTrue(len(drawings) >= 2, "Page 1 must contain cover background fill and framing borders")
            # Background fill is deep Baroque crimson (#4A1215)
            bg_fill = drawings[0].get("fill")
            self.assertIsNotNone(bg_fill)
            self.assertAlmostEqual(bg_fill[0], 0.290, delta=0.01)
            self.assertAlmostEqual(bg_fill[1], 0.071, delta=0.01)
            self.assertAlmostEqual(bg_fill[2], 0.082, delta=0.01)

            # Gold framing border (#D4AF37)
            border_stroke = drawings[1].get("color")
            self.assertIsNotNone(border_stroke)
            self.assertAlmostEqual(border_stroke[0], 0.831, delta=0.01)
            self.assertAlmostEqual(border_stroke[1], 0.686, delta=0.01)
            self.assertAlmostEqual(border_stroke[2], 0.216, delta=0.01)
        finally:
            doc.close()

    def test_issue_87_page_4_step_4_three_hail_marys_prefix(self):
        """Verifies Page 4 Step 4 renders '3× The Hail Mary' title prefix."""
        doc = pymupdf.open(str(CANONICAL_PDF))
        try:
            p4_text = doc[3].get_text()
            self.assertIn("3× The Hail Mary", p4_text)
        finally:
            doc.close()

    def test_issue_87_credits_formatting_and_non_duplicate_headers(self):
        """Verifies Pages 48-49 credits merge artist dates cleanly without )...( and omit duplicate mystery titles."""
        doc = pymupdf.open(str(CANONICAL_PDF))
        try:
            p48_text = " ".join(doc[47].get_text().split())
            p49_text = " ".join(doc[48].get_text().split())

            # No double-parentheses )...( on either credits page
            self.assertNotIn(")...(", p48_text)
            self.assertNotIn(")...(", p49_text)

            # Merged sobriquets and dates
            self.assertIn("El Greco (Doménikos Theotokópoulos, 1541–1614)", p48_text)
            self.assertIn("Giovanni Battista Caracciolo (Battistello, 1578–1635)", p49_text)
            self.assertIn("Raphael (Raffaello Sanzio, 1483–1520)", p49_text)

            # Non-duplicate header titles: '1st Joyful Mystery — The Annunciation' (not '... Mystery (The Annunciation) — The Annunciation')
            self.assertIn("1st Joyful Mystery — The Annunciation (La Anunciación)", p48_text)
            self.assertNotIn("1st Joyful Mystery (The Annunciation) — The Annunciation", p48_text)
            self.assertIn("1st Sorrowful Mystery — Christ on the Mount of Olives (Christ's Fear of Death)", p49_text)
            self.assertNotIn("1st Sorrowful Mystery (The Agony in the Garden) —", p49_text)
        finally:
            doc.close()

    def test_issue_87_page_49_colophon_and_page_50_attribution_styling(self):
        """Verifies Page 49 colophon styling and Page 50 attribution regular serif font weight."""
        doc = pymupdf.open(str(CANONICAL_PDF))
        try:
            p50 = doc[49]
            p50_text = p50.get_text()
            self.assertIn("Pope St. John Paul II", p50_text)
            self.assertIn("St. Louis Marie de Montfort", p50_text)

            # In Page 50, attributions use EBGaramond-Regular
            fonts_p50 = [f[3] for f in p50.get_fonts()]
            self.assertTrue(any("EBGaramond-Regular" in f for f in fonts_p50))
        finally:
            doc.close()

    def test_issue_88_get_project_version_and_fallback(self):
        """Verifies get_project_version correctly extracts version from project.godot and returns fallback 1.0.2."""
        from scripts.build_print_pdf import get_project_version

        # 1. Real project root matches project.godot config/version="1.0.2"
        version = get_project_version(PROJECT_ROOT)
        self.assertEqual(version, "1.0.2")

        # 2. Empty directory returns synchronized fallback version 1.0.2
        with tempfile.TemporaryDirectory() as tmp_dir:
            fallback = get_project_version(Path(tmp_dir))
            self.assertEqual(fallback, "1.0.2")

    def test_tabs_and_tabs_bleed_flag_geometry_and_monograms(self):
        """Verifies --tabs (459 x 648 pt) and --tabs --bleed (477 x 666 pt) geometry and tab monograms."""
        from scripts.build_print_pdf import TAB_SPECS, build_print_pdf
        with tempfile.TemporaryDirectory() as tmp_dir:
            tabs_pdf = Path(tmp_dir) / "tabs_test.pdf"
            build_print_pdf(tabs_pdf, tabs=True)
            self.assertTrue(tabs_pdf.exists())

            doc = pymupdf.open(str(tabs_pdf))
            try:
                self.assertEqual(len(doc), 50)
                for page in doc:
                    self.assertAlmostEqual(page.rect.width, 459.0, delta=1.0)
                    self.assertAlmostEqual(page.rect.height, 648.0, delta=1.0)
                for pnum, (_, monogram) in TAB_SPECS.items():
                    self.assertIn(monogram, doc[pnum - 1].get_text())
            finally:
                doc.close()

            tabs_bleed_pdf = Path(tmp_dir) / "tabs_bleed_test.pdf"
            build_print_pdf(tabs_bleed_pdf, tabs=True, bleed=True)
            self.assertTrue(tabs_bleed_pdf.exists())

            doc_bleed = pymupdf.open(str(tabs_bleed_pdf))
            try:
                self.assertEqual(len(doc_bleed), 50)
                for page in doc_bleed:
                    self.assertAlmostEqual(page.rect.width, 477.0, delta=1.0)
                    self.assertAlmostEqual(page.rect.height, 666.0, delta=1.0)
                    trim = page.trimbox
                    self.assertAlmostEqual(trim.x0, 9.0, delta=1.0)
                    self.assertAlmostEqual(trim.y0, 9.0, delta=1.0)
                    self.assertAlmostEqual(trim.x1, 468.0, delta=1.0)
                    self.assertAlmostEqual(trim.y1, 657.0, delta=1.0)
                    bleed = page.bleedbox
                    self.assertAlmostEqual(bleed.x0, 0.0, delta=1.0)
                    self.assertAlmostEqual(bleed.y0, 0.0, delta=1.0)
                    self.assertAlmostEqual(bleed.x1, 477.0, delta=1.0)
                    self.assertAlmostEqual(bleed.y1, 666.0, delta=1.0)
            finally:
                doc_bleed.close()

    def test_vervante_flag_geometry_trimbox_and_monograms(self):
        """Verifies -V / --Vervante mode produces 6.5x9 covers/tabs and 6.0x9 interior pages with bleed and crop marks."""
        from scripts.build_print_pdf import TAB_SPECS, build_print_pdf, is_vervante_wide_page
        with tempfile.TemporaryDirectory() as tmp_dir:
            vervante_pdf = Path(tmp_dir) / "vervante_test.pdf"
            build_print_pdf(vervante_pdf, vervante=True)
            self.assertTrue(vervante_pdf.exists())

            doc_v = pymupdf.open(str(vervante_pdf))
            try:
                self.assertEqual(len(doc_v), 50)
                for idx, page in enumerate(doc_v):
                    pnum = idx + 1
                    expected_trim_w = 468.0 if is_vervante_wide_page(pnum) else 432.0
                    trim = page.trimbox
                    self.assertAlmostEqual(trim.width, expected_trim_w, delta=1.0)
                    self.assertAlmostEqual(trim.height, 648.0, delta=1.0)
                    bleed = page.bleedbox
                    self.assertAlmostEqual(bleed.width, expected_trim_w + 18.0, delta=1.0)
                    self.assertAlmostEqual(bleed.height, 666.0, delta=1.0)
                for pnum, (_, monogram) in TAB_SPECS.items():
                    self.assertIn(monogram, doc_v[pnum - 1].get_text())
            finally:
                doc_v.close()


if __name__ == "__main__":
    unittest.main()
