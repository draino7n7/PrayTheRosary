"""
Configuration, dimensions, color palettes, font registration, and PrintConfig
for the Pray The Rosary automated print PDF generator.

Coordinate System Notes for Non-Python Developers:
--------------------------------------------------
ReportLab (the PDF generation library used by this package) uses the standard
PostScript / PDF coordinate space:
  - Units are "points" (pt), where 72 points = 1 inch (1 pt ≈ 0.3528 mm).
  - The origin (0, 0) is at the BOTTOM-LEFT corner of the page, NOT the top-left.
  - X increases from left to right; Y increases from bottom to top.
  - Because `inch` is imported from `reportlab.lib.units`, `6.0 * inch` evaluates
    to `432.0` points, and `9.0 * inch` evaluates to `648.0` points.
"""

from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, Tuple

from reportlab.lib.colors import HexColor
from reportlab.lib.units import inch
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

# ---------------------------------------------------------------------------
# Repository & Asset Directory Paths
# ---------------------------------------------------------------------------
PACKAGE_DIR: Path = Path(__file__).resolve().parent
SCRIPT_DIR: Path = PACKAGE_DIR.parent
PROJECT_ROOT: Path = SCRIPT_DIR.parent

FONTS_DIR: Path = PROJECT_ROOT / "game" / "assets" / "fonts"
DATA_DIR: Path = PROJECT_ROOT / "game" / "data"
ARTWORK_DIR: Path = PROJECT_ROOT / "assets" / "2D" / "gimp" / "original_downloads"

# Default output locations for each print edition
DEFAULT_OUTPUT_PDF: Path = PROJECT_ROOT / "assets" / "print" / "PrayTheRosary.pdf"
DEFAULT_OFFICE_DEPOT_PDF: Path = PROJECT_ROOT / "assets" / "print" / "PrayTheRosary_OfficeDepot.pdf"
DEFAULT_TABS_PDF: Path = PROJECT_ROOT / "assets" / "print" / "PrayTheRosary_Tabs.pdf"
DEFAULT_TABS_BLEED_PDF: Path = PROJECT_ROOT / "assets" / "print" / "PrayTheRosary_Tabs_Bleed.pdf"
DEFAULT_VERVANTE_PDF: Path = PROJECT_ROOT / "assets" / "print" / "Vervante" / "PrayTheRosary_Vervante.pdf"
DEFAULT_VERVANTE_COVERS_PDF: Path = PROJECT_ROOT / "assets" / "print" / "Vervante" / "PrayTheRosary_Vervante_Covers.pdf"
DEFAULT_VERVANTE_INTERIOR_PDF: Path = PROJECT_ROOT / "assets" / "print" / "Vervante" / "PrayTheRosary_Vervante_Interior.pdf"
DEFAULT_VERVANTE_TABS_PDF: Path = PROJECT_ROOT / "assets" / "print" / "Vervante" / "PrayTheRosary_Vervante_Tabs.pdf"

# ---------------------------------------------------------------------------
# Sacred Illuminated Parchment & Baroque Crimson Color Palettes
# ---------------------------------------------------------------------------
# Interior page palette (Pages 2..49)
COLOR_PARCHMENT: HexColor = HexColor("#FAF6EE")      # Warm archival parchment page background
COLOR_PARCHMENT_BOX: HexColor = HexColor("#EDE3CE")  # Callout box fill (Fruit pill & Scripture box)
COLOR_GOLD: HexColor = HexColor("#B89130")           # Master A 1.5pt border & horizontal rules
COLOR_CRIMSON: HexColor = HexColor("#6B1D21")        # Liturgical headings, rubrics & titles
COLOR_CHARCOAL: HexColor = HexColor("#1E1815")       # Primary body & prayer text
COLOR_UMBER: HexColor = HexColor("#5C4338")          # Subheadings, citations & colophon notes

# Cover & Index Tab palette (Pages 1 & 50, overhang strips on Pages 2 & 49, and 6 tab ears)
BACK_PRIMARY: HexColor = HexColor("#4A1215")         # Deep Baroque crimson cover & tab background
BACK_SECONDARY_BOX: HexColor = HexColor("#2A090B")   # Back cover callout box fill
BACK_GOLD: HexColor = HexColor("#D4AF37")            # Metallic antique gold border, title & tab monogram
BACK_IVORY: HexColor = HexColor("#F7F2E7")           # Warm ivory cover text

