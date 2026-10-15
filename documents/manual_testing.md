# Manual Testing Guide

This document outlines the strict manual testing procedures required before any release candidate can be deployed.

## Test 1.0: Launch & Boot
- **Step 1:** Open the app (`godot --path game`).
- **Expected:** The app boots cleanly without errors or crashes.

## Test 2.0: Typography & Font Rendering
- **Step 1:** Launch the application and observe any visible text (`Label`, `RichTextLabel`, and `Button` controls).
- **Expected:** 
  - Text renders using **EB Garamond** serif font across Regular, Bold, and Italic styles.
  - Characters appear crisp and legible without blurring, pixelation, distortion, or clipping at native and scaled resolutions.
  - Standard page card headers satisfy minimum font thresholds: `SubheadingLabel` $\ge 22\text{pt}$ (Garamond italic) and `HeadingLabel` $\ge 34\text{pt}$ (Garamond bold; $38\text{pt}$ on Cover and Back Cover).
  - Body text is maximized to fill card height without vertical overflow or internal scrolling (`required_height \le 1080.0\text{px}`).

## Test 3.0: Theme & Palette Consistency
- **Step 1:** Inspect UI elements utilizing `res://resources/rosary_theme.tres`.
- **Expected:**
  - Ambient viewport backdrop displays deep espresso charcoal (`#141010`).
  - Page container panels render with warm ivory / parchment background (`#FAF6EE`) framed by a 2px antique gold border (`#B89130`).
  - Headings display in baroque Marian crimson (`#6B1D21`).
  - Primary body text displays in deep charcoal / espresso (`#1E1815`).
  - Subheadings and rubrics display in muted warm umber (`#5C4338`).
  - Interactive buttons feature flat ivory/parchment styleboxes with subtle gold borders across normal, hover, pressed, and focus states.

## Test 4.0: Sacred Artwork Rendering
- **Step 1:** Inspect artwork display containers referencing runtime textures in `res://assets/images/`.
- **Expected:**
  - Paintings load cleanly from `.webp` format.
  - Images preserve their original aspect ratio without distortion or unnatural cropping (`stretch_mode = STRETCH_KEEP_ASPECT_CENTERED`).
  - Images appear centered and framed by the antique gold border (`#B89130`).

## Test 5.0: 2:3 Portrait Page Card Components

### TC-PAGE-01: Front Cover Card (`Page 1`)
- **Step 1:** Inspect the Front Cover card in the UI or test runner.
- **Expected:**
  - Front Cover card renders using a structured vertical layout (`VBoxContainer`) with standardized 32px outer margins.
  - Title elements are housed in a dedicated Top Header Band styled in deep Baroque crimson (`#4A1215` / `#2A090B`) with an antique gold border (`#D4AF37`).
  - Title **"PRAY THE ROSARY"** displays in warm gold serif typography at 38pt bold (`#D4AF37`), subtitle *"A Contemplative Visual Guide to the Twenty Mysteries"* in warm ivory at 22pt italic (`#F7F2E7`), separated by an ornamental gold divider line.
  - Bartolomé Esteban Murillo's *The Virgin of the Rosary* (`cover.webp`) renders centered in an antique gold framed artwork container strictly below the header band (`expand_mode = EXPAND_IGNORE_SIZE`, `stretch_mode = STRETCH_KEEP_ASPECT_CENTERED`).
  - Zero text or typography elements overlap any portion of the painting (the Virgin Mary, the Christ Child, the rosary, and halo remain completely unobstructed).
  - Strictly no numerical page numbers appear.

