# Application Requirements: Pray The Rosary (Godot 4.7.2 App)

This document is the definitive source of truth for the **Pray The Rosary** digital application built with Godot 4.7.2 for the OpenGameStack ecosystem. Autonomous subagents (`issue_creator`, `issue_resolver`, and `pr_reviewer`) MUST consult this document when creating issues, implementing features, or reviewing Pull Requests.

*(Note: Specifications specific to the physical 6" × 9" spiral-bound print edition are maintained separately in [`documents/book_requirements.md`](book_requirements.md).)*

---

## 1. Application Overview & Core Design Tenets

**Pray The Rosary** is a distraction-free, contemplative Rosary prayer companion and sacred art guide.

### Core Design Tenets
1. **Continuous 50-Page Vertical Scroll:**
   - The application presents all **50 sequential portrait pages** (`Page 1` Front Cover at the very top through `Page 50` Back Cover at the bottom) in a single smooth vertical `ScrollContainer`.
   - **Scrollbar-Free Sacred Booklet Aesthetic:** Both `Main/ScrollContainer` and `NavigationDrawer/DrawerScroll` enforce `vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER` (`3`) and `horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED` (`0`) so no right-side or bottom scrollbar ever interrupts the full-bleed contemplation view.
   - **Touch Swipe, Mouse Drag & Mouse Wheel Scrolling:** `Main.handle_scroll_input(event)` (invoked from `Main._input(event)` when the navigation drawer is closed) directly handles `InputEventScreenDrag` (touch swipe), left-mouse-button `InputEventMouseMotion` (`button_mask & MOUSE_BUTTON_MASK_LEFT != 0`), and `InputEventMouseButton` (`MOUSE_BUTTON_WHEEL_UP` / `MOUSE_BUTTON_WHEEL_DOWN`), clamping `scroll_container.scroll_vertical` to `[0, max_scroll]` and cancelling any active scroll tween. In `game/project.godot`, `[input_devices]` sets `pointing/emulate_touch_from_mouse=true`.
   - **Momentum & Inertia Scrolling Physics:**
     - Quick flicks and drags on touchscreens and left-mouse dragging impart release velocity into a smooth, natural momentum glide with simulated friction decay.
     - **Flick Detection & Threshold:** Velocity is tracked during gestures (`_drag_velocity_y`). On release (`InputEventScreenTouch.pressed == false` or `InputEventMouseButton.pressed == false`), momentum initiates if release velocity meets or exceeds `MIN_FLICK_VELOCITY = 120.0` px/s and the user did not pause before lifting (`elapsed <= DRAG_PAUSE_TIMEOUT_MS = 150` ms). Initial velocity is clamped to `MAX_MOMENTUM_VELOCITY = 6000.0` px/s.
     - **Decay Curve & Rest Cutoff:** Frame-rate independent exponential friction decay `pow(MOMENTUM_FRICTION, delta * 60.0)` with factor `MOMENTUM_FRICTION = 0.96` decelerates an internal sub-pixel float accumulator (`_momentum_scroll_y`) in `_process(delta)`. Momentum halts cleanly when `absf(velocity) < MOMENTUM_STOP_VELOCITY = 10.0` px/s.
     - **Strict Boundary Clamping:** Residual velocity is immediately zeroed and momentum is halted when reaching stream boundaries (`0` at Page 1 or `_get_max_scroll_vertical()` at Page 50), preventing overshoot, bounce, or stickiness.
     - **Immediate Interruption:** Active momentum is immediately halted upon any touch press down, mouse press down, mouse wheel scroll, navigation drawer opening (`_on_drawer_opened`), or page navigation (`scroll_to_page`).
     - **Virtualization & Reading Progress Synchronization:** As momentum scrolls past page boundaries, texture virtualization (`_update_virtualization`) and debounced reading progress saving (`_save_timer`) update dynamically.
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
  - Inherits `BasePageCard` (`AspectRatioContainer`) with strict $2:3$ ratio (`ratio = 2.0 / 3.0`) and minimum design size `720×1080`.
  - Automatically instantiates and hosts the appropriate specialized sub-card based on `page_data["page_type"]`.
  - Exposes static factory method `PageCard.create_for_page(page_data, loader)` and `bind_page_data(page_data, loader)` for continuous scroll instantiation.
