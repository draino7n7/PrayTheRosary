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
   - **Input Emulation & Native ScrollContainer Decoupling:**
     - **Input Device Emulation Decoupling:** `Main.handle_scroll_input()` filters out synthetic input events where `event.device == InputEvent.DEVICE_ID_EMULATION` (`-1`) so touch-from-mouse and mouse-from-touch emulation do not cause double-scrolling or cancel momentum.
     - **Native `ScrollContainer` Decoupling:** `ScrollContainer.mouse_filter` is configured as `Control.MOUSE_FILTER_IGNORE` (`2`) across scene definition and lifecycle states, preventing Godot's internal `drag_touching` state machine from fighting the custom momentum physics while allowing child controls (buttons, cards) to receive clicks and touch events cleanly.
     - **Zero-Delta Vertical Movement Filter:** Motion events where `delta_y == 0` (e.g. purely horizontal micro-jitter during release) do not record zero-velocity samples or alter `_last_drag_time_msec`.
   - **Momentum & Inertia Scrolling Physics:**
     - Quick flicks and drags on touchscreens and left-mouse dragging impart release velocity into a smooth, natural momentum glide with simulated friction decay.
     - **Rolling Velocity Window & Flick Detection:** Velocity samples are recorded during drag gestures within a rolling 120 ms time window (`VELOCITY_SAMPLE_WINDOW_MS = 120`). On release (`InputEventScreenTouch.pressed == false` or `InputEventMouseButton.pressed == false`), the release velocity is calculated from the rolling window average, ensuring natural finger lift deceleration during the final 30–60 ms does not suppress flick momentum. Momentum initiates if release velocity meets or exceeds `MIN_FLICK_VELOCITY = 100.0` px/s and the user did not pause before lifting (`elapsed <= DRAG_PAUSE_TIMEOUT_MS = 150` ms). Initial velocity is clamped to `MAX_MOMENTUM_VELOCITY = 6000.0` px/s.
     - **Decay Curve, Glide Distance & Rest Cutoff:** Frame-rate independent exponential friction decay `pow(MOMENTUM_FRICTION, delta * 60.0)` with factor `MOMENTUM_FRICTION = 0.986` decelerates an internal sub-pixel float accumulator (`_momentum_scroll_y`) in `_process(delta)`. A brisk flick (1500–2500 px/s) glides across 1.5 to 3+ portrait page cards over 1.5–2.5 seconds matching platform-standard iOS/Android touch physics. Momentum halts cleanly when `absf(velocity) < MOMENTUM_STOP_VELOCITY = 12.0` px/s.
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

### 2.3 Global Dynamic Text Sizing System
To accommodate diverse user needs, high-DPI mobile devices, and accessible reader experiences, the application features a global typography scaling system with 3 distinct presets:
- **`normal` (Normal / Default):** The baseline layout matching the 6" × 9" physical prayer book spread geometry. All 50 page cards fit within the canonical 720×1080 (2:3) canvas with zero vertical overflow. Standard body text: 19–24pt; headings: 34–38pt; subheadings: 22–24pt.
- **`mobile` (Mobile Large):** Optimized for reading on handheld screens while holding physical rosary beads. Scales headings up to 38pt, subheadings to 25pt, fruit badges to 24pt, scripture citations to 23pt, and body text/rubrics up to 27–33pt (approximately 1.35× scaling factor).
- **`extra_large` (Extra Large):** High-visibility accessibility mode for seniors and low-vision readers. Scales headings up to 44pt, subheadings to 29pt, fruit badges to 30pt, scripture citations to 29pt, and body text/rubrics up to 35–44pt (approximately 1.7× scaling factor).

Under the `mobile` and `extra_large` presets, text-heavy cards dynamically elongate vertically to guarantee zero truncation and zero internal scrollbars, while sacred art and cover pages maintain their locked 2:3 aspect ratio.

---

## 3. Page Card Types in the 50-Page Vertical Scroll

