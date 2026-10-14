# Project Requirements: Pray The Rosary

This document acts as the definitive source of truth for the application's features, architecture, UI layouts, and design constraints. When an autonomous subagent creates a feature, designs a scene, or refactors code, it MUST consult this document to ensure strict adherence to the project's vision.

---

## 1. Project Overview & Vision

**Pray The Rosary** is an interactive prayer companion and sacred art contemplation guide built with Godot 4.7.2 for the OpenGameStack ecosystem. 

Beyond serving as a standalone digital devotional application, this project serves as the interactive digital prototype and single source of truth for a future high-quality, physical 6" x 9" spiral-bound prayer book.

### Key Tenets
1. **Spread-First Design:** The application mirrors a physical two-page book spread:
   - **Left Page (Prayers & Scripture):** Distraction-free, complete prayer text for the decade, scripture passages, and meditative reflections. A user can pray an entire decade without scrolling.
   - **Right Page (Visual Contemplation):** Full-page classical sacred art masterpiece depicting the mystery to aid in contemplation.
2. **Data-Driven Separation:** All prayers, mysteries, scripture citations, reflections, and artwork metadata are stored in structured data formats (JSON / Godot Resources) completely independent of the UI code. This allows the exact same data to be exported to print publishing pipelines (Typst, Affinity Publisher, Scribus, HTML/CSS Paged Media).
3. **Reverent, Accessible Aesthetic:** Clean, dignified typography and palette suitable for quiet meditation in both light and dark ambient environments.

---

## 2. Rosary Book Structure & 24-Spread Pagination
The digital application and physical 6" × 9" spiral-bound book share an identical **26-view / 50-page-side** pagination structure (**Front Cover**, **24 Interior Two-Page Spreads**, and **Back Cover**):

### 2.1 Outside Front Cover (View 0 — Page 1)
- **Artwork:** Bartolomé Esteban Murillo, *The Virgin of the Rosary* (c. 1650–1655, Museo del Prado).
- **Typography:** Title **"Pray the Rosary"** and subtitle *"A Contemplative Visual Guide to the Twenty Mysteries"* set over the upper crimson drapery.

