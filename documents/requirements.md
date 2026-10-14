# Application Requirements: Pray The Rosary (Godot 4.7.2 App)

This document is the definitive source of truth for the **Pray The Rosary** digital application built with Godot 4.7.2 for the OpenGameStack ecosystem. Autonomous subagents (`issue_creator`, `issue_resolver`, and `pr_reviewer`) MUST consult this document when creating issues, implementing features, or reviewing Pull Requests.

*(Note: Specifications specific to the physical 6" × 9" spiral-bound print edition are maintained separately in [`documents/book_requirements.md`](book_requirements.md).)*

---

## 1. Application Overview & Core Design Tenets

**Pray The Rosary** is a distraction-free, contemplative Rosary prayer companion and sacred art guide.

### Core Design Tenets
1. **Continuous 50-Page Vertical Scroll:**
   - The application presents all **50 sequential portrait pages** (`Page 1` Front Cover at the very top through `Page 50` Back Cover at the bottom) in a single smooth vertical `ScrollContainer`.
   - Every page is rendered as a distinct **$2:3$ ($6:9$) portrait page card**. On portrait mobile screens, page cards fill the viewport width; on wider tablet/desktop windows, page cards remain centered horizontally at a $2:3$ aspect ratio against a deep ambient backdrop (`#141010`).
   - Integrated with 5 in-stream quick-jump separator bars (`InStreamJumpBar`) placed after Page 5 and after each mystery set (Pages 15, 25, 35, 45), comprising exactly 55 elements in the continuous stream.
2. **Distraction-Free Contemplation:**
   - **No Numerical Page Numbers:** Do not render visible numerical page numbers (`1..50`) on any page cards.
   - **No On-Page Artwork Captions:** Artwork pages (`Pages 5, 7, 9, ..., 47`) display **only** the Top Section/Mystery Header and the gold-framed painting so nothing distracts from using the sacred image as a prayer focus. All artist, title, date, and museum attributions appear exclusively on the **Sacred Artwork Credits pages (`Pages 48–49`)**.
   - **No Interactive Bead-Clicking Mechanic (MVP):** Prayer pages display the complete text of the prayers with clear rubrics (e.g., *"10× Hail Mary"*), assuming the user prays with physical Rosary beads or their fingers.
   - **Silent & Always-On:** The MVP application is completely silent (no background music or sound effects) and keeps the device screen awake (`DisplayServer.screen_set_keep_on(true)` when not running headlessly) so the screen never dims or locks during a 3–4 minute decade.
3. **Data-Driven Architecture:**
   - All prayers, mysteries, Douay-Rheims Scripture readings, meditations, artwork metadata, and page sequences are loaded dynamically via `RosaryDataLoader` (`res://scripts/data/rosary_data_loader.gd`) from `res://data/prayers.json`, `res://data/mysteries.json`, and `res://data/book_layout.json`.

---

## 2. Visual Theme, Color Palette & Typography

### 2.1 Color Palette
- **App Ambient Backdrop (Outside Page Cards):** Deep Espresso Charcoal (`#141010`)
- **Interior Page Card Background (`Pages 2–49`):** Warm Ivory / Parchment (`#FAF6EE`)
- **Interior Page Primary Body Text:** Deep Charcoal / Espresso (`#1E1815`)
- **Interior Page Headings & Mystery Titles:** Baroque Marian Crimson (`#6B1D21`)
- **Subheadings, Rubrics & Scripture Citations:** Muted Warm Umber (`#5C4338`)
- **Page Card Borders, Dividers & Artwork Frame Border:** Antique Gold (`#B89130`)
- **Front Cover (`Page 1`) & Back Cover (`Page 50`) Palette:**
  - Deep Baroque Crimson Background (`#4A1215` primary / `#2A090B` dark accent)
  - Warm Gold Accent & Title Typography (`#D4AF37`)
  - Warm Ivory Body Text (`#F7F2E7`)

### 2.2 Typography & Theme (`game/assets/fonts/`, `game/resources/rosary_theme.tres`)
- **Bundled Fonts:** **EB Garamond** (SIL Open Font License 1.1, license bundled at `game/assets/fonts/OFL.txt`) is bundled in `game/assets/fonts/` with all 4 core weights:
  - `EBGaramond-Regular.ttf`
  - `EBGaramond-Bold.ttf`
  - `EBGaramond-Italic.ttf`
  - `EBGaramond-BoldItalic.ttf`
