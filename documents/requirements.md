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

The 50 pages returned by `RosaryDataLoader.get_all_pages()` render using 6 distinct page card layouts inside the vertical scroll:

### 3.1 Type 1: Front Cover Card (`Page 1`, `page_type == "front_cover"`)
- Full-bleed portrait `TextureRect` displaying `res://assets/images/cover.webp` (Bartolomé Esteban Murillo, *The Virgin of the Rosary*).
- Overlay title **"Pray the Rosary"** and subtitle *"A Contemplative Visual Guide to the Twenty Mysteries"* positioned over the upper crimson drapery in warm gold/ivory serif typography (`#D4AF37` / `#F7F2E7`).

### 3.2 Type 2: Front-Matter Text Cards (`Pages 2–3`, `front_matter_spread_left` & `front_matter_spread_right`)
- **Page 2:** *The History of the Holy Rosary* (heading, subheading, and 3 historical sections).
- **Page 3:** *Structure of the Book & How to Pray* (heading, subheading, and 3 instructional sections).

### 3.3 Type 3: Prayer Sequence Cards (`Pages 4 & 46`, `page_type == "prayer_sequence_page"`)
- **Page 4 (*The Opening Prayers*):** Displays heading, subheading, and the 5 introductory prayer steps (Sign of the Cross, Apostles' Creed, Our Father, Three Hail Marys for Faith, Hope, and Charity, and Glory Be).
- **Page 46 (*The Closing Prayers*):** Displays heading, subheading, and the 4 concluding prayer steps (Hail, Holy Queen / *Salve Regina*, Versicle & Response, Concluding Rosary Prayer, and Sign of the Cross).

### 3.4 Type 4: Mystery Prayer Cards (`Even Pages 6, 8, 10, ..., 44`, `page_type == "mystery_prayer_page"`)
Each of the 20 Mystery Prayer Cards fits comfortably on its $2:3$ portrait card with zero internal scrolling:
- **Header:** Ordinal subtitle (e.g., *The First Joyful Mystery*), Mystery Title (e.g., **The Annunciation**), and **Fruit of the Mystery** tag (e.g., *Fruit of the Mystery: Humility*).
- **Scripture Reading:** Public-domain **Douay-Rheims (Challoner Revision)** passage and citation.
- **Contemplative Meditation:** 1–2 sentence reflection.
- **Decade Prayers:** Full text of the *Our Father* (`1×`), *Hail Mary* (`10×`), *Glory Be* (`1×`), and *Fatima Prayer* (`1×`).

### 3.5 Type 5: Sacred Artwork Cards (`Odd Pages 5, 7, 9, ..., 47`, `page_type == "artwork_page"`)
Designed for distraction-free visual contemplation:
- **Top Header Band:** Displays the `subheading` (e.g., *The First Joyful Mystery* or *The Opening Prayers*) and `heading` (e.g., **The Annunciation** or **The Most Holy Trinity**).
- **Gold-Framed Artwork Container:** Thin antique-gold border (`#B89130`) enclosing the painting `TextureRect` (`expand_mode = EXPAND_IGNORE_SIZE`, `stretch_mode = STRETCH_KEEP_ASPECT_CENTERED`, preserving the complete uncropped painting).
- **No Footer Caption or Page Number:** No artist name, museum credit, or page number is shown on the artwork card itself.

### 3.6 Type 6: Credits Cards (`Pages 48–49`) & Back Cover Card (`Page 50`)
- **Page 48 (*Sacred Artwork Credits Part I*):** Lists full artist, life dates, painting title, creation date, medium, and museum location for the Cover, Opening/Closing Prayers, Joyful Mysteries (1–5), and Luminous Mysteries (1–5).
- **Page 49 (*Sacred Artwork Credits Part II & Colophon*):** Lists full credits for the Sorrowful Mysteries (1–5) and Glorious Mysteries (1–5), plus the Douay-Rheims Scripture notice and museum open-access colophon.
- **Page 50 (*Back Cover*):** Deep Baroque crimson (`#4A1215`) card with antique gold border (`#D4AF37`), displaying Pope St. John Paul II's epigraph from *Rosarium Virginis Mariae*, the book synopsis, and St. Louis Marie de Montfort's quote on the daily Rosary.

---

## 4. Navigation, Liturgical Calendar & State Persistence

### 4.1 In-Stream Quick-Jump Separator Bars
Inserted between specific page cards in the vertical scroll (`RosaryDataLoader.get_in_stream_separators()`):
1. **After Page 5 (End of Opening Prayers):**
   - A subtle separator panel prompting *"Select a Mystery Set to Continue Praying:"* with 4 buttons:
     - **Joyful Mysteries** $\rightarrow$ scrolls smoothly/instantly to `Page 6`
     - **Luminous Mysteries** $\rightarrow$ scrolls to `Page 16`
     - **Sorrowful Mysteries** $\rightarrow$ scrolls to `Page 26`
     - **Glorious Mysteries** $\rightarrow$ scrolls to `Page 36`
   - Highlights today's recommended Mystery set (e.g., with a gold *"Recommended Today"* badge).
2. **After Pages 15, 25, 35, and 45 (End of the 5th Mystery of Each Set):**
   - A subtle separator panel with a **"Proceed to the Closing Prayers"** button that scrolls directly to `Page 46` (*The Closing Prayers*).

### 4.2 Top-Right Navigation & Bookmark Menu
- A persistent, unobtrusive button in the **top-right corner** of the viewport opens/closes a slide-out or dropdown navigation drawer containing:
  - **Cover** *(jumps to Page 1)*
  - **History of the Rosary** *(jumps to Page 2)*
  - **How to Pray** *(jumps to Page 3)*
  - **Opening Prayers** *(jumps to Page 4)*
  - **Four Expandable Mystery Set Rows (`Joyful`, `Luminous`, `Sorrowful`, `Glorious`):**
    - Each row has two distinct click targets:
      1. **Left Disclosure Arrow Button (`▸` / `▾`):** Expands or collapses the list of 5 individual Mysteries beneath that Mystery set without closing the menu.
      2. **Mystery Set Title Button:** Immediately jumps to the 1st Mystery of that set (`Pages 6, 16, 26, or 36`) and closes the menu.
    - When expanded, clicking any of the 5 individual Mysteries (e.g., *1. The Annunciation* through *5. The Finding in the Temple*) jumps directly to that Mystery's prayer page (`Even Pages 6..44`) and closes the menu.
    - Displays a *"Recommended Today"* indicator on the day's Mystery set.
  - **Closing Prayers** *(jumps to Page 46)*
  - **Artwork Credits** *(jumps to Page 48)*
  - **Back Cover** *(jumps to Page 50)*

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

### 4.4 Automatic "Resume Last Page" Persistence (`user://`)
- As the user scrolls or jumps to a page, persist the current `page_number` (`1..50`) to `user://reading_progress.cfg` (or `.json`).
- On application launch, automatically restore the scroll position to the last viewed page (defaulting to `Page 1` on first launch).

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