The 50 pages returned by `RosaryDataLoader.get_all_pages()` render inside the vertical scroll using a modular component architecture centered around a unified facade container and 7 specialized sub-card components:

### 3.0 Modular Component Architecture
- **Root Facade Component (`res://scenes/ui/page_card.tscn` / `res://scripts/ui/page_card.gd`):**
  - Inherits `BasePageCard` (`AspectRatioContainer`) with default $2:3$ ratio (`ratio = 2.0 / 3.0`) and minimum design size `720×1080`.
  - Automatically instantiates and hosts the appropriate specialized sub-card based on `page_data["page_type"]`.
  - Exposes static factory method `PageCard.create_for_page(page_data, loader)` and `bind_page_data(page_data, loader)` for continuous scroll instantiation.
  - Dynamically synchronizes dimensions with sub-cards via `_sync_with_sub_card()`: when a text-heavy sub-card elongates vertically beyond 1080px under larger typography presets, `PageCard` sets `custom_minimum_size = Vector2(720.0, target_h)` and adjusts `ratio = 720.0 / target_h`. For artwork and cover pages, it strictly preserves `custom_minimum_size = Vector2(720.0, 1080.0)` and `ratio = 2.0 / 3.0`.
- **Base Class (`res://scripts/ui/pages/base_page_card.gd`):**
  - Defines `BasePageCard`, extending `AspectRatioContainer`, establishing `mouse_filter = Control.MOUSE_FILTER_PASS`, the common lifecycle method `bind_page_data(page_data, loader)`, typography preset management (`set_text_size_preset()`, `get_text_size_preset()`, `normalize_preset()`, `get_required_card_height()`), standard inspector accessors (`get_heading_text()`, `get_subheading_text()`), and the recursive helper `BasePageCard.configure_pass_through_mouse_filters(node: Node)`.
  - **Pass-Through Mouse Filter Enforcement:** Every `Control` inside `PageCard`, `InStreamJumpBar`, and `NavigationDrawer/ContentContainer` is configured via `configure_pass_through_mouse_filters()` so that `BaseButton` descendants use `Control.MOUSE_FILTER_PASS` (allowing clicks/taps while passing drag/wheel input through), `Label` / `TextureRect` / `ColorRect` nodes use `Control.MOUSE_FILTER_IGNORE`, and layout containers use `Control.MOUSE_FILTER_PASS` (never `Control.MOUSE_FILTER_STOP`).
- **Data Hydration (`res://scripts/data/rosary_data_loader.gd`):**
  - `RosaryDataLoader` indexes all artwork entries via `get_artwork(artwork_id)` and `get_all_artworks()`, attaching each painting's non-numbered placement `section_label` (`"Front Cover"`, `"Opening Prayers"`, `"1st Joyful Mystery (The Annunciation)"` .. `"5th Glorious Mystery (The Coronation of the Blessed Virgin Mary)"`, and `"Closing Prayers"`).
  - Credits spreads (`spread_type == "credits_spread"`, Pages 48 & 49) automatically hydrate artwork attribution dictionaries in `lp_credits["attributions"]` and `rp_credits["attributions"]`.

### 3.0.1 Typography Sizing, Margin Standardization & Dynamic Vertical Card Elongation
To maximize mobile readability, eliminate vacant vertical whitespace, and guarantee zero vertical text clipping or internal scrolling on the $720×1080$ portrait canvas across all typography presets:
- **Standardized MarginContainers:**
  - Standard page card scenes (`CoverPageCard`, `FrontMatterPageCard`, `PrayerSequencePageCard`, `MysteryPrayerPageCard`, `ArtworkPageCard`) enforce a uniform **32px** margin on all four edges (`margin_left = 32`, `margin_right = 32`, `margin_top = 32`, `margin_bottom = 32`), yielding a consistent content width of 656px (`CreditsPageCard` uses 32px left/right margins and 22px top/bottom margins).
  - `BackCoverPageCard` aligns with 34–36px outer padding and 24px content block vertical separation.