### TC-PAGE-02: Front-Matter Text Cards (`Pages 2 & 3`)
- **Step 1:** Inspect Page 2 (*The History of the Holy Rosary*) and Page 3 (*Structure of the Book & How to Pray*).
- **Expected:**
  - Standardized 32px uniform margins (`margin_left`, `margin_right`, `margin_top`, `margin_bottom`).
  - 22pt italic subheading, 34pt bold heading, and warm ivory parchment panels (`#FAF6EE`) with antique gold borders (`#B89130`).
  - Calibrated typography auto-fitting based on character density (`total_chars <= 1650`):
    - Page 2 (1,622 chars): 25pt section headers and 22pt body paragraphs.
    - Page 3 (1,813 chars): 23pt section headers and 20pt body paragraphs.
  - Page 2 Section 3 (*Pope St. Pius V & The Twenty Mysteries*) accurately documents: `"...and in 1571 instituted the feast of Our Lady of Victory (renamed the Feast of Our Lady of the Rosary in 1573)."`
  - Page 3 Section 1 (*How This Book Is Organized*) explicitly notes the Bible translation in the `"Left Page (Word & Prayer)"` bullet: `• Left Page (Word & Prayer): Displays the Mystery title, its spiritual fruit, a passage from Sacred Scripture (taken from the Douay-Rheims / Confraternity Edition of the Bible), a brief meditation, and the complete prayers for that decade.`
  - Page 3 Section 2 (*Step-by-Step Guide to Praying the Rosary*) displays `"2. The Decades (Tabs J, L, S, G):"` and explains praying either the five decades of the day's Mystery set or all four Mystery sets (twenty decades) back-to-back in chronological order (`Joyful, Luminous, Sorrowful, Glorious`) for a complete Rosary, with all three sections fitting comfortably inside the `720×1080` card with zero overflow.
  - Section containers configure `SIZE_EXPAND_FILL` to evenly balance vertical space across the full 1080px canvas with zero text overflow or clipping.

### TC-PAGE-03: Prayer Sequence Cards (`Pages 4 & 46`)
- **Step 1:** Inspect Page 4 (*The Opening Prayers*) and Page 46 (*The Closing Prayers*).
- **Expected:**
  - Standardized 32px uniform margins, 22pt italic subheading, and 34pt bold heading.
  - Page 4 displays exactly 5 introductory prayer steps formatted with 20pt prayer titles, 16pt rubrics, and 19pt body text, using the simplified titles `"The Our Father"` (Step 3) and `"The Glory Be"` (Step 5) without `"The Lord's Prayer"` or `"(Doxology)"`.
  - Page 46 displays 4 concluding prayer steps formatted with 24pt prayer titles, 18pt rubrics, and 23pt body text.
  - Distinct muted umber rubric tags (e.g., `[1×]`, `[10×]`, `[Sign of the Cross]`) precede each prayer item.
  - Prayer step containers expand (`SIZE_EXPAND_FILL`) to balance card height with zero vertical overflow.

### TC-PAGE-04: Mystery Prayer Cards (`Even Pages 6, 8, 10, ..., 44`)
- **Step 1:** Inspect all 20 Mystery Prayer Cards.
- **Expected:**
  - Standardized 32px uniform margins.
  - Header displays 22pt italic mystery ordinal (e.g., *The First Joyful Mystery*), 34pt bold title (e.g., **The Annunciation**), and 18pt italic fruit badge (*Fruit of the Mystery: Humility*) in antique gold pill box.
  - Scripture citation renders at 17pt bold with a gold vertical accent bar (displaying clean book, chapter, and verse citations without any trailing `" (Douay-Rheims)"` suffix), and scripture reading renders at 18–20pt italic.
  - Verify canonical Douay-Rheims (Challoner Revision) citations and verbatim scripture passages:
    - **Joyful 4 (`Page 12`):** Citation reads `"Luke 2:22, 28–32"` and Luke 2:28 uses bracketed subject `"[Then Simeon] took him into his arms"`.
    - **Luminous 4 (`Page 22`):** Citation reads `"Luke 9:29–31, 35"` and verse 35 concludes with verbatim `"This is my beloved Son; hear him."`.
    - **Sorrowful 2 (`Page 28`):** Citation reads `"John 19:1; Isaias (Isaiah) 53:5"`.
    - **Sorrowful 4 (`Page 32`):** Citation order reads `"John 19:17; Luke 23:26–27"`, matching the sequence of quoted verses.
    - **Sorrowful 5 (`Page 34`):** Citation reads `"Luke 23:33–34, 46"` and Luke 23:46 reads verbatim `"And Jesus crying out with a loud voice, said:"`.
    - **Glorious 2 (`Page 38`):** Citation `"Luke 24:50–52; Acts 1:9"` separates Luke 24:50–52 and Acts 1:9 in canonical order with ellipses.
    - **Glorious 4 (`Page 42`):** Citation order reads `"Judith 15:10; Psalm 44:14, 16"`, matching the sequence of quoted verses.
    - **Glorious 5 (`Page 44`):** Citation reads `"Apocalypse (Revelation) 12:1; Ecclesiasticus (Sirach) 24:7"`.
  - Contemplative meditation renders at 20–22pt regular text.
  - Decade prayers (*The Our Father* with rubric `"1× The Our Father"`, *The Hail Mary* with rubric `"10× The Hail Mary"`, *The Glory Be* with rubric `"1× The Glory Be"`, and *The Fatima Prayer* with rubric `"1× The Fatima Prayer"`) render with 17–18pt bold rubrics and 20–22pt regular text.
  - High-density passages (e.g., Page 40 Pentecost with 1,326 chars) auto-fit cleanly to 20pt body / 18pt scripture / 17pt rubrics, guaranteeing zero internal scrolling and zero vertical overflow on the 720×1080 canvas.