# ---------------------------------------------------------------------------
# Page, Tab, Bleed & Sheet Dimensions (in PDF Points: 72 pt = 1.0 inch)
# ---------------------------------------------------------------------------
PAGE_W: float = 6.0 * inch               # 432.0 pt (6.0" standard interior page width)
PAGE_H: float = 9.0 * inch               # 648.0 pt (9.0" standard page height)

TAB_EXT: float = 0.375 * inch            # 27.0 pt (3/8" protruding tab & overhang cover extension)
TAB_PAGE_W: float = PAGE_W + TAB_EXT     # 459.0 pt (6.375" total width in --tabs mode)

VERVANTE_TAB_EXT: float = 0.50 * inch    # 36.0 pt (1/2" protruding tab & cover extension for Vervante)
VERVANTE_CROP_MARGIN: float = 0.375 * inch  # 27.0 pt (0.125" bleed + 0.25" margin for corner crop marks)

BLEED: float = 0.125 * inch              # 9.0 pt (1/8" full-bleed extension on all 4 edges)

LETTER_W: float = 8.5 * inch             # 612.0 pt (8.5" US Letter width for Office Depot mode)
LETTER_H: float = 11.0 * inch            # 792.0 pt (11.0" US Letter height for Office Depot mode)

# ---------------------------------------------------------------------------
# 6-Tab (1/6-Cut) Stepped Index Tab Specification
# ---------------------------------------------------------------------------
# Maps 1-based `page_num` -> `(tab_index, monogram_letter)` where:
#   - `tab_index` (0..5) positions the tab vertically from top (0) to bottom (5)
#     along the 8.0" Master A gold frame height (each tab is 8.0" / 6 = 1.3333" = 96 pt tall).
#   - Both the recto (odd page, front of leaf) and verso (even page, back of leaf)
#     of each physical divider sheet carry the same tab index and upright gold monogram
#     so the front and back of the physical die-cut tab register perfectly.
TAB_SPECS: Dict[int, Tuple[int, str]] = {
    3: (0, "O"), 4: (0, "O"),     # Sheet 2: Opening Prayers (opens to Spread 2: Pages 4-5)
    5: (1, "J"), 6: (1, "J"),     # Sheet 3: Joyful Mysteries (opens to Spread 3: Pages 6-7)
    15: (2, "L"), 16: (2, "L"),   # Sheet 8: Luminous Mysteries (opens to Spread 8: Pages 16-17)
    25: (3, "S"), 26: (3, "S"),   # Sheet 13: Sorrowful Mysteries (opens to Spread 13: Pages 26-27)
    35: (4, "G"), 36: (4, "G"),   # Sheet 18: Glorious Mysteries (opens to Spread 18: Pages 36-37)
    45: (5, "C"), 46: (5, "C"),   # Sheet 23: Closing Prayers (opens to Spread 23: Pages 46-47)
}

# ---------------------------------------------------------------------------
# Vervante Component Page Partitions (1-Based Page Numbers)
# ---------------------------------------------------------------------------
# Disjoint partition of the 50-page book into three uniform-dimension files
# for Vervante die-cut tab printing (4 + 12 + 34 = 50 pages):
#   - Covers (4 pages at 6.5" x 9.0"): Duplex Front Cover leaf (Pages 1-2) and Back Cover leaf (Pages 49-50)
#   - Tabs (12 pages at 6.5" x 9.0"): 6 double-sided 1/6-cut index tab sheets (O, J, L, S, G, C)
#   - Interior (34 pages at 6.0" x 9.0"): 17 standard double-sided interior sheets
VERVANTE_COVER_PAGES: List[int] = [1, 2, 49, 50]
VERVANTE_TAB_PAGES: List[int] = sorted(TAB_SPECS.keys())
VERVANTE_INTERIOR_PAGES: List[int] = [
    p for p in range(1, 51) if p not in VERVANTE_COVER_PAGES and p not in TAB_SPECS
]