- **Header Typography Sizing (Normal Preset Baseline):**
  - `SubheadingLabel`: Standardized to **22–24pt** (>= 22pt) in EB Garamond Italic (22pt on standard cards, 24pt on BackCover subtitle).
  - `HeadingLabel`: Standardized to **34–38pt** (>= 34pt) in EB Garamond Bold (34pt on standard cards, 38pt on Cover & BackCover titles).
- **Body Typography Auto-Fitting & Vertical Space Distribution:**
  - **Front Matter (`Pages 2 & 3`):** Dynamic font scaling calibrated to character density (`total_chars <= 1650`). Normal: Page 2 (1,622 chars) renders at 22pt body / 25pt section headers; Page 3 (1,813 chars) renders at 20pt body / 23pt section headers. Mobile: 26–28pt body / 30–32pt headers. Extra Large: 32–36pt body / 38–40pt headers. Section containers configure `SIZE_EXPAND_FILL`.
  - **Prayer Sequences (`Pages 4 & 46`):** Calibrated scaling: Page 4 (5 prayer steps) renders at 19pt body / 16pt rubrics / 20pt titles (Normal), 27pt body / 22pt rubrics / 28pt titles (Mobile), 35pt body / 28pt rubrics / 36pt titles (Extra Large); Page 46 (4 prayer steps) renders at 23pt body / 18pt rubrics / 24pt titles (Normal), 32pt body / 24pt rubrics / 33pt titles (Mobile), 42pt body / 32pt rubrics / 42pt titles (Extra Large). Prayer step containers configure `SIZE_EXPAND_FILL`.
  - **Mystery Prayers (`Pages 6, 8, ..., 44 even`):**
    - Fruit badge: 18pt (Normal), 24pt (Mobile), 30pt (Extra Large) in gold pill box.
    - Scripture citation: 17pt (Normal), 23pt (Mobile), 29pt (Extra Large) bold with gold vertical border accent.
    - Dynamic density scaling: Normal renders at 22–24pt body / 18–20pt scripture / 17–18pt decade rubric; Mobile scales to 31–33pt body / 24–25pt rubric; Extra Large scales to 40–44pt body / 31–33pt rubric.
    - Decade prayer step containers configure `SIZE_EXPAND_FILL` for vertical balance.
  - **Credits & Colophon (`Pages 48 & 49`):**
    - Part I (Page 48, 12 attributions): Normal: 16pt bold title / 14pt details; Mobile: 22pt bold title / 19pt details; Extra Large: 28pt bold title / 24pt details.
    - Part II (Page 49, 11 attributions + Colophon): Normal: 16pt bold title / 14pt details / 13pt colophon; Mobile: 22pt bold title / 19pt details / 17pt colophon; Extra Large: 28pt bold title / 24pt details / 22pt colophon.
  - **Back Cover (`Page 50`):** 38pt title / 22pt subtitle / 22pt epigraphs / 20pt synopsis / 17pt attributions with 24px vertical separation and `SIZE_EXPAND_FILL`.
- **Dynamic Vertical Elongation Rules for Text Cards:**
  - Text-heavy cards (`PrayerSequencePageCard`, `MysteryPrayerPageCard`, `FrontMatterPageCard`, `CreditsPageCard`) calculate their exact required content height using `FontFile.get_multiline_string_size()`.
  - Under `normal` preset, content height fits cleanly within the standard `1080.0px` envelope (`height <= 1080.0px`).
  - Under `mobile` and `extra_large` presets, when content demands additional height, cards dynamically elongate vertically beyond 1080px (`height > 1080.0px`), updating `custom_minimum_size.y` and adjusting `ratio = DESIGN_WIDTH / final_height`.
  - This guarantees that enlarged fonts never clip, truncate, or spawn awkward internal nested scrollbars inside cards; the continuous outer vertical stream absorbs all vertical growth naturally.