### TC-PAGE-05: Sacred Artwork Cards (`Odd Pages 5, 7, 9, ..., 47`)
- **Step 1:** Inspect all 22 Artwork Cards (Opening, 20 Mysteries, Closing).
- **Expected:**
  - Standardized 32px uniform margins.
  - Top header band displays the mystery ordinal subheading at 22pt italic and mystery title at 34pt bold.
  - Painting renders centered inside the antique gold border (`#B89130`) preserving original aspect ratio.
  - Strictly **NO captions** (artist, museum, date) and **NO numerical page numbers** appear on the artwork card.

### TC-PAGE-06: Credits & Back Cover Cards (`Pages 48, 49, & 50`)
- **Step 1:** Inspect Pages 48 and 49 (*Sacred Artwork Credits Parts I & II*) and Page 50 (*Back Cover*).
- **Expected:**
  - 32px horizontal / 22px vertical margins, 22pt italic subheading, and 34pt bold heading on Pages 48 and 49.
  - Page 48 (`"Front Cover, Opening Prayers, Joyful Mysteries & Luminous Mysteries"`) lists 12 attributions in exact sequential book appearance order (Front Cover, Opening Prayers, Joyful Mysteries 1–5, and Luminous Mysteries 1–5) at 16pt bold title (`"%s — %s" % [section_label, art_title]`, with `AUTOWRAP_WORD_SMART` and zero page numbers) and 14pt regular details with `SIZE_EXPAND_FILL` spacing, including updated creation dates for Ricci's *The Marriage at Cana* (`c. 1712–1715`) and Rubens's *The Last Supper* (`1631–1632`).
  - Page 49 (`"Sorrowful Mysteries, Glorious Mysteries, Closing Prayers & Text Sources"`) lists 11 attributions in exact sequential book appearance order (Sorrowful Mysteries 1–5, Glorious Mysteries 1–5, and Closing Prayers last, ending with `"Closing Prayers — The Immaculate Conception of Los Venerables (Inmaculada de Soult)"`) at 16pt bold title (`"%s — %s" % [section_label, art_title]`) and 14pt regular details—including Maíno's *Pentecost* (`1612–1614`), Murillo's *The Assumption of the Virgin* at `State Hermitage Museum, St. Petersburg, Russia`, and Velázquez's *The Coronation of the Virgin* (`c. 1635–1636`)—plus the Douay-Rheims Scripture notice (13pt italic) and museum colophon (13pt regular) with zero clipping or vertical overflow.
  - Page 50 displays deep Baroque crimson (`#4A1215`) card with 38pt title in warm gold, 22pt italic subtitle, 22pt epigraphs with 17pt attributions (including St. Louis Marie de Montfort's full verbatim Marian counsel: *"Never will anyone who says his Rosary every day become a formal heretic or be led astray by the devil. This is a statement that I would gladly sign with my blood."*), 20pt body synopsis, and 24px vertical block separation with zero vertical overflow.

## Test 6.0: Continuous 50-Page Vertical Scroll, Jump Bars & Reading Progress

### TC-SCROLL-01: Continuous 50-Page Scroll View, Hidden Scrollbars & Touch/Mouse/Wheel Scrolling
- **Step 1:** Launch the application (`godot --path game`) on desktop (widescreen window) and resize or simulate mobile (portrait).
- **Expected:**
  - The application presents all 50 sequential page cards in a single vertical stream.
  - **No Scrollbars:** Neither the main 50-page `ScrollContainer` nor the `NavigationDrawer/DrawerScroll` renders a vertical or horizontal scrollbar along the right or bottom edge (`vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER`, `horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED`).
  - In widescreen / desktop mode, page cards remain centered horizontally with strict 2:3 aspect ratio against the deep espresso `#141010` ambient backdrop.
  - In portrait mode, page cards fill the screen width smoothly.
- **Step 2:** Hover the cursor directly over page card backgrounds, sacred artwork paintings, text paragraphs, and in-stream separator bars, and scroll up/down using the **mouse wheel** (`MOUSE_BUTTON_WHEEL_UP` / `MOUSE_BUTTON_WHEEL_DOWN`).
- **Expected:**
  - The 50-page stream scrolls smoothly up and down regardless of which child control is beneath the cursor (no child control swallows wheel events).
- **Step 3:** On a touchscreen (or using left-mouse-button click-and-drag on desktop), swipe/drag vertically up and down across page cards and separator buttons.
- **Expected:**
  - Swiping/dragging up (`relative.y < 0`) smoothly advances down the stream (`scroll_vertical` increases), and swiping/dragging down (`relative.y > 0`) scrolls back up toward Page 1 (`scroll_vertical` decreases).
  - Unpressed mouse hover motion (`button_mask == 0`) does not scroll the stream.
  - Interactive buttons inside `InStreamJumpBar` and `NavigationDrawer` (`mouse_filter = MOUSE_FILTER_PASS`) still respond to clicks/taps normally while allowing drag gestures to scroll.
- **Step 4:** Perform a fast vertical swipe / flick on a touch screen or fast left-mouse drag.
- **Expected:**
  - Scrolling smoothly glides through prayer pages with natural momentum, decelerating smoothly according to exponential friction until resting gently.
  - As pages pass through the viewport, texture virtualization dynamically loads active paintings and frees distant textures without stuttering.
- **Step 5:** During an active momentum glide, tap anywhere on the screen (or left-click with mouse).
- **Expected:**
  - Scrolling immediately halts at the exact tap position without jumping or rubber-banding.
  - Lifting the finger/mouse button without dragging does not trigger residual momentum.
- **Step 6:** Perform a high-velocity swipe / flick upward toward Page 1 or downward toward Page 50.
- **Expected:**
  - Scrolling strictly stops at stream boundaries (`scroll_vertical = 0` at top, `max_scroll` at bottom) without overshooting, bouncing, or residual drift.
- **Step 7:** Perform a slow drag and release without flicking (`velocity < 120` px/s or pausing > 150ms before releasing).
- **Expected:**
  - Scrolling stops immediately where the gesture ends, without any momentum drift.

### TC-SCROLL-02: In-Stream Mystery Set Jump Bar (After Page 5)
- **Step 1:** Scroll past Page 5 (The Opening Prayers).
- **Expected:**
  - An in-stream jump bar appears prompting *"Select a Mystery Set to Continue Praying:"* with 4 buttons: Joyful (Page 6), Luminous (Page 16), Sorrowful (Page 26), and Glorious (Page 36).
  - The liturgically recommended mystery set for today is visually accented with an antique gold border, gold tinted background, and a *"★ Recommended Today"* badge.
- **Step 2:** Click each mystery set button.
- **Expected:** The viewport smoothly scrolls directly to the targeted mystery set's opening page card.

### TC-SCROLL-03: In-Stream Closing Prayers Jump Bar (After Pages 15, 25, 35, 45)
- **Step 1:** Scroll to the conclusion of any mystery set (after Page 15 for Joyful, Page 25 for Luminous, Page 35 for Sorrowful, Page 45 for Glorious).
- **Expected:**
  - An in-stream separator bar appears indicating mystery set completion (e.g. *"End of the Five Joyful Mysteries"*).
  - A prominent crimson-accented action button labeled *"Proceed to the Closing Prayers →"* is visible.
- **Step 2:** Click *"Proceed to the Closing Prayers →"*.
- **Expected:** The viewport scrolls directly to Page 46 (*The Closing Prayers*).

### TC-SCROLL-04: Reading Progress Persistence Across App Restarts
- **Step 1:** Scroll or jump to a specific interior page (e.g. Page 26: The Agony in the Garden).
- **Step 2:** Close the application.
- **Step 3:** Relaunch the application.
- **Expected:**
  - The scroll position is automatically restored to Page 26 without requiring manual re-navigation.
  - Default on fresh installation (no `user://reading_progress.cfg`) starts at Page 1 (Front Cover).

### TC-SCROLL-05: Screen Keep-Awake Verification
- **Step 1:** Launch the application on a physical mobile device or display-enabled OS.
- **Step 2:** Leave the application open on a mystery prayer card for longer than the device's default display timeout (e.g., > 5 minutes).
- **Expected:**
  - The display does not dim or sleep during prayer contemplation (`DisplayServer.screen_set_keep_on(true)`).

## Test 7.0: Top-Right Navigation Drawer & Table of Contents

### TC-NAV-01: Floating Navigation Button & Drawer Toggling
- **Step 1:** Launch the application and observe the top-right corner of the viewport.
- **Expected:**
  - A persistent, unobtrusive floating button labeled `☰` (48×48px) is visible in the top-right corner.
- **Step 2:** Click or tap the floating button.
- **Expected:**
  - The navigation drawer smoothly slides into view from the right edge.
  - A semi-transparent dimming scrim (`#00000080`) darkens the background content.
  - Background scrolling is disabled (`ScrollContainer.mouse_filter = MOUSE_FILTER_IGNORE`).
- **Step 3:** Click anywhere on the dimmed scrim backdrop or press the `Escape` key (`ui_cancel`).
- **Expected:**
  - The drawer smoothly closes and the dimming scrim disappears.
  - Background scrolling is restored (`ScrollContainer.mouse_filter = MOUSE_FILTER_STOP`).

### TC-NAV-02: Resume Last Page Action & Reading Progress Synchronization
- **Step 1:** Scroll or jump to an interior mystery page (e.g., Page 16: *The Baptism of Jesus in the Jordan*).
- **Step 2:** Open the navigation drawer.
- **Expected:**
  - The top "Resume" button dynamically displays: *"Resume Last Page: The Baptism of Jesus in the Jordan (Page 16)"*.
- **Step 3:** Scroll to Page 1, open drawer, and click the Resume button.
- **Expected:**
  - The viewport scrolls smoothly to Page 16.
  - The drawer automatically closes upon clicking.

### TC-NAV-03: Top-Level Landmark Direct Jump Buttons
- **Step 1:** Open the navigation drawer.
- **Step 2:** Individually test clicking each landmark button:
  - `Front Cover (Page 1)`
  - `History of the Rosary (Page 2)`
  - `Structure & How to Pray (Page 3)`
  - `The Opening Prayers (Page 4)`
  - `The Closing Prayers (Page 46)`
  - `Sacred Artwork Credits (Page 48)`
  - `Back Cover (Page 50)`
- **Expected:**
  - Clicking any landmark button scrolls the continuous stream directly to that target page.
  - The navigation drawer automatically closes upon selection.

### TC-NAV-04: Expandable Mystery Set Accordions & Daily Liturgical Badge
- **Step 1:** Open the navigation drawer.
- **Step 2:** Inspect the 4 Mystery Set rows (`Joyful`, `Luminous`, `Sorrowful`, `Glorious`).
- **Expected:**
  - The mystery set recommended for today (e.g. Glorious on Wednesday, Sorrowful on Tuesday/Friday, Joyful on Monday/Saturday, Luminous on Thursday) displays an antique gold `[★ Today]` badge.
- **Step 3:** Click the left disclosure arrow (`▸`) on a collapsed mystery set (e.g. *The Sorrowful Mysteries*).
- **Expected:**
  - The arrow icon flips to `▾`.
  - The indented list of 5 individual mysteries expands beneath the set.
  - The drawer remains open and does not scroll the main view.
- **Step 4:** Click the disclosure arrow (`▾`) again.
- **Expected:**
  - The list collapses and the arrow returns to `▸` without closing the drawer.
- **Step 5:** Expand a mystery set (e.g. *The Glorious Mysteries*) and click an individual mystery button (e.g. *3. The Descent of the Holy Spirit*).
- **Expected:**
  - The continuous stream scrolls directly to Page 40.
  - The drawer automatically closes.
- **Step 6:** Re-open the drawer and click a mystery set title button directly (e.g. *The Joyful Mysteries*).
- **Expected:**
  - The continuous stream immediately navigates to the 1st Mystery of that set (Page 6).
  - The drawer automatically closes.


## Test 8.0: Application Launcher Icon & Boot Splash Screen

### TC-ICON-01: Desktop & Launcher App Icon
- **Step 1:** Build or inspect the application executable/launcher on desktop (taskbar / window header) or deploy to an Android device.
- **Expected:**
  - The application icon displays the 512×512 square crop of Murillo's *The Virgin of the Rosary*.
  - The faces of Mary and the Infant Jesus, their halos, and the rosary beads are clearly visible and well-composed without awkward clipping across circular, squircle, or rectangular launcher masks.

### TC-SPLASH-01: Startup Boot Splash Screen
- **Step 1:** Launch the application (`godot --path game` or run exported build).
- **Expected:**
  - During engine initialization, the full, uncropped cover painting (*The Virgin of the Rosary*) is displayed.
  - The splash screen background color displays the deep ambient espresso `#141010` (`Color(0.0784314, 0.0627451, 0.0627451, 1)`), seamlessly transitioning into the continuous scroll view.