def register_fonts(fonts_dir: Optional[Path] = None) -> None:
    """
    Registers upright EB Garamond TrueType fonts (`EBGaramond-Regular` and `EBGaramond-Bold`)
    with ReportLab's global font metrics registry.

    Per project typography rules, zero italic fonts are permitted anywhere in the book.
    Both `italic` and `boldItalic` family mappings are explicitly bound to upright font faces
    so ReportLab can never synthesize or embed an italic glyph even if an XML tag requests one.
    """
    target_dir = fonts_dir or FONTS_DIR
    reg_path = target_dir / "EBGaramond-Regular.ttf"
    bold_path = target_dir / "EBGaramond-Bold.ttf"
    if not reg_path.exists() or not bold_path.exists():
        return

    pdfmetrics.registerFont(TTFont("EBGaramond-Regular", str(reg_path)))
    pdfmetrics.registerFont(TTFont("EBGaramond-Bold", str(bold_path)))
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


# Register upright fonts automatically when the module is imported
register_fonts()


def is_vervante_wide_page(page_num: int) -> bool:
    """
    Returns True for pages that have a 6.5" x 9.0" trim width in Vervante mode:
      - Covers: Pages 1, 2 (Front Cover leaf) and Pages 49, 50 (Back Cover leaf)
      - 6 Index Tab Divider Sheets: 12 pages defined in `TAB_SPECS`
    All other 34 interior pages have a standard 6.0" x 9.0" trim width.
    """
    return page_num in VERVANTE_COVER_PAGES or (page_num in TAB_SPECS)


class _DualFieldFactoryDescriptor:
    """
    Descriptor allowing an attribute name (such as `bleed`, `tabs`, `vervante`, `office_depot`)
    to act as:
      - A boolean field when accessed on a `PrintConfig` instance (`cfg.tabs -> bool`)
      - A factory constructor when called on the `PrintConfig` class (`PrintConfig.tabs() -> PrintConfig`)
    """

    def __init__(self, field_name: str, factory_method_name: str) -> None:
        self.field_name = field_name
        self.factory_method_name = factory_method_name

    def __get__(self, instance: Any, owner: type) -> Any:
        if instance is None:
            return getattr(owner, self.factory_method_name)
        return instance.__dict__.get(self.field_name, False)