- **Strict 2:3 Aspect Ratio Lock for Artwork and Covers:**
  - `ArtworkPageCard` (`Pages 5, 7, 9, ..., 47`), `CoverPageCard` (`Page 1`), and `BackCoverPageCard` (`Page 50`) are strictly locked to the canonical 2:3 portrait aspect ratio (`ratio = 2.0 / 3.0`, `custom_minimum_size = Vector2(720.0, 1080.0)`) across all text size presets.
  - Sacred artwork paintings and book covers are never stretched, distorted, cropped, or elongated.

### 3.0.2 Strict 720px Card Width Constraint, StyleBox Content Margins & Universal Word-Smart Wrapping
To prevent lateral expansion, horizontal overflow, and asymmetrical screen shifts across all viewports and typography presets:
- **Strict 720px Width Enforcement:**
  - All page cards (`PageCard` and its specialized sub-cards), `CardPanel` containers, and `PageContainer` must strictly enforce a maximum width constraint of 720px (`custom_minimum_size.x = 720.0` and `combined_minimum_size.x <= 720.0`).
  - No page card, panel, or nested child control may expand horizontally beyond 720px under any circumstances, guaranteeing zero lateral scroll drift and perfectly balanced viewport centering.
- **Universal Word-Smart Label Autowrapping (`autowrap_mode = TextServer.AUTOWRAP_WORD_SMART`):**
  - All `Label` nodes across all page card scenes and runtime programmatic instantiations (`SubheadingLabel`, `HeadingLabel`, `FruitLabel`, `ScriptureCitationLabel`, `ScriptureTextLabel`, `MeditationLabel`, `DecadeRubric`, `PrayerText`, `PrayerTitle`, `SectionTitleLabel`, `SectionBody`, `TitleLabel`, `SubtitleLabel`, `EpigraphQuoteLabel`, `ColophonNoticeLabel`, `ScriptureNoticeLabel`, `InStreamJumpBar/PromptLabel`, etc.) must enforce `autowrap_mode = TextServer.AUTOWRAP_WORD_SMART` (enum value `3`).
  - Never leave text labels unwrapped or configured with word-only wrapping (`AUTOWRAP_WORD`), which can trigger minimum width expansion on long titles or scaled typography.
- **CardPanel StyleBoxFlat Explicit Zero Content Margins (`content_margin_* = 0.0`):**
  - In Godot 4, `StyleBoxFlat` default internal content margins (`content_margin_left`, `content_margin_right`, `content_margin_top`, `content_margin_bottom`) default to `-1.0`, causing the engine to implicitly inherit the border widths (e.g., 2px left + 2px right = 4px). In a 720px panel with 720px content, this implicit margin adds 4px to the panel's combined minimum size (yielding 724px), causing horizontal blowout and rightward shift.
  - All card background `StyleBoxFlat` resources (e.g. `StyleBoxFlat_parchment`, `StyleBoxFlat_cover_crimson`) must explicitly set `content_margin_left = 0.0`, `content_margin_top = 0.0`, `content_margin_right = 0.0`, and `content_margin_bottom = 0.0`.
- **FruitBadge Dynamic Width Clamping Pattern:**
  - The `FruitBadge` (`PanelContainer`) inside `MysteryPrayerPageCard` uses `size_flags_horizontal = SIZE_SHRINK_CENTER` so the pill badge wraps tightly around short fruit names (e.g. *"Humility"*). Under enlarged presets (e.g., `extra_large` on *"Fruit of the Mystery: Contempt of the World"* or *"Fruit of the Mystery: Conversion of Sinners"*), unwrapped text width would exceed available content width (656px - 28px horizontal padding = 628px) and push the entire card width beyond 720px.
  - To prevent this while retaining center-shrink behavior on shorter strings, `FruitLabel.custom_minimum_size.x` must be clamped dynamically:
    ```gdscript
    var unwrapped_fruit_w: float = font_italic.get_string_size(fruit_str, HORIZONTAL_ALIGNMENT_CENTER, -1, fruit_font_size).x
    var target_label_w: float = ceilf(minf(unwrapped_fruit_w, 628.0))
    fruit_label.custom_minimum_size = Vector2(target_label_w, 0.0)
    fruit_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    ```