- **Base Class (`res://scripts/ui/pages/base_page_card.gd`):**
  - Defines `BasePageCard`, extending `AspectRatioContainer`, establishing `mouse_filter = Control.MOUSE_FILTER_PASS`, the common lifecycle method `bind_page_data(page_data, loader)`, standard inspector accessors (`get_heading_text()`, `get_subheading_text()`), and the recursive helper `BasePageCard.configure_pass_through_mouse_filters(node: Node)`.
  - **Pass-Through Mouse Filter Enforcement:** Every `Control` inside `PageCard`, `InStreamJumpBar`, and `NavigationDrawer/ContentContainer` is configured via `configure_pass_through_mouse_filters()` so that `BaseButton` descendants use `Control.MOUSE_FILTER_PASS` (allowing clicks/taps while passing drag/wheel input through), `Label` / `TextureRect` / `ColorRect` nodes use `Control.MOUSE_FILTER_IGNORE`, and layout containers use `Control.MOUSE_FILTER_PASS` (never `Control.MOUSE_FILTER_STOP`).
- **Data Hydration (`res://scripts/data/rosary_data_loader.gd`):**
  - `RosaryDataLoader` indexes all artwork entries via `get_artwork(artwork_id)` and `get_all_artworks()`, attaching each painting's non-numbered placement `section_label` (`"Front Cover"`, `"Opening Prayers"`, `"1st Joyful Mystery (The Annunciation)"` .. `"5th Glorious Mystery (The Coronation of the Blessed Virgin Mary)"`, and `"Closing Prayers"`).
  - Credits spreads (`spread_type == "credits_spread"`, Pages 48 & 49) automatically hydrate artwork attribution dictionaries in `lp_credits["attributions"]` and `rp_credits["attributions"]`.

### 3.0.1 Typography Sizing, Margin Standardization & Layout Calibration
To maximize mobile readability, eliminate vacant vertical whitespace, and guarantee zero vertical text clipping or internal scrolling on the $720×1080$ ($2:3$) portrait card canvas:
- **Standardized MarginContainers:**
  - Standard page card scenes (`CoverPageCard`, `FrontMatterPageCard`, `PrayerSequencePageCard`, `MysteryPrayerPageCard`, `ArtworkPageCard`) enforce a uniform **32px** margin on all four edges (`margin_left = 32`, `margin_right = 32`, `margin_top = 32`, `margin_bottom = 32`), yielding a consistent content width of 656px (`CreditsPageCard` uses 32px left/right margins and 22px top/bottom margins).
  - `BackCoverPageCard` aligns with 34–36px outer padding and 24px content block vertical separation.
- **Header Typography Sizing:**
  - `SubheadingLabel`: Standardized to **22–24pt** (>= 22pt) in EB Garamond Italic (22pt on standard cards, 24pt on BackCover subtitle).
  - `HeadingLabel`: Standardized to **34–38pt** (>= 34pt) in EB Garamond Bold (34pt on standard cards, 38pt on Cover & BackCover titles).
- **Body Typography Auto-Fitting & Vertical Space Distribution:**
  - **Front Matter (`Pages 2 & 3`):** Dynamic font scaling calibrated to character density (`total_chars <= 1650`). Page 2 (1,622 chars) renders at 22pt body / 25pt section headers; Page 3 (1,813 chars) renders at 20pt body / 23pt section headers. Section containers configure `SIZE_EXPAND_FILL` to distribute content evenly across the full 1080px canvas.
  - **Prayer Sequences (`Pages 4 & 46`):** Calibrated scaling: Page 4 (5 prayer steps) renders at 19pt body / 16pt rubrics / 20pt titles; Page 46 (4 prayer steps) renders at 23pt body / 18pt rubrics / 24pt titles. Prayer step containers configure `SIZE_EXPAND_FILL`.
  - **Mystery Prayers (`Pages 6, 8, ..., 44 even`):**
    - Fruit badge standardized to 18pt in gold pill box.
    - Scripture citation standardized to 17pt bold with gold vertical border accent.
    - Dynamic density scaling: Standard-density mysteries render at 22pt body / 20pt scripture / 18pt decade rubric; high-density mysteries (such as Page 40 Pentecost, 1,326 chars) render at 20pt body / 18pt scripture / 17pt decade rubric.
    - Decade prayer step containers configure `SIZE_EXPAND_FILL` for vertical balance.
  - **Credits & Colophon (`Pages 48 & 49`):**
    - Part I (Page 48, 12 attributions in sequential book order: Front Cover, Opening Prayers, Joyful Mysteries 1–5, and Luminous Mysteries 1–5): 16pt bold title (`"%s — %s" % [section_label, art_title]`) / 14pt regular details with `SIZE_EXPAND_FILL` and 22px top/bottom margins.
    - Part II (Page 49, 11 attributions + Colophon in sequential book order: Sorrowful Mysteries 1–5, Glorious Mysteries 1–5, and Closing Prayers last): 16pt bold title (`"%s — %s" % [section_label, art_title]`) / 14pt regular details / 13pt colophon notices.
  - **Back Cover (`Page 50`):** 38pt title / 22pt subtitle / 22pt epigraphs / 20pt synopsis / 17pt attributions with 24px vertical separation and `SIZE_EXPAND_FILL`.
