# Manual Testing Guide

This document outlines the strict manual testing procedures required before any release candidate can be deployed.

## Test 1.0: Launch & Boot
- **Step 1:** Open the app (`godot --path game`).
- **Expected:** The app boots cleanly without errors or crashes.

## Test 2.0: Typography & Font Rendering
- **Step 1:** Launch the application and observe any visible text (`Label`, `RichTextLabel`, and `Button` controls).
- **Expected:** 
  - Text renders using **EB Garamond** serif font across Regular and Bold styles (with Italic available in asset/theme fallbacks, but unused on page cards).
  - Characters appear crisp and legible without blurring, pixelation, distortion, or clipping at native and scaled resolutions.
  - Standard page card headers satisfy minimum font thresholds: `SubheadingLabel` $\ge 22\text{pt}$ (Garamond regular) and `HeadingLabel` $\ge 34\text{pt}$ (Garamond bold; $38\text{pt}$ on Cover and Back Cover).
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
  - Title **"PRAY THE ROSARY"** displays in warm gold serif typography at 38pt bold (`#D4AF37`), subtitle *"A Contemplative Visual Guide to the Twenty Mysteries"* in warm ivory at 22pt regular (`EBGaramond-Regular.ttf`, `#F7F2E7`), separated by an ornamental gold divider line.
  - Bartolomé Esteban Murillo's *The Virgin of the Rosary* (`cover.webp`) renders centered in an antique gold framed artwork container strictly below the header band (`expand_mode = EXPAND_IGNORE_SIZE`, `stretch_mode = STRETCH_KEEP_ASPECT_CENTERED`).
  - Zero text or typography elements overlap any portion of the painting (the Virgin Mary, the Christ Child, the rosary, and halo remain completely unobstructed).
  - Strictly no numerical page numbers appear.

### TC-PAGE-02: Front-Matter Text Cards (`Pages 2 & 3`)
- **Step 1:** Inspect Page 2 (*The History of the Holy Rosary*) and Page 3 (*Structure of This Book & How to Pray*).
- **Expected:**
  - Standardized 32px uniform margins (`margin_left`, `margin_right`, `margin_top`, `margin_bottom`).
  - 22pt regular subheading (`EBGaramond-Regular.ttf` in Warm Umber `#5C4338`), 34pt bold heading, and warm ivory parchment panels (`#FAF6EE`) with antique gold borders (`#B89130`).
  - Page 2 displays subheading *"Origins and Tradition of the Most Holy Rosary"*.
  - Calibrated typography auto-fitting based on character density (`total_chars <= 1650`):
    - Page 2 (1,622 chars): 25pt section headers and 22pt body paragraphs.
    - Page 3 (1,813 chars): 23pt section headers and 20pt body paragraphs.
  - Page 2 Section 2 (*St. Dominic & Preaching the Mysteries*) accurately notes: `"organized the Marian Psalter (the 150 Hail Marys) into fifteen decades"`.
  - Page 2 Section 3 (*Pope St. Pius V & The Twenty Mysteries*) accurately documents: `"...and in 1571 instituted the feast of Our Lady of Victory (renamed the Feast of Our Lady of the Rosary in 1573)."`
  - Page 3 Heading displays `"Structure of This Book & How to Pray"`, with subheading `"Praying with Scripture, Prayer, and Sacred Art"`.
  - Page 3 Section 1 (*How This Book Is Organized*) explicitly notes:
    - Group recitation guidance in the opening paragraph: lines printed in regular type are spoken by the leader and lines in bold are spoken by everyone together in unison.
    - Bible translation in the `"Left Page (Word & Prayer)"` bullet: `• Left Page (Word & Prayer): Displays the Mystery title, its spiritual fruit, a passage from Sacred Scripture (taken from the Catholic Public Domain Version of the Bible), a brief meditation, and the complete prayers for that decade.`
  - Page 3 Section 2 (*Step-by-Step Guide to Praying the Rosary*) displays `"2. The Decades (Tabs J, L, S, G):"` and explains praying either the five decades of the day's Mystery set or all four Mystery sets (twenty decades) back-to-back in chronological order (`Joyful, Luminous, Sorrowful, Glorious`) for a complete Rosary, with all three sections fitting comfortably inside the `720×1080` card with zero overflow.
  - Section containers size to natural content height (`sec_vbox` using `Control.SIZE_FILL`, with `SIZE_EXPAND` stripped) and `sections_container` dynamically calculates uniform separation across section gaps to evenly distribute leftover vertical space across the full 1080px canvas with zero text overflow or clipping.

### TC-PAGE-03: Prayer Sequence Cards (`Pages 4 & 46`)
- **Step 1:** Inspect Page 4 (*The Opening Prayers*) and Page 46 (*The Closing Prayers*).
- **Expected:**
  - Standardized 32px uniform margins, 22pt regular subheading, and 34pt bold heading. Prayer step rubrics render in 16–18pt upright regular typography (`EBGaramond-Regular.ttf`) in Warm Umber (`#5C4338`).
  - Page 4 displays exactly 5 introductory prayer steps formatted with 20pt prayer titles, 16pt rubrics, and 19pt body text, using the simplified titles `"The Our Father"` (Step 3) and `"The Glory Be"` (Step 5) without `"The Lord's Prayer"` or `"(Doxology)"`:
    - *The Sign of the Cross* renders entirely in bold-weight serif (`EBGaramond-Bold.ttf`) as a unison prayer.
    - *The Apostles' Creed*, *The Our Father*, three *Hail Marys for Faith, Hope, and Charity*, and *The Glory Be* render with regular leader text (`EBGaramond-Regular.ttf`) and bold group response (`EBGaramond-Bold.ttf`) stacked vertically on separate lines.
    - *The Glory Be* is rendered as a single unified sentence with a comma separating the invocatory clause from the lowercase group response (*"Glory be to the Father, and to the Son, and to the Holy Spirit,\nas it was in the beginning, is now, and ever shall be, world without end. Amen."*).
  - Page 46 displays 3 concluding prayer steps formatted with 24pt prayer titles, 18pt rubrics, and 23pt body text:
    - **Step 1 (*Hail, Holy Queen* with flowing *Versicle & Response*):** Rubric: *"After completing the decades, pray the Hail, Holy Queen (Salve Regina):"*. Recited in bold-weight serif (`EBGaramond-Bold.ttf`) as a unison prayer, followed immediately by the appended versicle and response without legacy `"V. "` and `"R. "` prefixes: leader versicle (*"Pray for us, O holy Mother of God."* in regular serif) and bold group response (*"That we may be made worthy of the promises of Christ."*).
    - **Step 2 (*Concluding Rosary Prayer*):** Rubric: *"Conclude with the Rosary Prayer:"*. Leader text (*"Let us pray."* in regular serif) followed by the collect prayer (*"O God, whose only begotten Son..."* in bold serif).
    - **Step 3 (*The Sign of the Cross*):** Rubric: *"End by making the Sign of the Cross:"*. Entire prayer rendered in bold-weight serif as a unison prayer.
  - Distinct muted umber rubric tags (e.g., `[1×]`, `[10×]`, `[Sign of the Cross]`) precede each prayer item.
  - Prayer step containers size to natural content height (`step_vbox` using `Control.SIZE_FILL`, with `SIZE_EXPAND` stripped) eliminating trailing blank space, while `steps_container` dynamically calculates uniform separation across all prayer step gaps to balance card height with zero vertical overflow.