- **Dynamic Multiline Card Height Calculation (`Font.get_multiline_string_size`):**
  - Dynamic vertical height calculations (`total_h`) in text cards must calculate heading, fruit, citation, and rubric heights using `Font.get_multiline_string_size(text, alignment, max_width, font_size).y` (using 656.0px for standard card content, 636.0px for scripture container, and 628.0px for fruit badge) rather than single-line approximations (`Font.get_height()`) so that multi-line wrapped headers are accurately reflected in card elongation.


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
  - `ScrollContainer.mouse_filter` permanently maintains `Control.MOUSE_FILTER_IGNORE` (`2`) across both open and closed states, while `reader_button.mouse_filter` toggles between `Control.MOUSE_FILTER_STOP` (closed) and `Control.MOUSE_FILTER_IGNORE` (open) so that floating HUD controls cannot be accidentally activated while the drawer is open.
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
- Persists to `user://reading_progress.cfg` using Godot's `ConfigFile` under section `[reading_progress]`, key `last_page_number`.
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

### 4.6 Floating "Aa" Reader Button & Typography Preset Persistence
- **Top-Left Floating "Aa" Reader Button:**
  - Located on a dedicated HUD canvas layer (`ReaderCanvasLayer`, `layer = 10`) positioned at `offset_left = 18.0`, `offset_top = 18.0`, with fixed dimensions `52×52px`.
  - Visual styling matches the canonical illuminated manuscript palette: warm parchment background (`#FAF6EE` at 0.92 alpha), 2px antique gold border (`#B89130`), corner radius 8px, drop shadow, and deep charcoal bold Garamond typography (`#1E1815`) at 24pt.
  - Interactive states: Hover border brightens to `#D4AF37`, pressed border shifts to Marian crimson `#6B1D21`.
  - Pass-through handling: When the navigation drawer is opened, `reader_button.mouse_filter = Control.MOUSE_FILTER_IGNORE` to prevent clicks through the drawer scrim; restored to `MOUSE_FILTER_STOP` upon drawer closing.
- **One-Tap Preset Cycling & Feedback Toast:**
  - Tapping the "Aa" button cycles sequentially through: `Normal` $\rightarrow$ `Mobile` $\rightarrow$ `Extra Large` $\rightarrow$ `Normal`.
  - Displays a centered top floating toast banner (`PresetToast`, `PanelContainer`) styled in parchment and gold with bold Garamond 18pt text (e.g., *"Text Size: Normal"*, *"Text Size: Mobile"*, *"Text Size: Extra Large"*).
  - In graphical runtimes, the toast smoothly lingers for 1.2s before fading out over 0.4s via a tween.
- **Viewport Scroll Anchor Stability:**
  - When switching presets, `Main.set_text_size_preset()` calculates the relative vertical center of the currently viewed page element in the viewport prior to resizing.
  - After all 50 cards update their minimum dimensions and layouts, the viewport scroll position is re-anchored to the exact relative position of that same element, preventing abrupt jumps, disorientation, or lost reading position.
- **Configuration Persistence (`user://reading_progress.cfg`):**
  - Stored under section `[reading_progress]`, key `text_size_preset` (values: `"normal"`, `"mobile"`, `"extra_large"`).
  - Loaded automatically at application boot by `Main._ready()` / `ReadingProgressManager`, restoring the user's preferred typography scale before initial card rendering.

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
4. **Card Width & Label Wrapping Standards:**
   - All page cards, `CardPanel` containers, and `PageContainer` must maintain `custom_minimum_size.x = 720.0` and `combined_minimum_size.x <= 720.0` across all text presets.
   - All text labels must specify `autowrap_mode = TextServer.AUTOWRAP_WORD_SMART` (`3`) to prevent horizontal minimum width expansion.
   - All card panel `StyleBoxFlat` resources must explicitly specify `content_margin_* = 0.0` to eliminate 4px implicit border margin blowout.
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