- **Application Theme:** The canonical Godot `Theme` resource is located at `res://resources/rosary_theme.tres` (mirrored at `res://assets/themes/rosary_theme.tres` and configured globally in `project.godot` via `[gui] theme/custom` and `theme/custom_font`). It defines:
  - Default font: `EBGaramond-Regular.ttf` (size 20).
  - Complete `RosaryPalette` color table (`parchment` `#FAF6EE`, `charcoal` `#1E1815`, `crimson` `#6B1D21`, `umber` `#5C4338`, `gold` `#B89130`, `ambient_espresso` `#141010`, `cover_crimson` `#4A1215`, `warm_gold` `#D4AF37`, `ivory_text` `#F7F2E7`).
  - Styled controls for `Label`, `RichTextLabel` (normal, bold, italics fonts), `Button` (interactive flat styleboxes with gold accents across normal, hover, pressed, focus, and disabled states), `PanelContainer` (parchment background with 2px gold border), and `ScrollContainer` (transparent empty stylebox for seamless vertical scrolling).

---

## 3. Page Card Types in the 50-Page Vertical Scroll

The 50 pages returned by `RosaryDataLoader.get_all_pages()` render inside the vertical scroll using a modular component architecture centered around a unified facade container and 7 specialized sub-card components:

### 3.0 Modular Component Architecture
- **Root Facade Component (`res://scenes/ui/page_card.tscn` / `res://scripts/ui/page_card.gd`):**
  - Inherits `AspectRatioContainer` with strict $2:3$ ratio (`ratio = 2.0 / 3.0`) and minimum design size `720×1080`.
  - Automatically instantiates and hosts the appropriate specialized sub-card based on `page_data["page_type"]`.
  - Exposes static factory method `PageCard.create_for_page(page_data, loader)` and `bind_page_data(page_data, loader)` for continuous scroll instantiation.
- **Base Class (`res://scripts/ui/pages/base_page_card.gd`):**
  - Defines `BasePageCard`, extending `Control`, establishing the common lifecycle method `bind_page_data(page_data, loader)` and standard inspector accessors (`get_heading_text()`, `get_subheading_text()`, `get_body_text()`).
- **Data Hydration (`res://scripts/data/rosary_data_loader.gd`):**
  - `RosaryDataLoader` indexes all artwork entries via `get_artwork(artwork_id)` and `get_all_artworks()`.
  - Credits spreads (`spread_type == "credits_spread"`, Pages 48 & 49) automatically hydrate artwork attribution dictionaries in `lp_credits["attributions"]` and `rp_credits["attributions"]`.

### 3.1 Type 1: Front Cover Card (`Page 1`, `res://scenes/ui/pages/cover_page_card.tscn`, `res://scripts/ui/pages/cover_page_card.gd`)
- Full-bleed portrait `TextureRect` displaying `res://assets/images/cover.webp` (Bartolomé Esteban Murillo, *The Virgin of the Rosary*).
- Overlay title **"Pray the Rosary"** and subtitle *"A Contemplative Visual Guide to the Twenty Mysteries"* positioned over the upper crimson drapery in warm gold/ivory serif typography (`#D4AF37` / `#F7F2E7`), leaving Mary and the Christ Child unobstructed.

### 3.2 Type 2: Front-Matter Text Cards (`Pages 2–3`, `res://scenes/ui/pages/front_matter_page_card.tscn`, `res://scripts/ui/pages/front_matter_page_card.gd`)
- **Page 2:** *The History of the Holy Rosary* (heading, subheading, and 3 historical sections).
- **Page 3:** *Structure of the Book & How to Pray* (heading, subheading, and 3 instructional sections).
- Rendered on warm ivory parchment panels (`#FAF6EE`) with crimson titles, umber subtitles, and dark charcoal body paragraphs.