@dataclass(frozen=True)
class PrintConfig:
    """
    Immutable configuration value object describing a print PDF build target.

    Replaces legacy module-level mutable flags (`_TABS_MODE`, `_BLEED_MODE`, `_VERVANTE_MODE`)
    so multiple PDF editions can be built sequentially or tested in isolation without
    global state leakage.

    Attributes:
        tabs: Enables 6.375" x 9.0" overhang covers and 6 stepped 1/6-cut index tabs (0.375" extension).
        bleed: Enables 0.125" (9 pt) full bleed around all edges and sets PDF TrimBox / BleedBox.
        vervante: Enables Vervante press-ready mode (6.5" x 9.0" covers/tabs with full-height crimson
                  tab strips, 6.0" x 9.0" standard interior pages, 0.125" bleed, and corner crop marks).
        office_depot: Centers the 6.0" x 9.0" book trim on 8.5" x 11.0" US Letter sheets with crop marks.
    """

    tabs: bool = False
    bleed: bool = False
    vervante: bool = False
    office_depot: bool = False

    # -----------------------------------------------------------------------
    # Factory Constructors for Canonical Print Profiles
    # -----------------------------------------------------------------------
    @classmethod
    def standard(cls) -> "PrintConfig":
        """Standard 6.0" x 9.0" (432 x 648 pt) edition without bleed or index tabs."""
        return cls()

    @classmethod
    def bleed_only(cls) -> "PrintConfig":
        """Standard 6.0" x 9.0" trim with 0.125" bleed (450 x 666 pt canvas)."""
        return cls(bleed=True)

    @classmethod
    def tabs_only(cls) -> "PrintConfig":
        """Tabbed 6.375" x 9.0" (459 x 648 pt) edition with 0.375" overhang covers and 6 index tabs."""
        return cls(tabs=True)

    @classmethod
    def tabs_and_bleed(cls) -> "PrintConfig":
        """Tabbed 6.375" x 9.0" trim with 0.125" bleed (477 x 666 pt canvas)."""
        return cls(tabs=True, bleed=True)

    @classmethod
    def vervante_mode(cls) -> "PrintConfig":
        """Vervante press-ready mixed-width edition (6.5" x 9.0" covers/tabs, 6.0" x 9.0" interior, bleed & crop marks)."""
        return cls(vervante=True)

    @classmethod
    def office_depot_mode(cls) -> "PrintConfig":
        """US Letter (8.5" x 11.0") imposition with centered 6.0" x 9.0" trim, bleed, and corner crop marks."""
        return cls(office_depot=True)

    @classmethod
    def tabs_bleed(cls) -> "PrintConfig":
        """Alias for `tabs_and_bleed()`."""
        return cls.tabs_and_bleed()

    # -----------------------------------------------------------------------
    # Computed Geometric Properties & Helpers
    # -----------------------------------------------------------------------
    @property
    def has_tabs(self) -> bool:
        """True if this configuration renders overhang covers and 1/6-cut index tabs (`tabs` or `vervante`)."""
        return self.tabs or self.vervante

    @property
    def has_bleed(self) -> bool:
        """True if this configuration extends backgrounds into the 0.125" bleed zone."""
        return self.bleed or self.vervante or self.office_depot

    @property
    def active_tab_ext(self) -> float:
        """
        Width in points of the protruding fore-edge tab / cover overhang extension:
          - 36.0 pt (0.50") in Vervante mode
          - 27.0 pt (0.375") in standard `--tabs` mode
          - 0.0 pt when tabs are disabled
        """
        if self.vervante:
            return VERVANTE_TAB_EXT
        if self.tabs:
            return TAB_EXT
        return 0.0

    def is_vervante_wide_page(self, page_num: int) -> bool:
        """Returns True if `page_num` is a cover (1, 2, 49, 50) or tab sheet (in `TAB_SPECS`)."""
        return is_vervante_wide_page(page_num)

    def effective_page_width(self, page_num: int = 1) -> float:
        """
        Returns the trimmed page width in points for `page_num`:
          - Vervante mode: 468.0 pt (6.5") for covers/tab sheets; 432.0 pt (6.0") for interior pages
          - Tabs mode: 459.0 pt (6.375") for all pages
          - Standard / Bleed / Office Depot: 432.0 pt (6.0") for all pages
        """
        if self.vervante:
            return (PAGE_W + VERVANTE_TAB_EXT) if is_vervante_wide_page(page_num) else PAGE_W
        if self.tabs:
            return TAB_PAGE_W
        return PAGE_W

    @property
    def effective_width(self) -> float:
        """Trimmed page width in points for Page 1 (front cover)."""
        return self.effective_page_width(1)

    def total_canvas_width(self, page_num: int = 1) -> float:
        """
        Returns the full ReportLab canvas (MediaBox) width in points for `page_num`,
        including bleed or crop mark margins when applicable.
        """
        eff_w = self.effective_page_width(page_num)
        if self.vervante:
            return eff_w + 2 * VERVANTE_CROP_MARGIN
        if self.office_depot:
            return LETTER_W
        if self.bleed:
            return eff_w + 2 * BLEED
        return eff_w

    @property
    def total_width(self) -> float:
        """Full ReportLab canvas (MediaBox) width in points for Page 1."""
        return self.total_canvas_width(1)

    def total_canvas_height(self) -> float:
        """
        Returns the full ReportLab canvas (MediaBox) height in points,
        including bleed or crop mark margins when applicable.
        """
        if self.vervante:
            return PAGE_H + 2 * VERVANTE_CROP_MARGIN
        if self.office_depot:
            return LETTER_H
        if self.bleed:
            return PAGE_H + 2 * BLEED
        return PAGE_H

    @property
    def total_height(self) -> float:
        """Full ReportLab canvas (MediaBox) height in points."""
        return self.total_canvas_height()

    @property
    def mode_label(self) -> str:
        """Human-readable label describing the active print profile for console logging."""
        if self.vervante:
            return "Vervante Press-Ready"
        if self.office_depot:
            return "Office Depot"
        if self.tabs and self.bleed:
            return "Tabs+Bleed"
        if self.tabs:
            return "Tabs 6.375x9"
        if self.bleed:
            return "Bleed"
        return "Standard 6x9"


# Bind dual field/factory descriptors so both `PrintConfig.tabs()` and `cfg.tabs` work seamlessly
PrintConfig.tabs = _DualFieldFactoryDescriptor("tabs", "tabs_only")  # type: ignore[assignment]
PrintConfig.bleed = _DualFieldFactoryDescriptor("bleed", "bleed_only")  # type: ignore[assignment]
PrintConfig.vervante = _DualFieldFactoryDescriptor("vervante", "vervante_mode")  # type: ignore[assignment]
PrintConfig.office_depot = _DualFieldFactoryDescriptor("office_depot", "office_depot_mode")  # type: ignore[assignment]