### TC-PAGE-04: Mystery Prayer Cards (`Even Pages 6, 8, 10, ..., 44`)
- **Step 1:** Inspect all 20 Mystery Prayer Cards.
- **Expected:**
  - Standardized 32px uniform margins.
  - Header displays 22pt regular mystery ordinal (e.g., *The First Joyful Mystery* in Warm Umber `#5C4338`), 34pt bold title (e.g., **The Annunciation**), and 18pt regular fruit badge (*Fruit of the Mystery: <Virtue>*) in antique gold pill box.
  - Verify that each Mystery Prayer Card renders its standardized concise traditional USCCB spiritual fruit:
    - **Joyful Mysteries:** Page 6 (*Humility*), Page 8 (*Love of Neighbor*), Page 10 (*Poverty*), Page 12 (*Purity of Heart and Body*), Page 14 (*Devotion to Jesus*).
    - **Luminous Mysteries:** Page 16 (*Openness to the Holy Spirit*), Page 18 (*To Jesus through Mary*), Page 20 (*Conversion*), Page 22 (*Desire for Holiness*), Page 24 (*Adoration*).
    - **Sorrowful Mysteries:** Page 26 (*Obedience to God's Will*), Page 28 (*Mortification*), Page 30 (*Courage*), Page 32 (*Patience*), Page 34 (*Sorrow for Our Sins*).
    - **Glorious Mysteries:** Page 36 (*Faith*), Page 38 (*Hope*), Page 40 (*Wisdom*), Page 42 (*Devotion to Mary*), Page 44 (*Grace of a Happy Death*).
  - Scripture citation renders at 17pt bold with a gold vertical accent bar (displaying clean book, chapter, and verse citations without any trailing `" (CPDV)"` suffix), and scripture reading renders at 18–20pt regular serif (`EBGaramond-Regular.ttf`) enclosed in a gold-bordered container.
  - Verify canonical Catholic Public Domain Version (CPDV) citations, verbatim scripture passages, and contemplative meditations:
    - **Joyful 1 (`Page 6`):** Contemplative meditation reads: `"With humble surrender, the Blessed Virgin welcomes the Archangel Gabriel's message and conceives the Eternal Word by the power of the Holy Spirit."`
    - **Joyful 2 (`Page 8`):** Contemplative meditation reads: `"Bearing Christ within her, Mary hastens in charity to visit and care for her aged cousin Elizabeth, bringing sanctifying joy to the unborn John the Baptist."`
    - **Joyful 3 (`Page 10`):** Scripture passage includes opening clause: `"And the Angel said to them: \"Do not be afraid. For, behold, I proclaim to you a great joy, which will be for all the people:"`.
    - **Joyful 4 (`Page 12`):** Citation reads `"Luke 2:22, 28–32"` and Luke 2:28 uses bracketed subject `"[Then Simeon] took him up, into his arms"`.
    - **Luminous 1 (`Page 16`):** Contemplative meditation reads: `"Descending into the River Jordan to sanctify the waters of Baptism, Christ is anointed by the Holy Spirit and proclaimed the Beloved Son of the Eternal Father."`
    - **Luminous 3 (`Page 20`):** Contemplative meditation reads: `"Upon the Galilean hillside, Christ proclaims the Beatitudes, calling every soul to conversion of heart, merciful forgiveness, and childlike trust in the Father."`
    - **Luminous 4 (`Page 22`):** Citation reads `"Luke 9:29–31, 35"` with verbatim `"Moses and Elijah, appearing in majesty"`, verse 35 concludes with verbatim `"This is my beloved Son. Listen to him.\""`, and contemplative meditation reads: `"Upon the holy mountain, the divine glory of God shines forth from the face of Christ, strengthening His Apostles for the coming Passion and revealing our call to transfiguring grace."`.
    - **Luminous 5 (`Page 24`):** Contemplative meditation reads: `"Having loved His own unto the end, Christ offers His Body, Blood, Soul, and Divinity, under the appearances of bread and wine, to remain truly, really, and substantially present with His Church forever."`
    - **Sorrowful 2 (`Page 28`):** Citation reads `"John 19:1; Isaiah 53:5"`, beginning with `"Therefore, Pilate then took Jesus into custody and scourged him..."`, containing `"The discipline of our peace was upon him. And by his wounds, we are healed."`, and contemplative meditation reads: `"Bound to the pillar in silence, the innocent Lamb of God endures cruel blows in reparation for our sins and to heal our wounded human nature."`.
    - **Sorrowful 4 (`Page 32`):** Citation order reads `"John 19:17; Luke 23:26–27"`, matching the sequence of quoted verses, and contemplative meditation reads: `"Falling beneath the heavy wood along the way to Calvary, Christ exchanges a look of piercing love with His grieving Mother, inviting us to take up our daily cross after Him."`.
    - **Sorrowful 5 (`Page 34`):** Citation reads `"Luke 23:33–34, 46"` and Luke 23:46 reads verbatim `"And Jesus, crying out with a loud voice, said: \"Father, into your hands I commend my spirit.\" And upon saying this, he expired."`.
    - **Glorious 1 (`Page 36`):** Contemplative meditation reads: `"At dawn on the third day, Christ bursts the bonds of death and rises in radiant majesty, opening the gates of eternal life to all who believe in Him."`.
    - **Glorious 2 (`Page 38`):** Citation `"Luke 24:50–52; Acts 1:9"` separates Luke 24:50–52 and Acts 1:9 in canonical order with ellipses: `"Then he led them out as far as Bethania. And lifting up his hands, he blessed them. And it happened that, while he was blessing them, he withdrew from them, and he was carried up into heaven. And worshiping, they returned to Jerusalem with great joy... And when he had said these things, while they were watching, he was lifted up, and a cloud took him from their sight."`.
    - **Glorious 4 (`Page 42`):** Citation reads `"Psalm 131:8 (132:8); Luke 1:48–49; Judith 15:10"`, with verbatim CPDV passages: `"Rise up, O Lord, into your resting place. You and the ark of your sanctification... For behold, from this time, all generations shall call me blessed. For he who is great has done great things for me, and holy is his name... You are the glory of Jerusalem, you are the joy of Israel, you are the honor of our people."`.
    - **Glorious 5 (`Page 44`):** Citation reads `"Revelation 12:1; Sirach 24:7"`, beginning with `"And a great sign appeared in heaven: a woman clothed with the sun,"` and concluding with `"and my throne is in the pillar of a cloud."`.
  - Contemplative meditation renders at 20–22pt regular text.
  - Decade prayers (*The Our Father* with rubric `"1× The Our Father"`, *The Hail Mary* with rubric `"10× The Hail Mary"`, *The Glory Be* with rubric `"1× The Glory Be"`, and *The Fatima Prayer* with rubric `"1× The Fatima Prayer"`) render with 17–18pt bold rubrics and 20–22pt prayer text:
    - *The Our Father*, *The Hail Mary*, and *The Glory Be* split into regular leader text (`EBGaramond-Regular.ttf`) and bold group response (`EBGaramond-Bold.ttf`) on a new line.
    - *The Glory Be* is formatted as a single continuous sentence with a comma terminating the leader line and a lowercase response clause (*"Glory be to the Father, and to the Son, and to the Holy Spirit,\nas it was in the beginning, is now, and ever shall be, world without end. Amen."*).
    - *The Fatima Prayer* is rendered entirely in bold-weight serif (`EBGaramond-Bold.ttf`) as a unison prayer using canonical traditional wording: *"O my Jesus, forgive us our sins, save us from the fires of hell, lead all souls to Heaven, especially those in most need of Thy mercy. Amen."*.
  - High-density passages (e.g., Page 40 Pentecost with 1,326 chars) auto-fit cleanly to 20pt body / 18pt scripture / 17pt rubrics, guaranteeing zero internal scrolling and zero vertical overflow on the 720×1080 canvas.
  - Decade prayer item containers size to natural content height (`p_vbox` using `Control.SIZE_FILL` without `SIZE_EXPAND`), and `decade_prayers_container` dynamically calculates uniform separation across all prayer gaps, eliminating empty trailing voids after shorter prayers like *The Glory Be*.

### TC-PAGE-05: Sacred Artwork Cards (`Odd Pages 5, 7, 9, ..., 47`)
- **Step 1:** Inspect all 22 Artwork Cards (Opening, 20 Mysteries, Closing).
- **Expected:**
  - Standardized 32px uniform margins.
  - Top header band displays the mystery ordinal subheading at 22pt regular serif (`EBGaramond-Regular.ttf`) and mystery title at 34pt bold.
  - Painting renders centered inside the antique gold border (`#B89130`) preserving original aspect ratio.
  - Strictly **NO captions** (artist, museum, date) and **NO numerical page numbers** appear on the artwork card.

### TC-PAGE-06: Credits & Back Cover Cards (`Pages 48, 49, & 50`)
- **Step 1:** Inspect Pages 48 and 49 (*Sacred Artwork Credits Parts I & II*) and Page 50 (*Back Cover*).
- **Expected:**
  - 32px horizontal / 22px vertical margins, 22pt regular subheading, and 34pt bold heading on Pages 48 and 49.
  - Page 48 (`"Front Cover, Opening Prayers, Joyful Mysteries & Luminous Mysteries"`) lists 12 attributions in exact sequential book appearance order (Front Cover, Opening Prayers, Joyful Mysteries 1–5, and Luminous Mysteries 1–5) at 16pt bold title (`"%s — %s" % [section_label, art_title]`, with `AUTOWRAP_WORD_SMART` and zero page numbers) and 14pt regular details with natural item heights (`art_vbox` using `Control.SIZE_FILL` without `SIZE_EXPAND`) and dynamically calculated uniform separation on `credits_container`, including updated creation dates for Ricci's *The Marriage at Cana* (`c. 1712–1715`) and Rubens's *The Last Supper* (`1631–1632`).
  - Page 48 renders a thin antique gold horizontal divider line (`ColophonDivider`) and bottom colophon block (`ColophonContainer`) displaying `"This edition of “Pray The Rosary” was created and is maintained by Kevin Audrain."` and `"Version 0.1.3"` (dynamically read from `application/config/version`) in upright `EBGaramond-Regular.ttf` in Deep Umber `#5C4338`, with scripture and artwork notices hidden.
  - Page 49 (`"Sorrowful Mysteries, Glorious Mysteries, Closing Prayers & Text Sources"`) lists 11 attributions in exact sequential book appearance order (Sorrowful Mysteries 1–5, Glorious Mysteries 1–5, and Closing Prayers last, ending with `"Closing Prayers — The Immaculate Conception of Los Venerables (Inmaculada de Soult)"`) at 16pt bold title (`"%s — %s" % [section_label, art_title]`) and 14pt regular details—including Maíno's *Pentecost* (`1612–1614`), Murillo's *The Assumption of the Virgin* at `State Hermitage Museum, St. Petersburg, Russia`, and Velázquez's *The Coronation of the Virgin* (`c. 1635–1636`)—plus the Catholic Public Domain Version (CPDV) Scripture notice (13pt regular in `EBGaramond-Regular.ttf`, matching the colophon notice) and museum colophon (13pt regular) with natural item heights (`Control.SIZE_FILL`), dynamically calculated uniform separation on `credits_container`, zero clipping or vertical overflow, and creator/version lines hidden.
  - Page 50 displays deep Baroque crimson (`#4A1215`) card with 38pt title in warm gold, 22pt regular subtitle in warm ivory (`EBGaramond-Regular.ttf`), Pope St. John Paul II's epigraph in 22pt regular with 17pt attribution enclosed in a subtle gold-bordered callout box (`PanelContainer` with `1px` gold border `#D4AF37` at `0.55` alpha, subtle deep crimson fill `#380D10`, and `14px/12px` padding), 20pt body synopsis, and St. Louis Marie de Montfort's full verbatim Marian counsel from *The Secret of the Rosary* (25th Rose) in 22pt regular with 17pt attribution enclosed in a matching gold-bordered callout box, natural block heights (`Control.SIZE_FILL` without `SIZE_EXPAND`), and dynamically calculated uniform vertical separation (~158px inter-block separation on Normal preset) across `main_vbox` with zero vertical overflow.
- **Step 2:** Navigate to Page 48 and cycle through `Normal`, `Mobile`, and `Extra Large` text presets using the top-left `"AA"` reader button.
- **Expected:**
  - On `Normal` preset, Page 48 displays all 12 credits, the thin gold divider, `"This edition of “Pray The Rosary” was created and is maintained by Kevin Audrain."`, and `"Version 0.1.3"` within the canonical 1080px height with zero vertical overflow.
  - On `Mobile` preset, colophon notice typography scales cleanly to 18pt and Page 48 dynamically elongates beyond 1080px with both notice lines fully visible and zero truncation.
  - On `Extra Large` preset, colophon notice typography scales cleanly to 23pt and Page 48 further elongates beyond 1080px with both notice lines fully visible and zero vertical or horizontal clipping.

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
- **Step 4:** Perform a fast vertical swipe / flick on a physical mobile touchscreen, simulated touch mode, or fast left-mouse drag flick on Desktop (with `pointing/emulate_touch_from_mouse` active).
- **Expected:**
  - Scrolling smoothly glides through prayer pages with natural momentum without sudden stop or collision on release, gliding across 1.5 to 3+ portrait page cards over 1.5–2.5 seconds and decelerating smoothly according to exponential friction until resting gently.
  - Device emulation events (`DEVICE_ID_EMULATION`) and native `ScrollContainer` touch tracking do not collide with custom momentum physics or truncate velocity samples, ensuring both mouse flicks and touch swipes glide freely.
  - Purely horizontal micro-movement jitter immediately prior to finger lift or mouse release does not zero the rolling velocity or suppress flick momentum.
  - As pages pass through the viewport, texture virtualization dynamically loads active paintings and frees distant textures without stuttering.
- **Step 5:** During an active momentum glide, tap anywhere on the screen (or left-click with mouse).
- **Expected:**
  - Scrolling immediately halts at the exact tap position without jumping or rubber-banding.
  - Lifting the finger/mouse button without dragging does not trigger residual momentum.
- **Step 6:** Perform a high-velocity swipe / flick upward toward Page 1 or downward toward Page 50.
- **Expected:**
  - Scrolling strictly stops at stream boundaries (`scroll_vertical = 0` at top, `max_scroll` at bottom) without overshooting, bouncing, or residual drift.
- **Step 7:** Perform a slow drag and release without flicking (`velocity < 100` px/s or pausing > 150ms before releasing).
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

### TC-SCROLL-04: Exact Reading Position & Lifecycle Persistence Across App Restarts
- **Step 1:** Scroll or navigate to an interior prayer page (e.g., Page 6: *The Annunciation* or Page 26: *The Agony in the Garden*) and scroll partway down the card (e.g., halfway through the decade prayers).
- **Step 2:** Minimize or background the application (triggering `NOTIFICATION_APPLICATION_PAUSED` / focus loss) or close the application window completely.
- **Step 3:** Relaunch the application (`godot --path game`).
- **Expected:**
  - The application immediately restores to the exact vertical reading position and scroll offset (`last_scroll_vertical`), rather than resetting to the top of the card or drifting.
- **Step 4:** Scroll all the way back to the very top of Page 1 (Front Cover, `scroll_vertical = 0`), then close or background the application.
- **Step 5:** Relaunch the application.
- **Expected:**
  - The application opens strictly at the very top of Page 1 (`scroll_vertical = 0`).
- **Step 6:** Launch on a fresh installation or with a missing/corrupted `user://reading_progress.cfg`.
- **Expected:**
  - The application falls back cleanly to Page 1 at `scroll_vertical = 0`.

### TC-SCROLL-05: Screen Keep-Awake Verification
- **Step 1:** Launch the application on a physical mobile device or display-enabled OS.
- **Step 2:** Leave the application open on a mystery prayer card for longer than the device's default display timeout (e.g., > 5 minutes).
- **Expected:**
  - The display does not dim or sleep during prayer contemplation (`DisplayServer.screen_set_keep_on(true)`).

### TC-SCROLL-06: Tall Mobile Aspect Ratio Startup & Zero Scroll Drift
- **Step 1:** Launch the application in a tall mobile aspect ratio window (e.g. 720×1440 [18:9], 720×1560 [19.5:9], or 720×1600 [20:9]).
- **Expected:**
  - On initial launch (or after clearing progress), the app starts strictly at the very top of Front Cover (Page 1, `scroll_vertical = 0`), displaying the dedicated top header band and framed Murillo artwork.
  - Zero downward scroll drift or ratcheting occurs during engine and layout startup; the viewport does not glide down toward later pages or get stuck on the Back Cover.
- **Step 2:** Navigate to an interior page (e.g. Page 10: *The Nativity*), close the application, and relaunch in the tall aspect ratio window.
- **Expected:**
  - The app restores stably to Page 10 without any layout inflation drift across repeated launches.

## Test 7.0: Top-Right Navigation Drawer & Table of Contents

### TC-NAV-01: Floating Navigation Button & Drawer Toggling
- **Step 1:** Launch the application and observe the top-right corner of the viewport.
- **Expected:**
  - A persistent, unobtrusive floating button ($52\times 52\text{px}$, pinned at offsets `left: -70, top: 18, right: -18, bottom: 70`) labeled `☰` is visible in the top-right corner.
  - The hamburger menu icon (`☰`, `U+2630`) appears optically and geometrically centered within its 52×52 parchment circular-rectangular button across default and hover states with balanced margins on all sides.
- **Step 2:** Hover over and click or tap the floating button.
- **Expected:**
  - Hovering over the button transitions its stylebox smoothly while preserving exact glyph centering.
  - The navigation drawer smoothly slides into view from the right edge.
  - A semi-transparent dimming scrim (`#00000080`) darkens the background content.
  - Background scrolling is disabled and floating reader button is disabled (`reader_button.mouse_filter = MOUSE_FILTER_IGNORE`, `ScrollContainer.mouse_filter = MOUSE_FILTER_IGNORE`).
- **Step 3:** Click anywhere on the dimmed scrim backdrop or press the `Escape` key (`ui_cancel`).
- **Expected:**
  - The drawer smoothly closes and the dimming scrim disappears.
  - Background scrolling and reader button interactivity are restored (`reader_button.mouse_filter = MOUSE_FILTER_STOP`, `ScrollContainer.mouse_filter` maintains `MOUSE_FILTER_IGNORE`).

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

## Test 9.0: Global Dynamic Text Sizing & Accessibility Reader Controls

### TC-TEXT-01: Dual-Sized 'AA' Reader Button UI & Dynamic Preset Feedback Toast
- **Step 1:** Launch the application (`godot --path game`) and observe the top-left corner of the viewport.
- **Expected:**
  - A persistent, unobtrusive floating button ($52\times 52\text{px}$) is visible at offset $(18, 18)$ on CanvasLayer 10.
  - The button is styled with a warm ivory parchment background (`#FAF6EE`), a 2px antique gold border (`#B89130`), 8px rounded corners, and subtle drop shadow.
  - **Dual-Sized 'AA' Icon:** Rather than a uniform single "Aa" label, the button displays two side-by-side capital 'A's (`SmallALabel` at 16pt bold on the left, `LargeALabel` at 26pt bold on the right) centered in an `IconHBox` with 1px separation.
  - **Color State Transitions:** The 'AA' labels render in Deep Charcoal (`#1E1815`) in the normal state, and shift to Sacred Crimson (`#6B1D21`) on mouse hover and button press, matching the button's gold-to-crimson border transitions.
- **Step 2:** Click or tap the dual-sized `"AA"` button once.
- **Expected:**
  - Text size preset switches from `Normal` to `Mobile`.
  - A top-centered toast banner (`PresetToast`) appears with text `"Text Size: Mobile"` dynamically rendered at **30pt** font size.
  - The toast resizes dynamically with symmetric horizontal offsets (`offset_left = -min_size.x * 0.5`, `offset_right = min_size.x * 0.5`) relative to horizontal center anchors (`anchor_left = anchor_right = 0.5`), maintaining exact horizontal centering ($x = 360\text{px}$ on 720px viewport) perfectly balanced between the top-left `"AA"` reader button and top-right navigation drawer menu button (`☰`) without rightward drift or text clipping, lingering for ~1.2s before fading out over 0.4s.
- **Step 3:** Click or tap the dual-sized `"AA"` button a second time.
- **Expected:**
  - Text size preset switches from `Mobile` to `Extra Large`.
  - A top-centered toast banner appears with text `"Text Size: Extra Large"` dynamically rendered at **38pt** font size.
  - The toast expands symmetrically around the horizontal center anchor ($x = 360\text{px}$) with symmetric offsets (`offset_left == -offset_right`), remaining dead-center between the top-left reader button and top-right navigation drawer menu button without clipping, and fades out after ~1.2s.
- **Step 4:** Click or tap the dual-sized `"AA"` button a third time.
- **Expected:**
  - Text size preset wraps sequentially back to `Normal`.
  - A top-centered toast banner appears with text `"Text Size: Normal"` dynamically rendered at **22pt** font size.
  - The toast scales down symmetrically with symmetric offsets (`offset_left == -offset_right`), remaining perfectly centered horizontally ($x = 360\text{px}$) between the top-left reader button and top-right navigation drawer menu button, and fades out after ~1.2s.
- **Step 5:** Open the navigation drawer (top-right `☰` button).
- **Expected:**
  - While the navigation drawer is open, clicking or tapping on the `"AA"` button area does not cycle text size presets (`reader_button.mouse_filter = MOUSE_FILTER_IGNORE`).
  - Closing the drawer restores normal interactivity (`MOUSE_FILTER_STOP`).

### TC-TEXT-02: Text Size Scaling & Dynamic Card Elongation
- **Step 1:** Scroll to an interior prayer page (e.g. Page 4 *The Opening Prayers*, Page 6 *The Annunciation*, or Page 48 *Sacred Artwork Credits*).
- **Step 2:** Observe font sizes and card height under the `Normal` preset.
- **Expected:**
  - Card height fits cleanly within the standard $720\times 1080$ ($2:3$) portrait dimensions.
  - No text is truncated or clipped; no internal scrollbars appear.
- **Step 3:** Tap the `"AA"` reader button to switch to the `Mobile` preset.
- **Expected:**
  - Headings, subheadings, fruit badges, scripture citations, prayer titles, rubrics, and body text visibly increase in size (e.g. body text scales from ~22pt to ~31–33pt).
  - The card dynamically expands vertically beyond 1080px (`custom_minimum_size.y > 1080px`) to comfortably accommodate the larger typography.
  - All text remains fully visible without truncation or internal scrollbars.
- **Step 4:** Tap the `"AA"` reader button to switch to the `Extra Large` preset.
- **Expected:**
  - Typography scales further (e.g. body text scales to ~40–44pt, headings up to 44pt).
  - The card elongates even further vertically to accommodate the high-visibility typography.
  - All text remains completely legible and unclipped.

### TC-TEXT-03: Sacred Artwork Aspect Ratio Preservation
- **Step 1:** Scroll to an artwork page (e.g. Page 5 *Opening Prayers Artwork*, Page 7 *The Annunciation Painting*, or Page 23 *The Transfiguration Painting*) or the Front/Back Covers (Page 1 or Page 50).
- **Step 2:** Cycle through all 3 text size presets (`Normal` -> `Mobile` -> `Extra Large`).
- **Expected:**
  - Sacred artwork cards and cover cards strictly preserve their rigid 2:3 ($720\times 1080$) portrait aspect ratio across all presets.
  - Artwork cards and cover cards do NOT elongate vertically (`custom_minimum_size = Vector2(720, 1080)`, `ratio = 2.0 / 3.0`).
  - Paintings remain centered within their antique gold borders without distortion, stretching, or cropping.

### TC-TEXT-04: Viewport Scroll Anchor Stability
- **Step 1:** Scroll into the middle of a mystery prayer card (e.g. Page 26 *The Agony in the Garden*) so that the meditation or decade prayers are centered in the viewport.
- **Step 2:** Tap the `"AA"` reader button to change the text size preset (`Normal` -> `Mobile` -> `Extra Large`).
- **Expected:**
  - As the text-heavy cards expand or shrink throughout the stream, the viewport scroll position smoothly re-anchors to keep the currently viewed content centered in the viewport.
  - The user does not jump disorientingly to the top or bottom of the book, nor lose their place within the decade.

### TC-TEXT-05: Preset Persistence Across Restarts
- **Step 1:** Tap the `"AA"` reader button to select `Mobile` or `Extra Large` preset.
- **Step 2:** Close the application completely.
- **Step 3:** Relaunch the application (`godot --path game`).
- **Expected:**
  - The application restores the previously selected text size preset on launch from `user://reading_progress.cfg` (`[reading_progress]` section, `text_size_preset` key).
  - Text-heavy cards immediately render with the chosen font scaling without requiring the user to cycle presets again.

### TC-TEXT-06: Strict 720px Card Width Constraint & Header/FruitBadge Text Wrapping Across Presets
- **Step 1:** Tap the `"AA"` reader button to switch to the `Extra Large` text preset.
- **Step 2:** Scroll through the continuous stream and inspect text cards with titles and fruit tags:
  - Page 8 (The Second Joyful Mystery: *The Visitation* / *Fruit of the Mystery: Love of Neighbor*).
  - Page 10 (The Third Joyful Mystery: *The Nativity* / *Fruit of the Mystery: Poverty*).
  - Page 12 (The Fourth Joyful Mystery: *The Presentation in the Temple* / *Fruit of the Mystery: Purity of Heart and Body*).
  - Page 26 (The First Sorrowful Mystery: *The Agony in the Garden* / *Fruit of the Mystery: Obedience to God's Will*).
  - Page 28 (The Second Sorrowful Mystery: *The Scourging at the Pillar* / *Fruit of the Mystery: Mortification*).
  - Page 44 (The Fifth Glorious Mystery: *The Coronation of the Blessed Virgin Mary* / *Fruit of the Mystery: Grace of a Happy Death*).
  - Page 48 & Page 49 (*Sacred Artwork Credits Parts I & II*).
- **Expected:**
  - **Zero Horizontal Expansion:** All page cards remain strictly constrained to a maximum width of 720px (`custom_minimum_size.x = 720.0` and `combined_minimum_size.x <= 720.0`). The scroll stream does not shift rightward or introduce horizontal panning.
  - **Clean Multiline Header Wrapping:** Long headings (e.g. *The Scourging at the Pillar*, *Sacred Artwork Credits (Part I)*) and subheadings wrap cleanly onto two or more lines without clipping or overflowing their container boundaries (`autowrap_mode = TextServer.AUTOWRAP_WORD_SMART`).
  - **Dynamic Fruit Badge Clamping:**
    - Short single-word fruit badges (e.g. Page 6: *Fruit of the Mystery: Humility*, Page 10: *Fruit of the Mystery: Poverty*, Page 28: *Fruit of the Mystery: Mortification*, Page 36: *Fruit of the Mystery: Faith*, Page 38: *Fruit of the Mystery: Hope*, Page 40: *Fruit of the Mystery: Wisdom*) remain tightly shrink-wrapped and centered horizontally in their gold pill container (`size_flags_horizontal = SIZE_SHRINK_CENTER`).
    - Compound fruit badges (e.g. Page 12: *Fruit of the Mystery: Purity of Heart and Body*, Page 26: *Fruit of the Mystery: Obedience to God's Will*, Page 44: *Fruit of the Mystery: Grace of a Happy Death*) fit cleanly on a single line on standard presets and wrap gracefully under enlarged accessibility presets (`extra_large`) without expanding past the maximum content width (628px), preserving the pill box styling and keeping card width strictly at 720px.
  - **Interior Scripture Frame Border:** The 1px interior scripture frame border (`ScriptureContainer`) on Mystery Prayer Cards remains completely visible with 10px internal margins and zero lateral cutoff.
  - **Symmetrical Lateral Margins:** Symmetrical 32px margins (left and right) are preserved uniformly across all 50 cards under all presets.

### TC-TEXT-07: Uniform Vertical Spacing Across Multi-Item Text and Prayer Pages
- **Step 1:** In `Normal` text size preset, inspect all 27 multi-item text and prayer pages:
  - Front Matter: Page 2 (*The History of the Holy Rosary*) and Page 3 (*Structure of This Book & How to Pray*).
  - Prayer Sequences: Page 4 (*The Opening Prayers*) and Page 46 (*The Closing Prayers*—3-step sequence with flowing Versicle & Response).
  - Mystery Decade Pages: Pages 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34, 36, 38, 40, 42, 44.
  - Credits: Page 48 (*Sacred Artwork Credits Part I*) and Page 49 (*Credits Part II & Colophon*).
  - Back Cover: Page 50.
- **Expected:**
  - **Elimination of Trailing Blank Space:** Child item containers (`sec_vbox`, `step_vbox`, `p_vbox`, `art_vbox`, `EpigraphContainer`, `SynopsisLabel`, `CounselContainer`) have vertical `SIZE_EXPAND` stripped and configure `Control.SIZE_FILL`, strictly sizing each child to its natural content height without artificial trailing empty margins or voids.
  - **Uniform Inter-Item Gaps:** Leftover vertical space is distributed evenly across all $N - 1$ inter-item gaps on parent containers (`sections_container`, `steps_container`, `decade_prayers_container`, `credits_container`, `main_vbox`). Adjacent visual gaps between items are strictly uniform (`max_gap - min_gap <= 2.0px`).
  - **Canonical Height Budget:** Under `Normal` preset, all 27 multi-item cards fit cleanly within the canonical $\le 1080.0\text{px}$ card height with zero internal scrollbars, zero text truncation, and zero vertical overflow.
  - **Harmonious Visual Balance:**
    - On Page 4, the 5 opening prayer steps are spaced evenly without an unnatural void after the short *Sign of the Cross*.
    - On Pages 6–44 (even), the 4 decade prayers (*The Our Father*, *The Hail Mary*, *The Glory Be*, *The Fatima Prayer*) are separated by uniform ~27px gaps, eliminating the blank ~80px void previously seen after *The Glory Be*.
    - On Page 46, the 3 closing prayer steps (with Step 1 flowing from the *Salve Regina* to the appended versicle and response) are balanced evenly across the canvas.
    - On Page 50, header, epigraph, synopsis, and counsel blocks are evenly distributed across the 1080px canvas with uniform ~158px inter-block separation.
- **Step 2:** Switch to `Mobile` (`1.45x`) and `Extra Large` (`1.9x`) presets and inspect multi-item cards.
- **Expected:**
  - Consistent uniform inter-item spacing is maintained while text-heavy cards smoothly elongate vertically beyond 1080px without label collisions, truncation, or clipping.
  - Back Cover (Page 50) maintains its locked 2:3 aspect ratio (`720x1080`).

## Test 10.0: Group Recitation & Leader/Response Typography

### TC-LEAD-01: Page 4 Opening Prayers Leader and Group Response Formatting
- **Step 1:** Navigate to Page 4 (*The Opening Prayers*).
- **Step 2:** Inspect the typography of each of the 5 prayer steps:
  1. *The Sign of the Cross*: Rendered entirely in bold-weight Garamond (`EBGaramond-Bold.ttf`) as a unison prayer.
  2. *The Apostles' Creed*: Opening section through `"...from there he will come to judge the living and the dead."` (verifying modern liturgical phrasing: *"on the third day he rose again from the dead. He ascended into heaven, and is seated at the right hand of God the Father Almighty; from there he will come to judge the living and the dead."*) renders in regular Garamond (`EBGaramond-Regular.ttf`) as leader text; canonical response section starting `"I believe in the Holy Spirit, the holy Catholic Church..."` renders in bold Garamond (`EBGaramond-Bold.ttf`) on a new line.
  3. *The Our Father*: Opening section through `"...on earth as it is in heaven."` renders in regular Garamond; response section starting `"Give us this day our daily bread..."` renders in bold Garamond on a new line.
  4. *Three Hail Marys (Faith, Hope, Charity)*: Opening clause through `"...and blessed is the fruit of thy womb, Jesus."` renders in regular Garamond; response section starting `"Holy Mary, Mother of God, pray for us sinners..."` renders in bold Garamond on a new line.
  5. *The Glory Be*: Invocatory clause (*"Glory be to the Father, and to the Son, and to the Holy Spirit,"*) terminates with a comma and renders in regular Garamond; response clause (*"as it was in the beginning, is now, and ever shall be, world without end. Amen."*) renders in bold Garamond on a new line in lowercase continuation.
- **Expected:**
  - Distinct vertical stacking between leader (regular) and response (bold) labels.
  - Zero text overlap or line collisions.
  - Card fits comfortably within standard 1080px height budget under `Normal` preset.

### TC-LEAD-02: Mystery Prayer Pages (6, 8, ..., 44) Decade Prayers Typography
- **Step 1:** Navigate to any Mystery Prayer page (e.g. Page 6: *The Annunciation*, Page 20: *The Wedding at Cana*, Page 26: *The Agony in the Garden*, or Page 40: *The Descent of the Holy Spirit*).
- **Step 2:** Inspect the 4 decade prayers:
  1. *1× The Our Father*: Regular leader text followed by bold group response on a new line.
  2. *10× The Hail Mary*: Regular leader text followed by bold group response on a new line.
  3. *1× The Glory Be*: Regular leader invocatory clause ending with a comma, followed by bold lowercase group response on a new line.
  4. *1× The Fatima Prayer*: Entire prayer rendered in bold Garamond (`EBGaramond-Bold.ttf`) with leader text hidden (`PrayerText.visible = false`), verifying wording: *"O my Jesus, forgive us our sins, save us from the fires of hell, lead all souls to Heaven, especially those in most need of Thy mercy. Amen."*.
- **Expected:**
  - Clear visual demarcation between leader recitation and communal group response.
  - All 20 mystery prayer cards display identical, consistent styling.
  - Total card height fits strictly within 1080px under `Normal` preset with zero internal scrolling.

### TC-LEAD-03: Page 46 Closing Prayers Leader and Group Response Formatting
- **Step 1:** Navigate to Page 46 (*The Closing Prayers*).
- **Step 2:** Inspect the 3 concluding prayer steps:
  1. *Hail, Holy Queen / Salve Regina* with flowing *Versicle & Response*:
     - *Hail, Holy Queen* renders entirely in bold Garamond (`EBGaramond-Bold.ttf`) as a unison prayer.
     - Appended immediately beneath within Step 1 is the *Versicle & Response* without legacy liturgical prefixes (`"V. "` and `"R. "`): Versicle (*"Pray for us, O holy Mother of God."*) renders in regular leader type (`EBGaramond-Regular.ttf`); Response (*"That we may be made worthy of the promises of Christ."*) renders in bold group response type (`EBGaramond-Bold.ttf`) on a new line.
  2. *Concluding Rosary Prayer*: Leader text (*"Let us pray."*) renders in regular Garamond; collect prayer (*"O God, whose only begotten Son, by his life, death, and resurrection..."*) renders in bold Garamond on a new line.
  3. *The Sign of the Cross*: Rendered entirely in bold Garamond as a unison prayer.
- **Expected:**
  - Clean, modern liturgical typography without clutter or manuscript abbreviations.
  - Step 1 flows seamlessly from the *Salve Regina* to the versicle and group response.
  - Card fits cleanly within 1080px under `Normal` preset with uniform vertical spacing across all 3 steps.

### TC-LEAD-04: Typography Scaling Across Text Presets for Leader and Response
- **Step 1:** Navigate to Page 4, Page 6, or Page 46.
- **Step 2:** Cycle the dual-sized `"AA"` reader button from `Normal` to `Mobile` and then `Extra Large`.
- **Expected:**
  - Both leader (`PrayerText`, `VersicleLeaderText`) and response (`ResponseText`, `VersicleResponseText`) labels scale uniformly using identical point sizes across all presets.
  - Line breaks and vertical spacing between leader and response remain crisp and proportional.
  - Dynamic vertical card elongation occurs smoothly under `Mobile` and `Extra Large` without clipping, truncation, or lateral drift.

## Test 11.0: Canonical References & Source Verification Ledger

### TC-REF-01: References Document Existence and AI Verification Rules
- **Step 1:** Confirm the existence of `documents/references.md` and `.agents/rules/references_verification.md` in the workspace.
- **Expected:**
  - Both files exist and are non-empty.
  - `documents/references.md` opens with a dedicated **AI Agent Verification & Fact-Checking Rules** section specifying authoritative primary source requirements (Vatican, USCCB, DRBO, official museum catalogs) and zero-tolerance hallucination constraints.
  - `.agents/rules/references_verification.md` specifies strict requirements for subagents to consult `documents/references.md` before making any text or attribution changes and to maintain mutual synchronization across data files.

### TC-REF-02: Strict 50-Page Book Order Sequence
- **Step 1:** Inspect the table of contents and section headings in `documents/references.md`.
- **Expected:**
  - Sections strictly follow sequential book order from `### Page 1` through `### Page 50`.
  - Every page card type (Cover, History, Guide, Opening Prayers, 20 Mysteries, Closing Prayers, Credits Parts I & II, Back Cover) is documented with its corresponding prayers, Scripture citations, meditations, and artwork metadata in exact order.

### TC-REF-03: Primary Source Citations and Verifiable External Hyperlinks
- **Step 1:** Verify the external source citations and hyperlinks documented in `documents/references.md`.
- **Expected:**
  - Prayers cite canonical texts from authoritative Catholic repositories (e.g., `vatican.va`, `usccb.org`, `newadvent.org`).
  - All 20 mystery Scripture passages cite the public-domain Catholic Public Domain Version (CPDV) with primary source links to `sacredbible.org` and GitHub `draino7n7/cpdv` (alongside comparative DRBO chapter links).
  - All 23 master artworks include exact museum inventory numbers, creation dates, current institutions, master filenames in `assets/2D/gimp/original_downloads/`, and direct catalog hyperlinks (e.g., `museodelprado.es`, `nationalgallery.org.uk`, `khm.at`, State Hermitage Museum).
  - All citations follow consistent numbered footnote references (`[Reference 1]`, `[Reference 2]`, etc.).

### TC-REF-04: Hyperlink Integrity, Markdown URL Encoding & Automated Verification Suite
- **Step 1:** Run the headless Godot test suite from the repository root:
  ```powershell
  godot --headless --path game -s res://tests/test_runner.gd
  ```
- **Step 2:** Confirm that `test_references_document_completeness_and_book_order` in `game/tests/test_rosary_data.gd` passes with zero errors:
  - Asserts that all Markdown link URLs in `documents/references.md` contain zero unescaped parentheses `(` or `)`. Parentheses must be percent-encoded as `%28` and `%29` so that Markdown parsers do not prematurely terminate links at the first closing parenthesis.
  - Asserts that all links in `documents/references.md` strictly use the secure `https://` protocol (zero insecure `http://` links).
  - Asserts the complete absence of all 20 obsolete, dead, or mismatched URL substrings (e.g., 4 Kings 15 `12015.htm`, obsolete object IDs `10207`, `30672`, `32338`, KHM obsolete paths `objektdb/detail/403` / `1531`, `secret-of-the-rosary-5671`, `catholictradition.org`, `collezione_online/last-supper`, `feast-of-our-lady-of-the-rosary.html`, or old Prado UUIDs).
  - Asserts the presence of all 23 verified replacement URL substrings (e.g., Judith 15 `18015.htm`, `jth015.htm`, `13189a.htm`, `memorial-of-our-lady-of-the-rosary.html`, Nelson-Atkins `29292`, Princeton `34052`, MFA Boston `32172`, KHM `the-baptism-of-christ-1522`, `christ-on-the-mount-of-olives-187`, `collezione-on-line/last-supper`, `olv-kerk-museum`, BALaT `89054` / `70926`, `montfortian.info`, and verified Prado UUIDs).
- **Step 3:** Spot-check Markdown link rendering in `documents/references.md` (e.g., Page 27 Caracciolo and Page 35 Murillo) to confirm links click through to the full URL without premature truncation.
- **Expected:**
  - Automated test suite completes with 0 failures (`8960+ passed`).
  - Hyperlinks render and navigate correctly in standard Markdown parsers without broken parentheses or insecure protocols.

## Test 12.0: Web Export & Cross-Platform Unicode Symbol Fallback Rendering

### TC-WEB-01: Web / HTML5 Export Symbol Rendering Verification
- **Step 1:** Export the project using the Web preset (`game/export_presets.cfg` `preset.1`) or launch a Godot Web export in a modern browser (Chrome/Edge/Firefox/Safari).
- **Step 2:** Observe the top-right pinned floating navigation button.
- **Expected:** The hamburger menu symbol `☰` (`U+2630`) renders crisply in bold serif font without missing-glyph tofu boxes (`□`) or blank spaces.
- **Step 3:** Click the floating button to open the Navigation Drawer.
- **Step 4:** Inspect the drawer header close button, the four mystery set accordion headers, and the liturgical recommendation badge.
- **Expected:**
  - Close button renders multiplication symbol `✕` (`U+2715`) crisply.
  - Collapsed mystery set accordion rows display right-pointing disclosure arrow `▸` (`U+25B8`).
  - Expanding an accordion toggles the arrow to down-pointing triangle `▾` (`U+25BE`).
  - Today's canonically recommended mystery set displays the antique gold liturgical badge `[★ Today]` with a sharp star symbol `★` (`U+2605`).
- **Step 5:** Close the drawer, navigate/scroll past Page 5 to the in-stream jump bar, and inspect the mystery set jump buttons.
- **Expected:** Today's recommended mystery set button displays `★ Recommended Today` with a sharp star icon `★` (`U+2605`) instead of a tofu box.
- **Step 6:** Inspect standard page cards (Page 1 Front Cover through Page 50 Back Cover) across all three text size presets (`Normal`, `Mobile`, `Extra Large`).
- **Expected:**
  - EB Garamond Latin text line heights, margins, and card height calculations remain completely unaffected.
  - Zero layout regressions, text clipping, or unexpected vertical overflow across all 50 pages.
- **Step 7:** Observe the top-left floating reader button and cycle text presets via the dual-sized `'AA'` button.
- **Expected:**
  - The dual-sized `'AA'` icon (`SmallALabel` at 16pt, `LargeALabel` at 26pt) renders crisply with clean baseline alignment inside the 52×52px button.
  - Preset feedback toasts dynamically resize and preserve horizontal centering (`22pt` for Normal, `30pt` for Mobile, `38pt` for Extra Large) without clipping or visual drift.

## Test 13.0: Automated Print PDF Generation Pipeline (`assets/print/`)

### TC-PDF-01: Standard 50-Page 6" × 9" Print PDF Generation
- **Step 1:** From the repository root, run the Python print PDF build script:
  ```powershell
  python scripts/build_print_pdf.py
  ```
- **Step 2:** Inspect the generated PDF at `assets/print/PrayTheRosary.pdf` using a standard PDF viewer (e.g., Adobe Acrobat, SumatraPDF, Edge/Chrome).
- **Expected:**
  - The script executes cleanly and reports successful generation of `assets/print/PrayTheRosary.pdf` (~18 MB).
  - The document contains exactly 50 pages.
  - Page dimensions are 6.0" × 9.0" (`432 × 648 pt`).
  - Gutter margins alternate properly across facing spreads: 0.625" inner margin on the punched spiral spine edge (left on odd pages, right on even pages) and 0.500" on outer/top/bottom edges.
  - Strictly **zero italic fonts** (`EBGaramond-Italic`) appear anywhere across all 50 pages; all text is rendered in crisp regular and bold serif typography.
  - Page 48 renders the bottom colophon with `"This edition of “Pray The Rosary” was created and is maintained by Kevin Audrain."` and `"Version <X.Y.Z>"` dynamically matching `application/config/version` in `game/project.godot` below a thin gold divider line.
  - Page 49 renders the Catholic Public Domain Version (CPDV) Scripture citation notice and museum artwork notice below its gold divider.
  - Page 50 (Back Cover) encapsulates Pope St. John Paul II's epigraph and St. Louis Marie de Montfort's Marian counsel quotes in subtle gold-bordered callout boxes (`#2A090B` fill, `#D4AF37` 0.9pt border, 3.5pt corner radius).
  - All 23 master artworks render in sharp 300-DPI quality without clipping, warping, or distortion.

### TC-PDF-02: Retail Copy Shop US Letter Edition (`--office-depot`)
- **Step 1:** From the repository root, run the script with the `--office-depot` (or `--letter`) flag:
  ```powershell
  python scripts/build_print_pdf.py --office-depot
  ```
- **Step 2:** Inspect the generated output at `assets/print/PrayTheRosary_OfficeDepot.pdf` in a PDF viewer.
- **Expected:**
  - The script completes cleanly with 0 errors.
  - Document contains exactly 50 pages.
  - Sheet dimensions are 8.5" × 11.0" (`612 × 792 pt`) US Letter size.
  - Each 6.0" × 9.0" page (with 0.125" bleed) is centered on the US Letter sheet.
  - Subtle corner crop marks are visible indicating the 6" × 9" trim line, ready for double-sided spiral-bound printing and trimming at commercial copy shops (e.g., Office Depot, FedEx Office).

### TC-PDF-03: Commercial Press Full Bleed Edition (`--bleed`)
- **Step 1:** From the repository root, run the script with the `--bleed` flag:
  ```powershell
  python scripts/build_print_pdf.py --bleed --output "test_bleed.pdf"
  ```
- **Step 2:** Inspect `test_bleed.pdf` using a PDF preflight tool or inspect PDF box geometry.
- **Expected:**
  - Page dimensions are 6.25" × 9.25" (`450 × 666 pt`).
  - PDF `TrimBox` is set to `Rect(9, 9, 441, 657)` (6.0" × 9.0" centered) and `BleedBox` is set to `Rect(0, 0, 450, 666)`.
- **Step 3:** Clean up the temporary test file:
  ```powershell
  Remove-Item -Force "test_bleed.pdf"
  ```

### TC-PDF-04: Automated Python Print PDF Unit Test Suite
- **Step 1:** Run the Python test suite:
  ```powershell
  python -m unittest discover -s scripts -p "test_*.py"
  ```
- **Expected:**
  - All unit tests in `scripts/test_build_print_pdf.py` execute and pass with 0 failures (`OK`).