- **Zero Vertical Overflow Guarantee:**
  - Automated tests assert that all 50 hydrated pages have total required height $\le 1080.0\text{px}$, ensuring no text clipping or hidden lines across the entire 50-page stream.

### 3.1 Type 1: Front Cover Card (`Page 1`, `res://scenes/ui/pages/cover_page_card.tscn`, `res://scripts/ui/pages/cover_page_card.gd`)
- Structured vertical layout (`VBoxContainer`) featuring a dedicated Top Header Band styled in deep Baroque crimson (`#4A1215`) with antique gold border (`#D4AF37`), housing **"PRAY THE ROSARY"** in warm gold 38pt bold (`#D4AF37`), the subtitle *"A Contemplative Visual Guide to the Twenty Mysteries"* in warm ivory 22pt italic (`#F7F2E7`), and an ornamental gold divider line.
- Positioned strictly below the header is a framed artwork container enclosing Bartolomé Esteban Murillo's *The Virgin of the Rosary* (`res://assets/images/cover.webp`) (`expand_mode = EXPAND_IGNORE_SIZE`, `stretch_mode = STRETCH_KEEP_ASPECT_CENTERED`), guaranteeing that zero text elements overlap any portion of the sacred painting.
- Displays no visible page number on the cover. Standard 32px outer margins.

### 3.2 Type 2: Front-Matter Text Cards (`Pages 2–3`, `res://scenes/ui/pages/front_matter_page_card.tscn`, `res://scripts/ui/pages/front_matter_page_card.gd`)
- **Page 2:** *The History of the Holy Rosary* (22pt subheading, 34pt heading, 25pt section headers, 22pt body paragraphs), including the historical note that Pope St. Pius V in 1571 instituted the feast of Our Lady of Victory (renamed the Feast of Our Lady of the Rosary in 1573).
- **Page 3:** *Structure of the Book & How to Pray* (22pt subheading, 34pt heading, 23pt section headers, 20pt body paragraphs), noting in *"How This Book Is Organized"* under *"Left Page (Word & Prayer)"* that the passage from Sacred Scripture is `(taken from the Douay-Rheims / Confraternity Edition of the Bible)` so the Bible version is stated once in the front matter rather than repeated on every Mystery page, and explaining in *"Step-by-Step Guide to Praying the Rosary"* (Step 2: *"2. The Decades (Tabs J, L, S, G)"*) that the user may pray either the five decades of the day's Mystery set or all four Mystery sets (twenty decades) back-to-back in chronological order (*Joyful, Luminous, Sorrowful, Glorious*) for a complete Rosary.
- Rendered on warm ivory parchment panels (`#FAF6EE`) with crimson titles, umber subtitles, and dark charcoal body paragraphs with 32px uniform margins and `SIZE_EXPAND_FILL` section distribution.