### 3.3 Type 3: Prayer Sequence Cards (`Pages 4 & 46`, `res://scenes/ui/pages/prayer_sequence_page_card.tscn`, `res://scripts/ui/pages/prayer_sequence_page_card.gd`)
- **Page 4 (*The Opening Prayers*):** Displays heading, subheading, and the 5 introductory prayer steps (Sign of the Cross, Apostles' Creed, Our Father, Three Hail Marys for Faith, Hope, and Charity, and Glory Be).
- **Page 46 (*The Closing Prayers*):** Displays heading, subheading, and the 4 concluding prayer steps (Hail, Holy Queen / *Salve Regina*, Versicle & Response, Concluding Rosary Prayer, and Sign of the Cross).
- Formatted with muted umber rubric tags (e.g. `[1×]`, `[10×]`, `[Sign of the Cross]`) and charcoal prayer text.

### 3.4 Type 4: Mystery Prayer Cards (`Even Pages 6, 8, 10, ..., 44`, `res://scenes/ui/pages/mystery_prayer_page_card.tscn`, `res://scripts/ui/pages/mystery_prayer_page_card.gd`)
Each of the 20 Mystery Prayer Cards fits comfortably on its $2:3$ portrait card with zero internal scrolling:
- **Header:** Ordinal subtitle (e.g., *The First Joyful Mystery*), Mystery Title (e.g., **The Annunciation**), and **Fruit of the Mystery** tag badge (e.g., *Fruit of the Mystery: Humility*).
- **Scripture Reading:** Public-domain **Douay-Rheims (Challoner Revision)** passage and citation.
- **Contemplative Meditation:** 1–2 sentence reflection.
- **Decade Prayers:** Full text of the *Our Father* (`1×`), *Hail Mary* (`10×`), *Glory Be* (`1×`), and *Fatima Prayer* (`1×`).

### 3.5 Type 5: Sacred Artwork Cards (`Odd Pages 5, 7, 9, ..., 47`, `res://scenes/ui/pages/artwork_page_card.tscn`, `res://scripts/ui/pages/artwork_page_card.gd`)
Designed for distraction-free visual contemplation:
- **Top Header Band:** Displays the `subheading` (e.g., *The First Joyful Mystery* or *The Opening Prayers*) and `heading` (e.g., **The Annunciation** or **The Most Holy Trinity**).
- **Gold-Framed Artwork Container:** Thin antique-gold border (`#B89130`) enclosing the painting `TextureRect` (`expand_mode = EXPAND_IGNORE_SIZE`, `stretch_mode = STRETCH_KEEP_ASPECT_CENTERED`, preserving the complete uncropped painting).
- **No Footer Caption or Page Number:** Strictly no artist name, museum credit, or page number is shown on the artwork card itself.

### 3.6 Type 6: Credits Cards (`Pages 48–49`, `res://scenes/ui/pages/credits_page_card.tscn`, `res://scripts/ui/pages/credits_page_card.gd`) & Back Cover Card (`Page 50`, `res://scenes/ui/pages/back_cover_page_card.tscn`, `res://scripts/ui/pages/back_cover_page_card.gd`)
- **Page 48 (*Sacred Artwork Credits Part I*):** Lists full artist, life dates, painting title, creation date, medium, and museum location for the Cover, Opening/Closing Prayers, Joyful Mysteries (1–5), and Luminous Mysteries (1–5).
- **Page 49 (*Sacred Artwork Credits Part II & Colophon*):** Lists full credits for the Sorrowful Mysteries (1–5) and Glorious Mysteries (1–5), plus the Douay-Rheims Scripture notice and museum open-access colophon.
- **Page 50 (*Back Cover*):** Deep Baroque crimson (`#4A1215`) card with antique gold border (`#D4AF37`), displaying Pope St. John Paul II's epigraph from *Rosarium Virginis Mariae*, the book synopsis, and St. Louis Marie de Montfort's Marian counsel.

---

## 4. Navigation, Liturgical Calendar & State Persistence

### 4.1 In-Stream Quick-Jump Separator Bars
Implemented via `res://scenes/ui/in_stream_jump_bar.tscn` (`res://scripts/ui/in_stream_jump_bar.gd`) and inserted between specific page cards in the continuous vertical scroll stream (`RosaryDataLoader.get_in_stream_separators()`), yielding exactly **55 total stream elements** (50 `PageCard` instances + 5 `InStreamJumpBar` instances):
1. **After Page 5 (End of Opening Prayers):**
   - A separator panel prompting *"Select a Mystery Set to Continue Praying:"* with 4 buttons:
     - **Joyful Mysteries** $\rightarrow$ scrolls to `Page 6`
     - **Luminous Mysteries** $\rightarrow$ scrolls to `Page 16`
     - **Sorrowful Mysteries** $\rightarrow$ scrolls to `Page 26`
     - **Glorious Mysteries** $\rightarrow$ scrolls to `Page 36`
   - Highlights today's liturgically recommended Mystery set with an antique gold border (`#B89130`), gold tinted background, and a *"★ Recommended Today"* badge, determined dynamically via `RosaryDataLoader.get_recommended_mystery_set_for_today()`.
2. **After Pages 15, 25, 35, and 45 (End of the 5th Mystery of Each Set):**
   - A separator panel displaying a completion prompt (e.g., *"End of the Five Joyful Mysteries"*) and a prominent crimson-accented action button:
     - **"Proceed to the Closing Prayers →"** $\rightarrow$ scrolls directly to `Page 46` (*The Closing Prayers*).
3. **Signal Integration:**
   - Each `InStreamJumpBar` emits `jump_requested(target_page: int)`, connected cleanly to `Main.scroll_to_page()`.

### 4.2 Top-Right Navigation & Bookmark Menu
Implemented via `res://scenes/ui/navigation_drawer.tscn` (`res://scripts/ui/navigation_drawer.gd`):
- **Node Hierarchy & Visual Design:**
  - `NavigationDrawer` (`CanvasLayer`, `layer = 15`): Overlays the continuous stream and main HUD cleanly.
  - `FloatingNavButton` (`Button`): Unobtrusive 48×48px floating toggle button pinned in the top-right viewport corner displaying the `☰` navigation icon.
  - `DrawerOverlay` (`Control`): Full-screen control (`ANCHORS_PRESET_FULL_RECT`) containing:
    - `Scrim` (`ColorRect`): Semi-transparent dimming backdrop (`#00000080`, `mouse_filter = MOUSE_FILTER_STOP`). Clicking the scrim closes the drawer.
    - `DrawerPanel` (`PanelContainer`): Right-aligned sliding drawer panel styled in warm ivory parchment (`#FAF6EE`) with an antique gold left border (`#B89130`), minimum width 320px (responsive on portrait displays).
    - `DrawerScroll` (`ScrollContainer`): Smooth vertical scrolling container for drawer content.
    - `ContentContainer` (`VBoxContainer`): Vertical list hosting all navigation entries and dividers.
- **Background Touch Isolation & Dismissal:**
  - When the drawer opens, `Main` sets `scroll_container.mouse_filter = MOUSE_FILTER_IGNORE` so background page cards cannot be accidentally scrolled during drawer navigation.
  - Restores `scroll_container.mouse_filter = MOUSE_FILTER_STOP` when closed.
  - Drawer can be dismissed via clicking the close button (`✕`), tapping the dimming `Scrim` backdrop, pressing `Escape` / `ui_cancel`, or selecting any navigation destination.
- **"Resume Last Page" Action Button:**
  - Positioned prominently at the top of the drawer content list.
  - Integrated with `ReadingProgressManager` / `user://reading_progress.cfg`.
  - Displays dynamic contextual label (e.g., *"Resume Last Page: The Baptism of Jesus in the Jordan (Page 16)"* or *"Resume: Front Cover (Page 1)"*).
  - Clicking immediately jumps to the saved page and dismisses the drawer.
- **Top-Level Landmark Section Buttons:**
  - Styled navigation buttons for non-mystery landmark sections:
    - `Front Cover (Page 1)`
    - `History of the Rosary (Page 2)`
    - `Structure & How to Pray (Page 3)`
    - `The Opening Prayers (Page 4)`
    - `The Closing Prayers (Page 46)`
    - `Sacred Artwork Credits (Page 48)`
    - `Back Cover (Page 50)`
  - Each button emits `page_requested(page_number)` and closes the drawer.
- **Expandable Mystery Set Accordions (Dual-Action Rows):**
  - Covers all 4 Mystery Sets (`Joyful`, `Luminous`, `Sorrowful`, `Glorious`) in canonical order.
  - **Dual-Action Click Targets:**
    1. **Left Disclosure Arrow Button (`▸` / `▾`):** Expands or collapses the indented sub-list of 5 individual Mysteries beneath that set without closing the drawer and without emitting `page_requested`.
    2. **Mystery Set Title Button:** Immediately navigates to the **1st Mystery** prayer page of that set (`Page 6`, `Page 16`, `Page 26`, or `Page 36`) and closes the drawer.
  - **All 20 Individual Mystery Sub-Buttons:** Indented list under each set displaying mystery ordinal and canonical title (e.g., *1. The Annunciation* $\rightarrow$ `Page 6`, *2. The Visitation* $\rightarrow$ `Page 8`, through *5. The Coronation of Mary* $\rightarrow$ `Page 44`). Clicking any individual mystery button jumps directly to that mystery's left prayer page and closes the drawer.
- **Dynamic Liturgical "Recommended Today" Badge:**
  - Queries `RosaryDataLoader.get_recommended_mystery_set_for_today()` upon drawer initialization and opening.
  - Displays a distinctive antique gold badge (`[★ Today]`) alongside today's liturgically recommended Mystery Set title (e.g. Joyful on Mon/Sat, Luminous on Thu, Sorrowful on Tue/Fri, Glorious on Wed/Sun).


### 4.3 Dynamic Liturgical Calendar for Daily Mystery Recommendation
Implemented in `RosaryDataLoader.get_recommended_mystery_set_for_date(year, month, day)`:
- **Monday & Saturday:** `"joyful"`
- **Thursday:** `"luminous"`
- **Tuesday & Friday:** `"sorrowful"`
- **Wednesday:** `"glorious"`
- **Sunday (Dynamic by Liturgical Season via Gregorian Easter Computus):**
  - **Advent & Christmas Season Sundays** (from the First Sunday of Advent, Nov 27–Dec 3, through the Baptism of the Lord, up to Jan 13): `"joyful"`
  - **Lenten Sundays** (from the First Sunday of Lent, 42 days before Easter, through Palm Sunday, 7 days before Easter): `"sorrowful"`
  - **Easter Season & Ordinary Time Sundays:** `"glorious"`

### 4.4 Automatic "Resume Last Page" Persistence (`user://reading_progress.cfg`)
Implemented via `ReadingProgressManager` (`res://scripts/core/reading_progress_manager.gd`):
- Tracks the currently viewed page number (`1..50`) calculated dynamically from the vertical scroll position in `Main` (`res://scripts/main/main.gd`).
- Persists to `user://reading_progress.cfg` using Godot's `ConfigFile` under section `[progress]`, key `last_viewed_page`.
- **Save Debouncing:** Debounces disk writes with a 600ms timer during active scrolling to prevent disk thrashing, while immediately saving on discrete jump bar activations.
- **Launch Restoration:** On startup, loads the saved page (defaulting to `Page 1` on fresh launch) and restores the vertical scroll position cleanly.

### 4.5 Texture Virtualization & Screen Keep-Awake
1. **Sliding Buffer Window Virtualization (`ARTWORK_BUFFER_PAGES = 4`):**
   - High-resolution sacred art `.webp` textures are memory-intensive. `Main` maintains an active buffer window of $\pm 4$ pages around the current viewport.
   - Cards within the buffer window have their artwork loaded via `load_artwork()` on `ArtworkPageCard` and `CoverPageCard`.
   - Cards outside the buffer window are unloaded via `unload_artwork()`, freeing VRAM and preventing memory bloat on mobile and web platforms while maintaining a consistent 60 FPS scroll.
   - Transparent fallback: `PageCard.get_artwork_texture()` automatically reloads textures on demand if queried outside the active window.
2. **Screen Keep-Awake:**
   - `Main._ready()` calls `DisplayServer.screen_set_keep_on(true)` guarded by `DisplayServer.get_name() != "headless"` to prevent mobile displays from dimming or locking during contemplative prayer.

---

## 5. Asset Pipeline & Archival Protection

### 5.1 Immutable Original Downloads (`assets/2D/gimp/original_downloads/`)
- All 23 `*_master_*.jpg` files in `assets/2D/gimp/original_downloads/` (cataloged in `assets/2D/gimp/attributions.json`) are unmodified, byte-for-byte archival downloads.
- Agents and scripts must **never** modify, overwrite, crop, resize, rename, or delete any file inside `assets/2D/gimp/original_downloads/`.

### 5.2 Runtime Game Textures (`game/assets/images/`)
- All 23 runtime `.webp` textures have been generated in `game/assets/images/` from the archival master files in `assets/2D/gimp/original_downloads/` at quality 85, with maximum height constrained to 1800px and original aspect ratios strictly preserved.
- These textures match the exact `runtime_texture_path` entries in `book_layout.json` and `mysteries.json` (e.g., `res://assets/images/cover.webp`, `res://assets/images/opening_prayers.webp`, `res://assets/images/closing_prayers.webp`, and the 20 mystery textures `res://assets/images/{set}_{num}_{name}.webp`).
- Verified via automated unit tests in `game/tests/test_assets_and_theme.gd` to confirm non-zero dimensions, correct aspect ratios, and clean loading as `Texture2D`.

---

## 6. Technical Constraints & Testing Standards

1. **Godot Version & Renderer:** Godot `4.7.2`, `gl_compatibility` renderer.
2. **Static Typing:** GDScript static typing is strictly enforced across all production scripts and test suites.
3. **Headless Unit Tests (`game/tests/`):**
   - Run via:
     ```powershell
     godot --headless --editor --quit --path game
     godot --headless --path game -s res://tests/test_runner.gd
     ```
   - All data files, liturgical date calculations, save/load persistence, and UI scenes must have automated unit tests with 0 failures.
