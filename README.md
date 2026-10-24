# Pray The Rosary

An interactive prayer companion and visual contemplation guide for the Holy Rosary, built with **Godot 4.7.2** for the **OpenGameStack (OGS)** ecosystem and designed as the digital foundation for a high-quality printed prayer book.

## About the Project

*Pray The Rosary* bridges digital devotions with classical fine art and traditional book design. Designed around a two-page spread concept mirroring a 6" x 9" spiral-bound prayer book:
- **Left Page / Side:** Clear, distraction-free prayers for each decade (Apostles' Creed, Our Father, Hail Marys, Glory Be, Fatima Prayer), alongside verbatim public-domain [Catholic Public Domain Version (CPDV)](https://www.sacredbible.org/) ([GitHub](https://github.com/draino7n7/cpdv)) scriptural passages and meditative reflections. Everything needed to pray the decade is presented on a single screen without cumbersome scrolling.
- **Right Page / Side:** Large, contemplative public-domain Sacred Art masterpieces (from renowned institutions like the Museo del Prado, National Gallery of Art, Kunsthistorisches Museum, and State Hermitage Museum) corresponding to each mystery.
- **Structured Content Architecture:** All mysteries, prayers, Catholic Public Domain Version (CPDV) scripture verses, and authoritative museum catalog attributions (`inventory_number`, `original_dimensions`, `creation_date`, and `current_location` across all 23 masterworks) are organized as structured data (`game/data/mysteries.json`, `game/data/book_layout.json`, and `assets/2D/gimp/attributions.json`), serving as the single source of truth for both the interactive application and printed book layout exports.
- **Canonical Source Verification Ledger ([`documents/references.md`](documents/references.md)):** Authoritative, comprehensive primary source guide and verification ledger cataloging all 50 physical pages in strict book order, 12 canonical prayers (with liturgical and Catechism sources), 20 mysteries and spiritual fruits, public-domain Catholic Public Domain Version (CPDV) Scripture citations with primary source links to [SacredBible.org](https://www.sacredbible.org/) and [GitHub draino7n7/cpdv](https://github.com/draino7n7/cpdv) (alongside comparative [drbo.org](https://www.drbo.org) chapter links), and 23 fine art masterpieces with museum inventory numbers and collection catalog links. Governed by AI agent verification rules in [`.agents/rules/references_verification.md`](.agents/rules/references_verification.md).

### The Four Mysteries
1. **The Joyful Mysteries** (The Annunciation, The Visitation, The Nativity, The Presentation, The Finding in the Temple)
2. **The Luminous Mysteries** (The Baptism in the Jordan, The Wedding at Cana, The Proclamation of the Kingdom, The Transfiguration, The Institution of the Eucharist)
3. **The Sorrowful Mysteries** (The Agony in the Garden, The Scourging at the Pillar, The Crowning with Thorns, The Carrying of the Cross, The Crucifixion)
4. **The Glorious Mysteries** (The Resurrection, The Ascension, The Descent of the Holy Spirit, The Assumption of Mary, The Coronation of Mary)

---

- **Classical Typography & Symbol Fallbacks (`game/assets/fonts/`):**
  - **EB Garamond** (SIL Open Font License 1.1) provides elegant Renaissance serif typography for all Latin text, prayers, scriptures, and headings, standardizing on crisp, upright regular (`EB Garamond Regular`) and bold (`EB Garamond Bold`) typography across all 50 pages for maximum legibility and reading comfort across all screen sizes (with italic styles retained in asset bundles and theme fallbacks).
  - **Noto Sans Symbols** (`NotoSansSymbols-Regular.ttf`, SIL Open Font License 1.1) is bundled as a cross-platform fallback font for sandboxed Web / HTML5 exports, ensuring crisp, tofu-free rendering of Unicode UI glyphs (`☰`, `✕`, `▸`, `▾`, `★`) while 100% preserving EB Garamond's Latin line heights and layout metrics.
- **Runtime Sacred Art Textures (`game/assets/images/`):** Contains 23 optimized runtime `.webp` textures generated from archival public-domain masterpieces in `assets/2D/gimp/original_downloads/` (quality 85, max height 1800px, aspect ratio strictly preserved).
- **Application Theme (`game/resources/rosary_theme.tres`):** Canonical Godot theme configured with an illuminated manuscript palette featuring warm ivory parchment (`#FAF6EE`), Marian crimson headers (`#6B1D21`), deep charcoal text (`#1E1815`), warm umber rubrics (`#5C4338`), and antique gold borders (`#B89130`).
- **App Icon & Sacred Boot Splash (`game/assets/icons/`):** Custom 512×512 square icon cropped from Murillo's *The Virgin of the Rosary* focusing on Mary and the Infant Jesus, matching 432×432 Android adaptive launcher icons (`icon_foreground.png` and `#141010` `icon_background.png`), and full-resolution uncropped cover art boot splash (`boot_splash.png`) against deep ambient espresso (`#141010`).

---

## 2:3 Portrait Page Card Architecture

The UI is built around a modular page card component architecture designed for the continuous 50-page vertical scroll:
- **Unified Root Facade (`game/scenes/ui/page_card.tscn` / `game/scripts/ui/page_card.gd`):** Uses Godot's `AspectRatioContainer` (`ratio = 2.0 / 3.0`) to enforce a clean 2:3 portrait card geometry across mobile, tablet, and desktop display viewports.
- **Standardized Margins & Dynamic Typography:** Card scenes feature uniform 32px margins, enlarged headers (34–38pt headings, 22–24pt subheadings), and dynamic body text auto-fitting. Under larger text presets (`Mobile` and `Extra Large`), text-heavy cards dynamically elongate vertically to prevent clipping or internal scrolling, while sacred art and cover cards strictly preserve their rigid 2:3 ($720\times 1080$) aspect ratio.
- **Specialized Sub-Cards (`game/scenes/ui/pages/`):** Dynamically instantiates the appropriate sub-card component for each page type:
  - `CoverPageCard`: Dedicated top header band with framed Murillo painting below, ensuring text never overlaps the sacred artwork.
  - `FrontMatterPageCard`: History and guide spreads on ivory parchment panels (including the front-matter note citing the Catholic Public Domain Version of the Bible and a step-by-step guide explaining praying either the five decades of the day's Mystery set or all four Mystery sets—twenty decades—in chronological order).
  - `PrayerSequencePageCard`: Opening (Page 4) and closing (Page 46, featuring a 3-step sequence with flowing Versicle & Response beneath the Salve Regina) prayer sequences with rubrics.
  - `MysteryPrayerPageCard`: Decade prayers (*The Our Father*, *The Hail Mary*, *The Glory Be*, *The Fatima Prayer*), fruit badge, clean book/chapter/verse citation, verbatim Catholic Public Domain Version (CPDV) scripture passage, and meditation.
  - `ArtworkPageCard`: Centered, uncropped sacred art painting in an antique gold frame with strictly no captions or page numbers.
  - `CreditsPageCard`: Comprehensive museum catalog artwork attributions listed in exact sequential book appearance order across Pages 48 (12 items) and 49 (11 items + Colophon) with non-numbered section/Mystery placement labels (`section_label — title`).
  - `BackCoverPageCard`: Deep crimson card with Pope St. John Paul II's epigraph, book synopsis, and St. Louis Marie de Montfort's full verbatim Marian counsel from *The Secret of the Rosary*.
- **Data-Driven Hydration:** Cards are hydrated directly from `RosaryDataLoader` via `PageCard.create_for_page(page_data, loader)` or `card.bind_page_data(page_data, loader)`.

---

## Continuous Vertical Scroll View & Navigation

The application connects all 50 sequential pages into a unified, distraction-free reading experience:
- **Continuous 50-Page Stream (`game/scenes/main/main.tscn` / `game/scripts/main/main.gd`):** Presents all pages from Cover to Back Cover in a single vertical `ScrollContainer` with a clean, scrollbar-free layout (`SCROLL_MODE_SHOW_NEVER`) and pass-through mouse filters (`MOUSE_FILTER_PASS` / `MOUSE_FILTER_IGNORE`), supporting smooth touch swipe, left-mouse click-drag, and mouse wheel scrolling with natural momentum and inertia physics (exponential friction decay, flick velocity detection, stream boundary clamping, and tap-to-halt interruption) across mobile, tablet, and desktop. Page cards stay horizontally centered at a 2:3 aspect ratio against a deep ambient espresso backdrop (`#141010`).
- **Accessible Typography Controls & Top-Left "AA" Reader Button:** Tap the persistent, unobtrusive dual-sized `'AA'` reader icon button ($52\times 52\text{px}$, featuring a smaller 16pt left 'A' and larger 26pt right 'A') in the top-left viewport corner to cycle through 3 reading presets: `Normal` (baseline book spread), `Mobile` (~1.35× scaling for handheld prayer), and `Extra Large` (~1.7× scaling for high-visibility readability). Displays dynamic font-scaled preset toast feedback (`22pt` Normal, `30pt` Mobile, `38pt` Extra Large) with automatic horizontal re-centering upon cycling, smoothly re-anchors the vertical scroll to maintain reading position without jumps, and persists preferences across launches in `user://reading_progress.cfg`.
- **Top-Right Navigation Drawer & Table of Contents (`game/scenes/ui/navigation_drawer.tscn`):** An unobtrusive floating button (`☰`) in the top-right corner slides open a full-featured navigation drawer with background touch isolation, featuring:
  - **"Resume Last Page" Action:** Dynamically remembers and displays the last visited page with one-tap restoration.
  - **Expandable Mystery Set Accordions:** Dual-action rows for all 4 Mystery sets with left disclosure arrows (`▸` / `▾`) expanding the 5 individual mysteries and title buttons navigating directly to each set's opening page.
  - **Dynamic Liturgical Badge:** Highlights today's canonically recommended mystery set with an antique gold `[★ Today]` badge.
  - **Direct Landmark Navigation:** Instant jump buttons for Cover, History, How to Pray, Opening Prayers, Closing Prayers, Sacred Art Credits, and Back Cover.
  - **Preset-Adaptive Width & Scaled Typography:** Dynamically adapts drawer width (`400px` in Normal, `560px` in Mobile, `680px` in Extra Large), typography, and button touch targets to match the active reading text size preset, with clean word-smart wrapping across all buttons.
- **In-Stream Quick-Jump Separator Bars (`game/scenes/ui/in_stream_jump_bar.tscn`):**
  - **Post-Opening Prayers (After Page 5):** Displays 4 mystery buttons with an antique gold border and *"★ Recommended Today"* badge on today's liturgically recommended mystery set.
  - **Post-Mystery Set Jump Bars (After Pages 15, 25, 35, 45):** Displays a mystery set completion banner and a prominent *"Proceed to the Closing Prayers →"* action button jumping directly to Page 46.
- **Reading Progress Persistence (`game/scripts/core/reading_progress_manager.gd`):** Automatically tracks and persists the current page to `user://reading_progress.cfg` (debounced at 600ms during scroll, immediate on jump) and restores the saved page on startup.
- **VRAM Texture Virtualization & Screen Keep-Awake:** Employs a sliding active buffer window (`ARTWORK_BUFFER_PAGES = 4`) dynamically loading active artwork and unloading distant textures from VRAM for smooth 60 FPS scrolling. Calls `DisplayServer.screen_set_keep_on(true)` to prevent screen dimming during contemplative prayer.


---

## OpenGameStack Integration

This project is configured as an **OpenGameStack (OGS)** project. It includes `stack.json` and `ogs_config.json` files which define the exact environment (Godot 4.7.2) required to run and build the application.

To get started with OGS:
1. Download the [OGS Launcher](https://github.com/OpenGameStack-Launcher/ogs-launcher).
2. Open the OGS Launcher and click **Add Project** to register this repository.
3. The launcher will read `stack.json` and automatically provide the correct Godot version and dependencies.

---

## Print Book & Automated PDF Pipeline (`assets/print/`)

The repository includes a complete automated Python PDF generation pipeline that produces a 50-page, 6" × 9" spiral-bound print edition directly from project assets and structured data:
- **Canonical Print PDF Asset (`assets/print/PrayTheRosary.pdf`):** 50-page, 6.0" × 9.0" (432 × 648 pt) reader/print PDF with alternating 0.625" inner spiral-binding safety margins (0.500" outer/top/bottom margins), zero italic fonts, dynamic version and colophon notices on Pages 48–49, and framed quote callout boxes on Page 50. Tracked under Git LFS (~18 MB).
- **Automated PDF Generator (`scripts/build_print_pdf.py`):** Python script (`reportlab`, `Pillow`, `pymupdf`) compiling the 50-page document directly from `game/data/book_layout.json`, `game/data/prayers.json`, `game/data/mysteries.json`, `game/project.godot`, `game/assets/fonts/EBGaramond-*.ttf`, and `assets/2D/gimp/original_downloads/`.
  - **Standard Reader / Print Edition (Default):**
    ```powershell
    python scripts/build_print_pdf.py
    ```
    Outputs `assets/print/PrayTheRosary.pdf` (6.0" × 9.0").
  - **Retail Copy Shop US Letter Edition (`--office-depot` / `--letter`):**
    ```powershell
    python scripts/build_print_pdf.py --office-depot
    ```
    Generates `assets/print/PrayTheRosary_OfficeDepot.pdf` centered on 8.5" × 11.0" (612 × 792 pt) US Letter sheets with 0.125" bleed and subtle corner crop marks, ideal for double-sided spiral-bound printing at retail copy shops like Office Depot.
  - **Commercial Press Bleed Edition (`--bleed`):**
    ```powershell
    python scripts/build_print_pdf.py --bleed
    ```
    Generates 6.25" × 9.25" (450 × 666 pt) pages with 0.125" bleed, embedding PDF `TrimBox` (6.0" × 9.0") and `BleedBox` metadata for professional commercial print houses.
  - **Custom Output Path (`--output <path>`):**
    ```powershell
    python scripts/build_print_pdf.py --output "path/to/custom.pdf"
    ```

---

## Documentation & Specifications

Key architecture specifications, theological references, and testing standards:
- **[Application Requirements (`documents/requirements.md`)](documents/requirements.md):** Comprehensive digital application specifications, continuous scroll architecture, typography presets, and testing standards.
- **[Print Book Requirements (`documents/book_requirements.md`)](documents/book_requirements.md):** Specifications for the physical 6" × 9" spiral-bound print edition and automated print PDF pipeline.
- **[Canonical References Guide (`documents/references.md`)](documents/references.md):** Complete primary source citations and verification ledger for all 50 physical pages, 12 prayers, 20 mysteries, Catholic Public Domain Version (CPDV) Scripture verses, and 23 fine art masterpieces.
- **[Manual Testing Guide (`documents/manual_testing.md`)](documents/manual_testing.md):** Test suites for manual validation, accessibility testing, and typography verification.
- **[AI Agent Rules (`.agents/rules/references_verification.md`)](.agents/rules/references_verification.md):** Verification protocols and rules governing modifications to sacred text, prayers, and artwork attributions.

---

## Running and Testing

### Automated Test Suites
To run the Godot engine test suite locally:
```powershell
godot --headless --path game -s res://tests/test_runner.gd
```

To run the Python Print PDF pipeline unit tests locally:
```powershell
python -m unittest discover -s scripts -p "test_*.py"
```

---

## AI Agent Integration (MCP)

This project integrates the Model Context Protocol (MCP) to allow AI assistants (like Claude Desktop, Cursor, or Antigravity) to directly interact with the running game.

The `McpInteractionServer` is pre-registered as an AutoLoad (`res://autoloads/mcp_interaction_server.gd`). When you run the application, it exposes a local TCP bridge on port `9090`.

### Python Client for Agents
A lightweight CLI script `mcp_client.py` is included in the project root:
```powershell
python mcp_client.py screenshot      # Captures visual snapshot
python mcp_client.py click 360 640   # Sends click input
python mcp_client.py get_scene_tree  # Returns full SceneTree hierarchy
python mcp_client.py get_ui_elements # Lists interactive UI controls
python mcp_client.py raw '<json>'    # Sends custom MCP JSON payload
```

---

## Cross-Platform Builds & CI/CD

This repository includes production-tested GitHub Actions workflows:
- **Android Release (`android_release.yml`):** Automatically triggers on tag push (`v*`). Runs headless tests, validates 16 KiB page size compliance, builds an Android App Bundle (`.aab`), signs the bundle, and publishes release assets.
- **Web Release (`web_release.yml`):** Automatically builds an HTML5 Web export and attaches a zip archive to GitHub Releases.
- **Print PDF Release (`pdf_release.yml`):** Automatically triggers on tag push (`v*`) or manual dispatch. Validates the test suite (`test_*.py`), builds the canonical 50-page print PDF, and attaches `PrayTheRosary.pdf` to the GitHub Release.
- **GL Compatibility Renderer:** Configured with `gl_compatibility` (OpenGL ES 3.0 / WebGL 2.0), guaranteeing optimal compatibility across Web, Desktop, and Mobile.

---

## Git LFS Requirement

This repository uses [Git Large File Storage (LFS)](https://git-lfs.com/) for artwork and binary assets.
1. Ensure Git LFS is installed on your machine (`git lfs install`).
2. `.gitattributes` tracks images, audio, fonts, and model assets automatically.

---

## License

This project uses a split license:
- **Source Code:** Licensed under the [GNU General Public License v3.0 (GPLv3)](LICENSE).
- **Assets & Media:** Unless otherwise specified, art and assets in `game/assets/` are licensed under [Creative Commons Attribution-ShareAlike 4.0 (CC BY-SA 4.0)](LICENSE-ASSETS) or are in the Public Domain (CC0 / Open Access).