### 3.3 Type 3: Prayer Sequence Cards (`Pages 4 & 46`, `res://scenes/ui/pages/prayer_sequence_page_card.tscn`, `res://scripts/ui/pages/prayer_sequence_page_card.gd`)
- **Page 4 (*The Opening Prayers*):** Displays 22pt subheading, 34pt heading, and the 5 introductory prayer steps (*The Sign of the Cross*, *The Apostles' Creed*, *The Our Father*, *Three Hail Marys for Faith, Hope, and Charity*, and *The Glory Be*—using the simplified canonical titles `"The Our Father"` and `"The Glory Be"` without `"The Lord's Prayer"` or `"(Doxology)"`) rendered at 20pt prayer titles, 16pt rubrics, and 19pt body text.
- **Page 46 (*The Closing Prayers*):** Displays 22pt subheading, 34pt heading, and the 4 concluding prayer steps (Hail, Holy Queen / *Salve Regina*, Versicle & Response, Concluding Rosary Prayer, and Sign of the Cross) rendered at 24pt prayer titles, 18pt rubrics, and 23pt body text.
- Formatted with muted umber rubric tags (e.g. `[1×]`, `[10×]`, `[Sign of the Cross]`), charcoal prayer text, 32px margins, and `SIZE_EXPAND_FILL` step distribution.

### 3.4 Type 4: Mystery Prayer Cards (`Even Pages 6, 8, 10, ..., 44`, `res://scenes/ui/pages/mystery_prayer_page_card.tscn`, `res://scripts/ui/pages/mystery_prayer_page_card.gd`)
Each of the 20 Mystery Prayer Cards fits comfortably on its $2:3$ portrait card with zero internal scrolling and 32px uniform margins:
- **Header:** Ordinal subtitle (22pt italic), Mystery Title (34pt bold), and **Fruit of the Mystery** tag badge in gold pill container (18pt italic).
- **Scripture Reading:** Public-domain **Douay-Rheims (Challoner Revision)** citation (17pt bold with gold vertical border accent, displaying clean book, chapter, and verse citations without repeating a trailing `" (Douay-Rheims)"` suffix on each page, using traditional DRBO book titles with modern equivalents where helpful—e.g., *Isaias (Isaiah) 53:5*, *Ecclesiasticus (Sirach) 24:7*, *Apocalypse (Revelation) 12:1*—and ordered strictly to match the sequence of quoted verses) and verbatim passage (18–20pt italic).
- **Contemplative Meditation:** 1–2 sentence reflection (20–22pt regular).
- **Decade Prayers:** Full text of *The Our Father* (`1× The Our Father`), *The Hail Mary* (`10× The Hail Mary`), *The Glory Be* (`1× The Glory Be`), and *The Fatima Prayer* (`1× The Fatima Prayer`) (17–18pt bold rubric labels, 20–22pt regular prayer text).

### 3.5 Type 5: Sacred Artwork Cards (`Odd Pages 5, 7, 9, ..., 47`, `res://scenes/ui/pages/artwork_page_card.tscn`, `res://scripts/ui/pages/artwork_page_card.gd`)
Designed for distraction-free visual contemplation:
- **Top Header Band:** Displays the `subheading` at 22pt italic (e.g., *The First Joyful Mystery* or *The Opening Prayers*) and `heading` at 34pt bold (e.g., **The Annunciation** or **The Most Holy Trinity**).
- **Gold-Framed Artwork Container:** Thin antique-gold border (`#B89130`) enclosing the painting `TextureRect` (`expand_mode = EXPAND_IGNORE_SIZE`, `stretch_mode = STRETCH_KEEP_ASPECT_CENTERED`, preserving the complete uncropped painting) with 32px margins.
- **No Footer Caption or Page Number:** Strictly no artist name, museum credit, or page number is shown on the artwork card itself.

### 3.6 Type 6: Credits Cards (`Pages 48–49`, `res://scenes/ui/pages/credits_page_card.tscn`, `res://scripts/ui/pages/credits_page_card.gd`) & Back Cover Card (`Page 50`, `res://scenes/ui/pages/back_cover_page_card.tscn`, `res://scripts/ui/pages/back_cover_page_card.gd`)
- **Page 48 (*Sacred Artwork Credits Part I*):** 22pt subheading (`"Front Cover, Opening Prayers, Joyful Mysteries & Luminous Mysteries"`), 34pt heading, 32px horizontal / 22px vertical margins. Lists 12 artwork attributions in exact sequential book appearance order (Front Cover, Opening Prayers, Joyful Mysteries 1–5, and Luminous Mysteries 1–5), displaying each credit entry's non-numbered placement `section_label` alongside the painting title (`"%s — %s" % [section_label, art_title]`, e.g., `"1st Joyful Mystery (The Annunciation) — The Annunciation (La Anunciación)"`) at 16pt bold title (`AUTOWRAP_WORD_SMART`) and full artist, life dates, creation date, medium, and museum location at 14pt regular details.
- **Page 49 (*Sacred Artwork Credits Part II & Colophon*):** 22pt subheading (`"Sorrowful Mysteries, Glorious Mysteries, Closing Prayers & Text Sources"`), 34pt heading, 32px horizontal / 22px vertical margins. Lists 11 artwork attributions in exact sequential book appearance order (Sorrowful Mysteries 1–5, Glorious Mysteries 1–5, and Closing Prayers last) at 16pt bold `section_label — title` (`AUTOWRAP_WORD_SMART`) and 14pt regular details, plus the Douay-Rheims Scripture notice (13pt italic) and museum open-access colophon (13pt regular).
- **Page 50 (*Back Cover*):** Deep Baroque crimson (`#4A1215`) card with antique gold border (`#D4AF37`), displaying title in 38pt bold gold, subtitle in 22pt italic gold, Pope St. John Paul II's epigraph in 22pt italic with 17pt attribution, the book synopsis in 20pt body text, and St. Louis Marie de Montfort's full verbatim Marian counsel from *The Secret of the Rosary* (25th Rose) in 22pt italic with 17pt attribution, distributed cleanly with 24px block separation and zero overflow.

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
- All 23 `*_master_*.jpg` files in `assets/2D/gimp/original_downloads/` (cataloged in `assets/2D/gimp/attributions.json` in exact sequential order of appearance in the book, ending with `"closing_prayers"`) are unmodified, byte-for-byte archival downloads.
- Every entry in `assets/2D/gimp/attributions.json` maintains non-empty museum catalog `inventory_number`, `original_dimensions`, and non-numbered placement `section_label` records, and its `inventory_number`, `creation_date`, `current_location`, and `section_label` fields are strictly synchronized with `game/data/mysteries.json`, `game/data/book_layout.json`, and `RosaryDataLoader`.
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
---

## 7. Platform & Export Specifications (App Icon, Adaptive Icons & Boot Splash)

### 7.1 Application Launcher Icons
- **Main App Icon (`config/icon`):**
  - Path: `res://assets/icons/icon.png`
  - Dimensions: 512×512 RGBA square PNG.
  - Composition: Calibrated crop from Bartolomé Esteban Murillo's *The Virgin of the Rosary* (c. 1650–1655), focusing closely on the Virgin Mary and the Infant Jesus with their radiant halos, rosary beads, and crucifix. Balanced across square, circle, and squircle mask viewports on desktop window headers, taskbars, and launcher menus.
- **Android Adaptive Launcher Icons (`export_presets.cfg`):**
  - **Foreground Asset (`launcher_icons/adaptive_foreground_432x432`):** `res://assets/icons/icon_foreground.png` (432×432 RGBA PNG). Mary and Infant Jesus are framed strictly within the standard 72dp / 288px safe zone, with edges softly vignetted to accommodate parallax motion and custom OEM masking shapes (circle, squircle, rounded rectangle) without hard edge clipping.
  - **Background Asset (`launcher_icons/adaptive_background_432x432`):** `res://assets/icons/icon_background.png` (432×432 RGB PNG). Solid canonical deep ambient espresso `#141010` (`Color(0.0784314, 0.0627451, 0.0627451, 1)`).

### 7.2 Boot Splash Screen
- **Splash Image (`boot_splash/image`):**
  - Path: `res://assets/icons/boot_splash.png`
  - Specifications: 1137×1800 uncropped high-resolution rendering of the full *The Virgin of the Rosary* cover masterpiece.
  - Note: Godot's core startup initialization (`main/main.cpp`) strictly requires PNG format for `boot_splash/image` (WebP or other formats trigger startup engine fallback/errors).
- **Splash Background Color (`boot_splash/bg_color`):**
  - Value: `Color(0.0784314, 0.0627451, 0.0627451, 1)` (`#141010` deep ambient espresso), seamlessly matching the app's ambient canvas background during launch transitions.