### 2.2 Spread 1: History of the Rosary & How to Use (Pages 2–3)
- **Left Page (Page 2 / Inside Front Cover):** *The History of the Holy Rosary* (Monastic roots & the Marian Psalter, St. Dominic & preaching the Mysteries, Pope St. Pius V & Pope St. John Paul II's 20 Mysteries).
- **Right Page (Page 3):** *Structure of the Book & How to Pray* (Organization of the two-page spreads, step-by-step Rosary guide, and Weekly Schedule of the Mysteries).

### 2.3 Spread 2: The Opening Prayers (Pages 4–5)
- **Left Page (Page 4):** Sign of the Cross, Apostles' Creed, Opening Our Father, Three Hail Marys (for Faith, Hope, and Charity), and Glory Be.
- **Right Page (Page 5):** El Greco, *The Holy Trinity* (1577–1579, Museo del Prado).

### 2.4 Spreads 3–22: The Four Mystery Sets (20 Spreads — Pages 6–45)
Each Mystery is presented as a self-contained two-page spread:
- **Left Page (Even Pages 6–44):**
  - **Mystery Header:** Ordinal label (e.g., *The First Joyful Mystery*), Mystery title, and Spiritual Fruit.
  - **Sacred Scripture:** Public-domain **Douay-Rheims (Challoner Revision)** passage grounding the Mystery.
  - **Contemplative Meditation:** 1–2 sentence reflection connecting the Mystery, its fruit, and the artwork.
  - **Prayers of the Decade:** Full text of the Our Father, Hail Mary (with 10-bead progress indicator), Glory Be, and Fatima Prayer.
- **Right Page (Odd Pages 7–45):** Full-page sacred artwork with artist, title, date, and museum attribution.
- **Mystery Sequence:**
  1. **The Joyful Mysteries (Spreads 3–7, Pages 6–15 — Mondays & Saturdays):**
     1. The Annunciation (*Luke 1:28, 38*) — Fruit: Humility — Art: Bartolomé Esteban Murillo
     2. The Visitation (*Luke 1:41–42, 46–47*) — Fruit: Love of Neighbor — Art: Philippe de Champaigne
     3. The Nativity of Our Lord (*Luke 2:6–7, 10–11*) — Fruit: Poverty of Spirit — Art: Guido Reni
     4. The Presentation in the Temple (*Luke 2:22, 28–32*) — Fruit: Obedience & Purity — Art: Vittore Carpaccio
     5. The Finding in the Temple (*Luke 2:46–47, 49, 51*) — Fruit: Joy in Finding Jesus — Art: Bernard van Orley
  2. **The Luminous Mysteries (Spreads 8–12, Pages 16–25 — Thursdays):**
     1. The Baptism in the Jordan (*Matthew 3:16–17*) — Fruit: Openness to the Holy Spirit — Art: Guido Reni
     2. The Wedding Feast at Cana (*John 2:3–5, 11*) — Fruit: To Jesus through Mary — Art: Sebastiano Ricci
     3. The Proclamation of the Kingdom (*Mark 1:14–15; Matthew 5:3, 8*) — Fruit: Repentance & Trust in God — Art: Carl Bloch
     4. The Transfiguration (*Luke 9:29–30, 35*) — Fruit: Desire for Holiness — Art: Gerard David
     5. The Institution of the Eucharist (*Matthew 26:26–28*) — Fruit: Eucharistic Adoration — Art: Peter Paul Rubens
  3. **The Sorrowful Mysteries (Spreads 13–17, Pages 26–35 — Tuesdays & Fridays):**
     1. The Agony in the Garden (*Luke 22:41–44*) — Fruit: Contrition & Conformity to God's Will — Art: Giovanni Battista Caracciolo
     2. The Scourging at the Pillar (*John 19:1; Isaiah 53:5*) — Fruit: Purity & Mortification — Art: Peter Paul Rubens
     3. The Crowning with Thorns (*Matthew 27:28–30*) — Fruit: Moral Courage — Art: Sir Anthony van Dyck
     4. The Carrying of the Cross (*Luke 23:26–27; John 19:17*) — Fruit: Patience in Trials — Art: Raphael
     5. The Crucifixion and Death of Our Lord (*Luke 23:33–34, 46*) — Fruit: Forgiveness & Perseverance — Art: Bartolomé Esteban Murillo
  4. **The Glorious Mysteries (Spreads 18–22, Pages 36–45 — Wednesdays & Sundays):**
     1. The Resurrection of Our Lord (*Mark 16:5–6*) — Fruit: Lively Faith — Art: Bartolomé Esteban Murillo
     2. The Ascension of Our Lord (*Luke 24:50–52; Acts 1:9*) — Fruit: Christian Hope — Art: John Singleton Copley
     3. The Descent of the Holy Spirit (*Acts 1:14; 2:1–4*) — Fruit: Love of God & Gifts of the Spirit — Art: Juan Bautista Maíno
     4. The Assumption of the Blessed Virgin Mary (*Psalm 44:14–16; Judith 15:10*) — Fruit: Grace of a Happy Death — Art: Bartolomé Esteban Murillo
     5. The Coronation of the Blessed Virgin Mary (*Apocalypse 12:1; Sirach 24:4*) — Fruit: Trust in Mary's Intercession — Art: Diego Velázquez

### 2.5 Spread 23: The Closing Prayers (Pages 46–47)
- **Left Page (Page 46):** Hail, Holy Queen (*Salve Regina*), Versicle & Response (*Pray for us, O holy Mother of God...*), Concluding Rosary Prayer (*O God, whose only begotten Son...*), and concluding Sign of the Cross.
- **Right Page (Page 47):** Bartolomé Esteban Murillo, *The Immaculate Conception of Los Venerables* (c. 1678, Museo del Prado).

### 2.6 Spread 24: Sacred Artwork Credits & Attributions (Pages 48–49)
- **Left Page (Page 48):** Credits Part I (Cover, Opening/Closing Prayers, Joyful & Luminous Mysteries).
- **Right Page (Page 49 / Inside Back Cover):** Credits Part II (Sorrowful & Glorious Mysteries, Douay-Rheims Scripture notice, and Museum Open-Access Colophon).

### 2.7 Outside Back Cover (View 25 — Page 50)
- Deep Baroque crimson (`#4A1215`) and warm gold (`#D4AF37`) layout harmonizing with the front cover drapery, featuring Pope St. John Paul II's epigraph from *Rosarium Virginis Mariae*, book synopsis, and St. Louis de Montfort's counsel on daily recitation of the Rosary.

---

## 3. UI, Physical Index Tabs & Visual Layout Specifications

### 3.1 App Layout: Continuous 50-Page Vertical Scroll
- Rather than forcing a wide 12:9 two-page spread onto screens, the application presents all **50 individual portrait pages (`Page 1` Front Cover at the top through `Page 50` Back Cover at the bottom)** in a single, smooth **continuous vertical scroll**.
- Each page card maintains a $2:3$ ($6" \times 9"$) portrait aspect ratio:
  - **Even Pages (`Pages 4, 6, 8, ..., 46`):** Display the prayers, Scripture readings, spiritual fruit, and meditation text.
  - **Odd Artwork Pages (`Pages 5, 7, 9, ..., 47`):**
    - **Top Header Band:** Displays the section or Mystery ordinal subtitle (e.g., *The First Joyful Mystery*) and Mystery title (e.g., **The Annunciation**) at the top of the artwork page so that when the physical spiral-bound book is folded $360^\circ$ back (or when viewing the painting page in the continuous-scroll app), the reader always sees which Mystery they are contemplating.
    - **Center Artwork Frame:** Displays the sacred masterwork (`TextureRect` with `expand_mode = EXPAND_IGNORE_SIZE`, `stretch_mode = STRETCH_KEEP_ASPECT_CENTERED`).
    - **Bottom Attribution Footer:** Displays Artist, Title, Year, and Museum Collection.

### 3.2 App Navigation: Top-Right Menu & In-Stream Separators
1. **Top-Right Navigation & Bookmark Menu:**
   - A floating button in the top-right corner opens a navigation and bookmark drawer:
     - **Front Cover** *(Page 1)*
     - **History of the Rosary** *(Page 2)*
     - **How to Use This Book** *(Page 3)*
     - **Opening Prayers** *(Page 4)*
     - **`▸` The Joyful Mysteries** *(Clicking the title jumps directly to Page 6; clicking the left arrow `▸` expands all 5 individual Joyful Mysteries)*
     - **`▸` The Luminous Mysteries** *(Clicking the title jumps directly to Page 16; clicking `▸` expands all 5 Luminous Mysteries)*
     - **`▸` The Sorrowful Mysteries** *(Clicking the title jumps directly to Page 26; clicking `▸` expands all 5 Sorrowful Mysteries)*
     - **`▸` The Glorious Mysteries** *(Clicking the title jumps directly to Page 36; clicking `▸` expands all 5 Glorious Mysteries)*
     - **Closing Prayers** *(Page 46)*
     - **Credits & Attributions** *(Page 48)*
     - **Back Cover** *(Page 50)*
   - Supports bookmarking the user's current page and highlights the day's recommended Mystery set.
2. **Subtle In-Stream Quick-Jump Separators:**
   - **After Page 5 (End of Opening Prayers):** A subtle separator bar allowing the user to jump directly to the 1st Joyful (Page 6), 1st Luminous (Page 16), 1st Sorrowful (Page 26), or 1st Glorious Mystery (Page 36).
   - **After Pages 15, 25, 35, and 45 (End of each 5th Mystery):** A subtle separator bar with a *"Proceed to the Closing Prayers (Page 46)"* button so the user can jump directly to the Closing Prayers after completing any 5-decade set.

### 3.3 Physical Book Specification: 6 Stepped Index Tabs (`O`, `J`, `L`, `S`, `G`, `C`)
- **Trim & Tab Dimensions:**
  - **Interior Body Page Size:** $6.0" \times 9.0"$.
  - **Protruding Die-Cut Tab Extension:** $0.375"$ ($3/8"$) on the right fore-edge, giving tabbed sheets a total width of $6.375" \times 9.0"$.
  - **Overhang Cover Width:** $6.375" \times 9.0"$ front and back covers so that when the book is closed, the covers protect the 6 protruding tabs.
  - **Vertical Stepping:** 6 stepped tabs ($1.25"$ tall each along a $7.5"$ centered vertical track with $0.75"$ top/bottom margins).
- **Flip-to-Left Mechanics:**
  When the book is closed, grabbing any tab on the right and flipping that tabbed sheet to the left opens directly to that section's two-page spread:
  1. **`O` (Sheet 2, Pages 3–4):** Flips to the left to reveal **Spread 2: Opening Prayers** (`Page 4` Left | `Page 5` Right).
  2. **`J` (Sheet 3, Pages 5–6):** Flips to the left to reveal **Spread 3: 1st Joyful Mystery** (`Page 6` Left | `Page 7` Right).
  3. **`L` (Sheet 8, Pages 15–16):** Flips to the left to reveal **Spread 8: 1st Luminous Mystery** (`Page 16` Left | `Page 17` Right).
  4. **`S` (Sheet 13, Pages 25–26):** Flips to the left to reveal **Spread 13: 1st Sorrowful Mystery** (`Page 26` Left | `Page 27` Right).
  5. **`G` (Sheet 18, Pages 35–36):** Flips to the left to reveal **Spread 18: 1st Glorious Mystery** (`Page 36` Left | `Page 37` Right).
  6. **`C` (Sheet 23, Pages 45–46):** Flips to the left to reveal **Spread 23: Closing Prayers** (`Page 46` Left | `Page 47` Right).

---

## 4. Data Architecture & Asset Guidelines

### 4.1 Data Structure (`game/data/` & `game/scripts/data/`)
All text, prayers, mysteries, and page pagination are stored in three modular JSON files loaded by `RosaryDataLoader` (`res://scripts/data/rosary_data_loader.gd`):
- `res://data/prayers.json`: Dictionary of all 12 canonical Rosary prayers (`sign_of_the_cross`, `apostles_creed`, `our_father`, `hail_mary`, `hail_mary_faith`, `hail_mary_hope`, `hail_mary_charity`, `glory_be`, `fatima_prayer`, `hail_holy_queen`, `versicle_response`, `rosary_concluding_prayer`).
- `res://data/mysteries.json`: Ordered array of the 4 Mystery Sets (`joyful`, `luminous`, `sorrowful`, `glorious`) and all 20 Mysteries (`spread_number` 3..22, `left_page_number`, `right_page_number`, `title`, `fruit`, Douay-Rheims `scripture_reference` & `scripture_text`, `meditation`, and `artwork` metadata).
- `res://data/book_layout.json`: Complete 26-view / 50-page-side book manifest (`front_cover`, `spreads` 1..24, `back_cover`).

### 4.2 Sacred Art Standards & Archival Protection
- Public Domain (CC0 / Open Access) from institutions like:
  - Museo del Prado, National Gallery, Kunsthistorisches Museum, Metropolitan Museum of Art, National Gallery of Art, Art Institute of Chicago, and Wikimedia Commons.
- **Immutable Original Downloads (`assets/2D/gimp/original_downloads/`):**
  - All 23 `*_master_*.jpg` files in `assets/2D/gimp/original_downloads/` (cataloged in `assets/2D/gimp/attributions.json`) are unmodified, byte-for-byte archival downloads.
  - Agents and scripts must **never** modify, overwrite, crop, resize, rename, or delete any file inside `assets/2D/gimp/original_downloads/`.
- **Derived Assets:**
  - Working GIMP project files (`.xcf`) and print-ready crops belong in `assets/2D/gimp/`.
  - Compressed runtime textures (`.webp` / `.png` / `.jpg`) for the Godot application belong in `game/assets/`.

---

## 5. Technical Constraints & Testing

1. **Godot Version:** 4.7.2.
2. **Renderer:** `gl_compatibility` (OpenGL ES 3.0 / WebGL 2.0).
3. **Automated Testing:** All data files and UI components must have unit tests in `game/tests/` runnable via:
   `godot --headless --path game -s res://tests/test_runner.gd`
4. **Static Typing:** GDScript static typing is strictly enforced (`-> void`, `var x: int = 0`).
5. **No Broken Links or Missing Assets:** Unit tests must verify that all images and data files referenced in json/resources exist on disk.
