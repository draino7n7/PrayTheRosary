"""
Generator for the Vervante Print & Bindery Assembly Guide PDF
(`assets/print/Vervante/README_Print_and_Assembly_Guide.pdf`).

Produces a 2-page 8.5" x 11" US Letter job ticket and collation guide for
Vervante prepress and bindery staff:
  - Page 1: Job Header Banner, Overview of the 4 PDF Files in the Package,
            Quick Bindery Collation Summary (0 - 4 - 4 - 4 - 4 - 1 interior
            sheet rhythm), and Prepress & Die-Cut Tab Specifications.
  - Page 2: Complete 25-Sheet Bindery Collation & Verification Table fitting
            all 25 physical sheets (Sheet 01 to Sheet 25) onto a single page
            with color-coded rows for Overhang Covers and 6 Die-Cut Index Tabs.

Contains strictly print-shop and bindery assembly instructions (zero software,
Python script, or repository references).
"""

from pathlib import Path
from typing import Optional

from reportlab.lib import colors
from reportlab.lib.colors import HexColor
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import (
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

PACKAGE_DIR: Path = Path(__file__).resolve().parent
SCRIPT_DIR: Path = PACKAGE_DIR.parent
PROJECT_ROOT: Path = SCRIPT_DIR.parent

DEFAULT_VERVANTE_GUIDE_PDF: Path = (
    PROJECT_ROOT / "assets" / "print" / "Vervante" / "README_Print_and_Assembly_Guide.pdf"
)

CRIMSON: HexColor = HexColor("#4A1215")
CRIMSON_LIGHT: HexColor = HexColor("#F6ECEC")
COVER_LIGHT: HexColor = HexColor("#EFE6D5")
GOLD_BORDER: HexColor = HexColor("#B89130")
CHARCOAL: HexColor = HexColor("#1E1815")
ROW_ALT: HexColor = HexColor("#FAF8F5")
WHITE = colors.white


def build_vervante_assembly_guide(output_path: Optional[Path] = None) -> Path:
    """
    Generates the 2-page 8.5" x 11" US Letter Vervante Print & Bindery Assembly Guide PDF.

    Args:
        output_path: Target path for the generated guide PDF. Defaults to
                     `assets/print/Vervante/README_Print_and_Assembly_Guide.pdf`.

    Returns:
        Resolved `Path` to the generated PDF.
    """
    out_pdf = Path(output_path) if output_path is not None else DEFAULT_VERVANTE_GUIDE_PDF
    out_pdf.parent.mkdir(parents=True, exist_ok=True)

    doc = SimpleDocTemplate(
        str(out_pdf),
        pagesize=letter,
        leftMargin=0.45 * inch,
        rightMargin=0.45 * inch,
        topMargin=0.36 * inch,
        bottomMargin=0.36 * inch,
        title="Pray the Rosary - Print & Bindery Assembly Guide",
        author="Kevin Audrain",
    )

    st_banner_title = ParagraphStyle(
        "BannerTitle",
        fontName="Helvetica-Bold",
        fontSize=13.5,
        leading=16.5,
        textColor=WHITE,
        alignment=TA_LEFT,
    )
    st_banner_sub = ParagraphStyle(
        "BannerSub",
        fontName="Helvetica",
        fontSize=9.0,
        leading=12.2,
        textColor=HexColor("#F7F2E7"),
        alignment=TA_LEFT,
    )
    st_h2 = ParagraphStyle(
        "SectionH2",
        fontName="Helvetica-Bold",
        fontSize=10.5,
        leading=13.0,
        textColor=CRIMSON,
        spaceBefore=6,
        spaceAfter=3,
    )
    st_body = ParagraphStyle(
        "Body",
        fontName="Helvetica",
        fontSize=8.6,
        leading=11.6,
        textColor=CHARCOAL,
    )
    st_bullet = ParagraphStyle(
        "Bullet",
        fontName="Helvetica",
        fontSize=8.5,
        leading=11.5,
        leftIndent=10,
        textColor=CHARCOAL,
        spaceBefore=1.5,
        spaceAfter=1.5,
    )
    st_th = ParagraphStyle(
        "TableHead",
        fontName="Helvetica-Bold",
        fontSize=8.0,
        leading=9.8,
        textColor=WHITE,
        alignment=TA_LEFT,
    )
    st_th_c = ParagraphStyle(
        "TableHeadCenter",
        fontName="Helvetica-Bold",
        fontSize=8.0,
        leading=9.8,
        textColor=WHITE,
        alignment=TA_CENTER,
    )
    st_td = ParagraphStyle(
        "TableCell",
        fontName="Helvetica",
        fontSize=7.8,
        leading=10.0,
        textColor=CHARCOAL,
        alignment=TA_LEFT,
    )
    st_td_c = ParagraphStyle(
        "TableCellCenter",
        fontName="Helvetica-Bold",
        fontSize=7.8,
        leading=10.0,
        textColor=CHARCOAL,
        alignment=TA_CENTER,
    )

    story = []

    # =========================================================================
    # PAGE 1: OVERVIEW OF FILES, COLLATION RHYTHM & PREPRESS SPECS
    # =========================================================================
    banner_data = [
        [Paragraph("PRINT &amp; BINDERY ASSEMBLY GUIDE", st_banner_title)],
        [
            Paragraph(
                "<b>Book Title:</b> Pray the Rosary: A Contemplative Visual Guide to the Twenty Mysteries<br/>"
                "<b>Total Book Length:</b> 50 Pages (25 Double-Sided Sheets)  |  "
                "<b>Binding:</b> Black Twin-Loop Wire-O on 9.0\" Left Spine<br/>"
                "<b>Finished Trim Sizes:</b> 6.5\" x 9.0\" (Overhang Covers &amp; 6 Die-Cut Index Tab Sheets) "
                "and 6.0\" x 9.0\" (17 Standard Interior Sheets)",
                st_banner_sub,
            )
        ],
    ]
    banner_table = Table(banner_data, colWidths=[7.6 * inch])
    banner_table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, -1), CRIMSON),
                ("TOPPADDING", (0, 0), (-1, 0), 8),
                ("BOTTOMPADDING", (0, 0), (-1, 0), 2),
                ("TOPPADDING", (0, 1), (-1, 1), 2),
                ("BOTTOMPADDING", (0, 1), (-1, 1), 8),
                ("LEFTPADDING", (0, 0), (-1, -1), 10),
                ("RIGHTPADDING", (0, 0), (-1, -1), 10),
                ("BOX", (0, 0), (-1, -1), 1.2, GOLD_BORDER),
            ]
        )
    )
    story.append(banner_table)
    story.append(Spacer(1, 5))

    # --- Section 1: Overview of the 4 PDF Files ---
    story.append(Paragraph("1. Overview of the 4 PDF Files in This Package", st_h2))
    story.append(
        Paragraph(
            "This package contains <b>3 separated production print PDFs</b> (grouped by trim size and paper stock for press imposition) "
            "plus <b>1 combined 50-page Master Collation Reference PDF</b> showing the complete book in reading and binding order:",
            st_body,
        )
    )
    story.append(Spacer(1, 4))

    files_rows = [
        [
            Paragraph("PDF File Name", st_th),
            Paragraph("Production Role", st_th),
            Paragraph("Pages (Sheets)", st_th_c),
            Paragraph("Trim Size (w/ Bleed &amp; Crops)", st_th_c),
            Paragraph("Stock &amp; Finishing Notes", st_th),
        ],
        [
            Paragraph("<b>PrayTheRosary_Vervante_Covers.pdf</b>", st_td),
            Paragraph("<b>PRINT FILE 1:</b><br/>Front &amp; Back Overhang Covers", st_td),
            Paragraph("4 pages<br/>(2 sheets)", st_td_c),
            Paragraph("<b>6.5\" x 9.0\"</b><br/>(7.25\" x 9.75\" canvas)", st_td_c),
            Paragraph(
                "18pt heavy cover stock, full color both sides (0.125\" bleed + crop marks). "
                "Extends 0.50\" on right fore-edge to protect the 6 index tabs.",
                st_td,
            ),
        ],
        [
            Paragraph("<b>PrayTheRosary_Vervante_Tabs.pdf</b>", st_td),
            Paragraph("<b>PRINT FILE 2:</b><br/>6 Stepped 1/6-Cut Die-Cut Tabs", st_td),
            Paragraph("12 pages<br/>(6 sheets)", st_td_c),
            Paragraph("<b>6.5\" x 9.0\"</b><br/>(7.25\" x 9.75\" canvas)", st_td_c),
            Paragraph(
                "6 double-sided 1/6-cut tab sheets (O, J, L, S, G, C from top to bottom). "
                "0.50\" tab extension has a full-length crimson background strip for clean die-cutting.",
                st_td,
            ),
        ],
        [
            Paragraph("<b>PrayTheRosary_Vervante_Interior.pdf</b>", st_td),
            Paragraph("<b>PRINT FILE 3:</b><br/>Standard Interior Pages", st_td),
            Paragraph("34 pages<br/>(17 sheets)", st_td_c),
            Paragraph("<b>6.0\" x 9.0\"</b><br/>(6.75\" x 9.75\" canvas)", st_td_c),
            Paragraph(
                "100# text stock, premium full color both sides (0.125\" bleed + crop marks). "
                "Trimmed flush at 6.0\" x 9.0\".",
                st_td,
            ),
        ],
        [
            Paragraph("<b>PrayTheRosary_Vervante.pdf</b>", st_td),
            Paragraph("<b>REFERENCE ONLY:</b><br/>Master Collation Guide (Do Not Print)", st_td),
            Paragraph("50 pages<br/>(25 sheets)", st_td_c),
            Paragraph("Mixed<br/>(6.5\" &amp; 6.0\" x 9.0\")", st_td_c),
            Paragraph(
                "Complete 50-page book in exact reading and binding order (Pages 1 to 50). "
                "Use for visual spread verification during bindery collation.",
                st_td,
            ),
        ],
    ]
    files_table = Table(
        files_rows,
        colWidths=[2.24 * inch, 1.40 * inch, 0.78 * inch, 1.13 * inch, 2.05 * inch],
    )
    files_table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), CRIMSON),
                ("BACKGROUND", (0, 1), (-1, 1), COVER_LIGHT),
                ("BACKGROUND", (0, 2), (-1, 2), CRIMSON_LIGHT),
                ("BACKGROUND", (0, 3), (-1, 3), WHITE),
                ("BACKGROUND", (0, 4), (-1, 4), ROW_ALT),
                ("GRID", (0, 0), (-1, -1), 0.5, HexColor("#C8BFA8")),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("TOPPADDING", (0, 0), (-1, -1), 4),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
                ("LEFTPADDING", (0, 0), (-1, -1), 5),
                ("RIGHTPADDING", (0, 0), (-1, -1), 5),
            ]
        )
    )
    story.append(files_table)
    story.append(Spacer(1, 5))

    # --- Section 2: Quick Bindery Collation Rule ---
    story.append(
        Paragraph("2. Quick Bindery Collation Summary (0 - 4 - 4 - 4 - 4 - 1 Interior Sheet Rhythm)", st_h2)
    )
    story.append(
        Paragraph(
            "Because the pages do not have printed page numbers at the bottom, every sheet is identified by its "
            "<b>printed top heading</b> (see the full 25-sheet table on Page 2) and can be visually checked against "
            "<b>PrayTheRosary_Vervante.pdf</b>. When collating the 6 die-cut tab sheets with the 17 standard interior sheets "
            "between the Front and Back Covers, the interior sheets follow a simple <b>0 - 4 - 4 - 4 - 4 - 1</b> rhythm:",
            st_body,
        )
    )
    story.append(Spacer(1, 4))

    rhythm_lines = (
        "1. <b>Sheet 01 (Front Cover):</b> Covers PDF, Sheet 1 (pp. 1-2)<br/>"
        "2. <b>Sheet 02 (Tab 1 - 'O', Top 1/6):</b> Tabs PDF, Sheet 1 (pp. 1-2)<br/>"
        "3. <b>Sheet 03 (Tab 2 - 'J', 2nd 1/6):</b> Tabs PDF, Sheet 2 (pp. 3-4)  "
        "<i>(Note: Tab O and Tab J sit back-to-back with <b>0 interior sheets</b> between them.)</i><br/>"
        "    + <b>Sheets 04 to 07 (4 Interior Sheets):</b> Interior PDF, Sheets 1-4 (pp. 1-8: Joyful Mysteries)<br/>"
        "4. <b>Sheet 08 (Tab 3 - 'L', 3rd 1/6):</b> Tabs PDF, Sheet 3 (pp. 5-6)<br/>"
        "    + <b>Sheets 09 to 12 (4 Interior Sheets):</b> Interior PDF, Sheets 5-8 (pp. 9-16: Luminous Mysteries)<br/>"
        "5. <b>Sheet 13 (Tab 4 - 'S', 4th 1/6):</b> Tabs PDF, Sheet 4 (pp. 7-8)<br/>"
        "    + <b>Sheets 14 to 17 (4 Interior Sheets):</b> Interior PDF, Sheets 9-12 (pp. 17-24: Sorrowful Mysteries)<br/>"
        "6. <b>Sheet 18 (Tab 5 - 'G', 5th 1/6):</b> Tabs PDF, Sheet 5 (pp. 9-10)<br/>"
        "    + <b>Sheets 19 to 22 (4 Interior Sheets):</b> Interior PDF, Sheets 13-16 (pp. 25-32: Glorious Mysteries)<br/>"
        "7. <b>Sheet 23 (Tab 6 - 'C', Bottom 1/6):</b> Tabs PDF, Sheet 6 (pp. 11-12)<br/>"
        "    + <b>Sheet 24 (1 Interior Sheet):</b> Interior PDF, Sheet 17 (pp. 33-34: Closing Prayers Artwork &amp; Credits Part I)<br/>"
        "8. <b>Sheet 25 (Back Cover):</b> Covers PDF, Sheet 2 (pp. 3-4)"
    )
    rhythm_box = Table([[Paragraph(rhythm_lines, st_body)]], colWidths=[7.6 * inch])
    rhythm_box.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, -1), COVER_LIGHT),
                ("BOX", (0, 0), (-1, -1), 0.9, GOLD_BORDER),
                ("TOPPADDING", (0, 0), (-1, -1), 6),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
                ("LEFTPADDING", (0, 0), (-1, -1), 8),
                ("RIGHTPADDING", (0, 0), (-1, -1), 8),
            ]
        )
    )
    story.append(rhythm_box)
    story.append(Spacer(1, 5))

    # --- Section 3: Prepress & Die-Cut Tab Geometry Details ---
    story.append(Paragraph("3. Prepress &amp; Die-Cut Tab Specifications", st_h2))
    story.append(
        Paragraph(
            "&bull; <b>Bleed &amp; Corner Crop Marks:</b> Every page across all 4 PDFs includes <b>0.125\" (1/8\") full bleed</b> on all four sides "
            "plus outer corner crop marks aligned to the exact trim corners (6.5\" x 9.0\" for Covers and Tabs; 6.0\" x 9.0\" for Interior). "
            "PDF TrimBox and BleedBox metadata are embedded on every page.",
            st_bullet,
        )
    )
    story.append(
        Paragraph(
            "&bull; <b>Full-Length Crimson Tab Extension Strip (PrayTheRosary_Vervante_Tabs.pdf):</b> On all 12 tab pages (6 duplex sheets), "
            "the 0.50\" outer tab extension strip is filled with the Deep Baroque Crimson (#4A1215) background along the entire 9.0\" length of the sheet "
            "(plus top, bottom, and outer bleed) so mechanical tab cutting produces solid crimson tab edges with zero white paper showing on the shoulders.",
            st_bullet,
        )
    )
    story.append(
        Paragraph(
            "&bull; <b>6-Tab (1/6-Cut) Stepped Bank Positions (8.0\" Active Vertical Bank from 0.50\" Top Margin to 0.50\" Bottom Margin):</b><br/>"
            "&nbsp;&nbsp;&nbsp;&nbsp;1. <b>Tab 1 ('O' - Opening, Sheet 02):</b> Top 1/6 (7.167\"-8.500\")  |  "
            "2. <b>Tab 2 ('J' - Joyful, Sheet 03):</b> 2nd 1/6 (5.833\"-7.167\")<br/>"
            "&nbsp;&nbsp;&nbsp;&nbsp;3. <b>Tab 3 ('L' - Luminous, Sheet 08):</b> 3rd 1/6 (4.500\"-5.833\")  |  "
            "4. <b>Tab 4 ('S' - Sorrowful, Sheet 13):</b> 4th 1/6 (3.167\"-4.500\")<br/>"
            "&nbsp;&nbsp;&nbsp;&nbsp;5. <b>Tab 5 ('G' - Glorious, Sheet 18):</b> 5th 1/6 (1.833\"-3.167\")  |  "
            "6. <b>Tab 6 ('C' - Closing, Sheet 23):</b> Bottom 1/6 (0.500\"-1.833\")",
            st_bullet,
        )
    )

    # =========================================================================
    # PAGE 2: COMPLETE 25-SHEET COLLATION TABLE (ALL 25 SHEETS ON ONE PAGE)
    # =========================================================================
    story.append(PageBreak())
    story.append(Paragraph("4. Complete 25-Sheet Bindery Collation &amp; Verification Table (Sheets 01 to 25)", st_h2))
    story.append(
        Paragraph(
            "Each row below represents <b>one physical double-sided sheet</b> in final binding order from front to back "
            "(shaded rows highlight the <b>6.5\" x 9.0\" Overhang Covers and 6 Die-Cut Index Tab Sheets</b>):",
            st_body,
        )
    )
    story.append(Spacer(1, 4))

    raw_sheets = [
        ("Sheet 01", "pp. 1 - 2", "Covers PDF (pp. 1-2)", "6.5\" x 9.0\" (Front Cover)", "PRAY THE ROSARY (Murillo Front Cover Painting)", "The History of the Holy Rosary (0.50\" left crimson overhang)", "cover"),
        ("Sheet 02", "pp. 3 - 4", "Tabs PDF (pp. 1-2)", "6.5\" x 9.0\" [Tab 1: O - Top 1/6]", "Structure of This Book & How to Pray (Tab O on right)", "The Opening Prayers: Sign of the Cross to Glory Be (Tab O on left)", "tab"),
        ("Sheet 03", "pp. 5 - 6", "Tabs PDF (pp. 3-4)", "6.5\" x 9.0\" [Tab 2: J - 2nd 1/6]", "The Opening Prayers (Holy Trinity Painting; Tab J on right)", "The First Joyful Mystery: The Annunciation (Prayers; Tab J on left)", "tab"),
        ("Sheet 04", "pp. 7 - 8", "Interior PDF (pp. 1-2)", "6.0\" x 9.0\" (Interior Sheet 01)", "The First Joyful Mystery: The Annunciation (Painting)", "The Second Joyful Mystery: The Visitation (Prayers)", "int"),
        ("Sheet 05", "pp. 9 - 10", "Interior PDF (pp. 3-4)", "6.0\" x 9.0\" (Interior Sheet 02)", "The Second Joyful Mystery: The Visitation (Painting)", "The Third Joyful Mystery: The Nativity of Our Lord (Prayers)", "int"),
        ("Sheet 06", "pp. 11 - 12", "Interior PDF (pp. 5-6)", "6.0\" x 9.0\" (Interior Sheet 03)", "The Third Joyful Mystery: The Nativity of Our Lord (Painting)", "The Fourth Joyful Mystery: The Presentation in the Temple (Prayers)", "int"),
        ("Sheet 07", "pp. 13 - 14", "Interior PDF (pp. 7-8)", "6.0\" x 9.0\" (Interior Sheet 04)", "The Fourth Joyful Mystery: The Presentation in the Temple (Painting)", "The Fifth Joyful Mystery: The Finding in the Temple (Prayers)", "int"),
        ("Sheet 08", "pp. 15 - 16", "Tabs PDF (pp. 5-6)", "6.5\" x 9.0\" [Tab 3: L - 3rd 1/6]", "The Fifth Joyful Mystery: The Finding in the Temple (Painting; Tab L)", "The First Luminous Mystery: The Baptism of Jesus (Prayers; Tab L)", "tab"),
        ("Sheet 09", "pp. 17 - 18", "Interior PDF (pp. 9-10)", "6.0\" x 9.0\" (Interior Sheet 05)", "The First Luminous Mystery: The Baptism of Jesus (Painting)", "The Second Luminous Mystery: The Wedding at Cana (Prayers)", "int"),
        ("Sheet 10", "pp. 19 - 20", "Interior PDF (pp. 11-12)", "6.0\" x 9.0\" (Interior Sheet 06)", "The Second Luminous Mystery: The Wedding at Cana (Painting)", "The Third Luminous Mystery: Proclamation of the Kingdom (Prayers)", "int"),
        ("Sheet 11", "pp. 21 - 22", "Interior PDF (pp. 13-14)", "6.0\" x 9.0\" (Interior Sheet 07)", "The Third Luminous Mystery: Proclamation of the Kingdom (Painting)", "The Fourth Luminous Mystery: The Transfiguration (Prayers)", "int"),
        ("Sheet 12", "pp. 23 - 24", "Interior PDF (pp. 15-16)", "6.0\" x 9.0\" (Interior Sheet 08)", "The Fourth Luminous Mystery: The Transfiguration (Painting)", "The Fifth Luminous Mystery: Institution of the Eucharist (Prayers)", "int"),
        ("Sheet 13", "pp. 25 - 26", "Tabs PDF (pp. 7-8)", "6.5\" x 9.0\" [Tab 4: S - 4th 1/6]", "The Fifth Luminous Mystery: Institution of the Eucharist (Painting; Tab S)", "The First Sorrowful Mystery: The Agony in the Garden (Prayers; Tab S)", "tab"),
        ("Sheet 14", "pp. 27 - 28", "Interior PDF (pp. 17-18)", "6.0\" x 9.0\" (Interior Sheet 09)", "The First Sorrowful Mystery: The Agony in the Garden (Painting)", "The Second Sorrowful Mystery: The Scourging at the Pillar (Prayers)", "int"),
        ("Sheet 15", "pp. 29 - 30", "Interior PDF (pp. 19-20)", "6.0\" x 9.0\" (Interior Sheet 10)", "The Second Sorrowful Mystery: The Scourging at the Pillar (Painting)", "The Third Sorrowful Mystery: The Crowning with Thorns (Prayers)", "int"),
        ("Sheet 16", "pp. 31 - 32", "Interior PDF (pp. 21-22)", "6.0\" x 9.0\" (Interior Sheet 11)", "The Third Sorrowful Mystery: The Crowning with Thorns (Painting)", "The Fourth Sorrowful Mystery: The Carrying of the Cross (Prayers)", "int"),
        ("Sheet 17", "pp. 33 - 34", "Interior PDF (pp. 23-24)", "6.0\" x 9.0\" (Interior Sheet 12)", "The Fourth Sorrowful Mystery: The Carrying of the Cross (Painting)", "The Fifth Sorrowful Mystery: The Crucifixion and Death (Prayers)", "int"),
        ("Sheet 18", "pp. 35 - 36", "Tabs PDF (pp. 9-10)", "6.5\" x 9.0\" [Tab 5: G - 5th 1/6]", "The Fifth Sorrowful Mystery: The Crucifixion and Death (Painting; Tab G)", "The First Glorious Mystery: The Resurrection of Our Lord (Prayers; Tab G)", "tab"),
        ("Sheet 19", "pp. 37 - 38", "Interior PDF (pp. 25-26)", "6.0\" x 9.0\" (Interior Sheet 13)", "The First Glorious Mystery: The Resurrection of Our Lord (Painting)", "The Second Glorious Mystery: The Ascension of Our Lord (Prayers)", "int"),
        ("Sheet 20", "pp. 39 - 40", "Interior PDF (pp. 27-28)", "6.0\" x 9.0\" (Interior Sheet 14)", "The Second Glorious Mystery: The Ascension of Our Lord (Painting)", "The Third Glorious Mystery: The Descent of the Holy Spirit (Prayers)", "int"),
        ("Sheet 21", "pp. 41 - 42", "Interior PDF (pp. 29-30)", "6.0\" x 9.0\" (Interior Sheet 15)", "The Third Glorious Mystery: The Descent of the Holy Spirit (Painting)", "The Fourth Glorious Mystery: The Assumption of Mary (Prayers)", "int"),
        ("Sheet 22", "pp. 43 - 44", "Interior PDF (pp. 31-32)", "6.0\" x 9.0\" (Interior Sheet 16)", "The Fourth Glorious Mystery: The Assumption of Mary (Painting)", "The Fifth Glorious Mystery: The Coronation of Mary (Prayers)", "int"),
        ("Sheet 23", "pp. 45 - 46", "Tabs PDF (pp. 11-12)", "6.5\" x 9.0\" [Tab 6: C - Bottom 1/6]", "The Fifth Glorious Mystery: The Coronation of Mary (Painting; Tab C)", "The Closing Prayers: Hail, Holy Queen & Concluding Prayer (Tab C)", "tab"),
        ("Sheet 24", "pp. 47 - 48", "Interior PDF (pp. 33-34)", "6.0\" x 9.0\" (Interior Sheet 17)", "The Closing Prayers (Murillo Immaculate Conception Painting)", "Sacred Artwork Credits (Part I: Front Cover to Luminous Mysteries)", "int"),
        ("Sheet 25", "pp. 49 - 50", "Covers PDF (pp. 3-4)", "6.5\" x 9.0\" (Back Cover)", "Sacred Artwork Credits (Part II) & Colophon (0.50\" right crimson overhang)", "PRAY THE ROSARY (Outside Back Cover with Papal & Marian Quotes)", "cover"),
    ]

    st_cell_sm = ParagraphStyle("CellSm", fontName="Helvetica", fontSize=7.0, leading=8.4, textColor=CHARCOAL)
    st_cell_sm_b = ParagraphStyle("CellSmB", fontName="Helvetica-Bold", fontSize=7.0, leading=8.4, textColor=CHARCOAL)
    st_cell_sm_c = ParagraphStyle("CellSmC", fontName="Helvetica-Bold", fontSize=7.0, leading=8.4, textColor=CHARCOAL, alignment=TA_CENTER)

    sheet_rows = [
        [
            Paragraph("Sheet #", st_th_c),
            Paragraph("Master Pages", st_th_c),
            Paragraph("Source Print PDF", st_th),
            Paragraph("Trim Size &amp; Tab Cut", st_th),
            Paragraph("Front of Sheet (Recto / Odd) Heading", st_th),
            Paragraph("Back of Sheet (Verso / Even) Heading", st_th),
        ]
    ]

    t_styles = [
        ("BACKGROUND", (0, 0), (-1, 0), CRIMSON),
        ("GRID", (0, 0), (-1, -1), 0.4, HexColor("#C8BFA8")),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("TOPPADDING", (0, 0), (-1, -1), 1.6),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 1.6),
        ("LEFTPADDING", (0, 0), (-1, -1), 4),
        ("RIGHTPADDING", (0, 0), (-1, -1), 4),
    ]

    for idx, (sh, mp, src, trm, fr, bk, kind) in enumerate(raw_sheets, start=1):
        is_special = kind in ("cover", "tab")
        st_use = st_cell_sm_b if is_special else st_cell_sm
        sheet_rows.append(
            [
                Paragraph(sh, st_cell_sm_c),
                Paragraph(mp, st_cell_sm_c),
                Paragraph(src, st_use),
                Paragraph(trm, st_use),
                Paragraph(fr, st_use),
                Paragraph(bk, st_use),
            ]
        )
        if kind == "cover":
            t_styles.append(("BACKGROUND", (0, idx), (-1, idx), COVER_LIGHT))
        elif kind == "tab":
            t_styles.append(("BACKGROUND", (0, idx), (-1, idx), CRIMSON_LIGHT))
        elif idx % 2 == 0:
            t_styles.append(("BACKGROUND", (0, idx), (-1, idx), ROW_ALT))

    sheets_table = Table(
        sheet_rows,
        colWidths=[0.58 * inch, 0.68 * inch, 1.15 * inch, 1.35 * inch, 1.92 * inch, 1.92 * inch],
        repeatRows=1,
    )
    sheets_table.setStyle(TableStyle(t_styles))
    story.append(sheets_table)

    doc.build(story)
    return out_pdf


if __name__ == "__main__":
    generated_path = build_vervante_assembly_guide()
    size_kb = generated_path.stat().st_size / 1024.0
    print(f"Generated (Vervante Assembly Guide): {generated_path} (2 pages, {size_kb:.1f} KB)")
