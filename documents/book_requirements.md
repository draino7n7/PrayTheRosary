# Physical Book Requirements: Pray The Rosary (6" × 9" Spiral-Bound Edition)

This document defines the physical production, layout, typography, index tab, and prepress specifications for the **Pray The Rosary** 6" × 9" spiral-bound prayer book.

*(Note: Specifications for the Godot 4.7.2 interactive digital application are maintained in [`documents/requirements.md`](requirements.md). Both the physical book and the digital app share the canonical prayer, Scripture, Mystery, and artwork data in `game/data/` and `assets/2D/gimp/`.)*

---

## 1. Physical Format, Dimensions & Binding

- **Binding Style:** Twin-loop wire-o / spiral binding along the 9.0" vertical spine edge, allowing the book to lie completely flat ($180^\circ$) on a table or fold completely back on itself ($360^\circ$) for one-handed use while holding Rosary beads.
- **Interior Body Page Trim Size:** $6.0" \text{ wide} \times 9.0" \text{ tall}$ ($2:3$ portrait aspect ratio).
- **Open Two-Page Spread Size:** $12.0" \text{ wide} \times 9.0" \text{ tall}$ ($4:3$ landscape aspect ratio).
- **Protruding Die-Cut Index Tabs (`O`, `J`, `L`, `S`, `G`, `C`):**
  - **Tab Extension Width:** $0.375"$ ($3/8"$) protruding beyond the $6.0"$ right fore-edge.
  - **Tabbed Sheet Width:** $6.375" \times 9.0"$ prior to die-cutting.
  - **Vertical Tab Stepping:** 6 stepped tabs along a centered $7.5"$ vertical track ($0.75"$ top and bottom margins), with each tab measuring **$1.25"$ tall**.
- **Overhang Front & Back Covers:**
  - Heavy laminated cover stock measuring **$6.375" \text{ wide} \times 9.0" \text{ tall}$** so the outer edge of the covers is flush with the outer edge of the 6 protruding index tabs, protecting the tabs from damage when the book is closed.
- **Total Sheet & Page Count:**
  - **25 double-sided leaves (50 page sides total):**
    - Outside Front Cover (`Page Side 1`)
    - **24 Interior Two-Page Spreads (`Page Sides 2–49`)**
    - Outside Back Cover (`Page Side 50`)

---

## 2. Six Stepped Index Tabs (`O`, `J`, `L`, `S`, `G`, `C`)

When the book is closed, the 6 stepped tabs are visible down the right edge (`O`, `J`, `L`, `S`, `G`, `C`). Grabbing any tab on the right and **flipping that tabbed sheet over to the left** opens directly to the corresponding two-page spread:

| Tab Order | Tab Letter | Section Opened | Sheet # (Page Sides) | Resulting Open Spread (Left Page \| Right Page) |
| :---: | :---: | :--- | :---: | :--- |
| **1 (Top)** | **`O`** | **Opening Prayers** | Sheet 2 *(Sides 3–4)* | **Spread 2:** *Opening Prayers Text* (Left) \| El Greco, *The Holy Trinity* (Right) |
| **2** | **`J`** | **Joyful Mysteries** | Sheet 3 *(Sides 5–6)* | **Spread 3:** *1st Joyful: The Annunciation* (Left) \| Murillo, *The Annunciation* (Right) |
| **3** | **`L`** | **Luminous Mysteries** | Sheet 8 *(Sides 15–16)* | **Spread 8:** *1st Luminous: The Baptism* (Left) \| Guido Reni, *The Baptism of Christ* (Right) |
| **4** | **`S`** | **Sorrowful Mysteries** | Sheet 13 *(Sides 25–26)* | **Spread 13:** *1st Sorrowful: Agony in the Garden* (Left) \| Caracciolo, *Mount of Olives* (Right) |
| **5** | **`G`** | **Glorious Mysteries** | Sheet 18 *(Sides 35–36)* | **Spread 18:** *1st Glorious: The Resurrection* (Left) \| Murillo, *The Resurrection* (Right) |
| **6 (Bottom)** | **`C`** | **Closing Prayers** | Sheet 23 *(Sides 45–46)* | **Spread 23:** *Closing Prayers Text* (Left) \| Murillo, *Immaculate Conception* (Right) |

---

## 3. Visual Design, Typography & Editorial Rules

### 3.1 Color Palette & Paper Stock
- **Interior Paper Appearance:** Warm Ivory / Parchment (`#FAF6EE`) uncoated or matte-coated archival paper stock (minimum 80–100 lb text weight to prevent show-through, with heavier tab-stock sheets for the 6 tabbed leaves).
- **Body Text Ink:** Deep Charcoal / Espresso (`#1E1815`).
- **Headings & Mystery Titles:** Baroque Marian Crimson (`#6B1D21`).
- **Borders, Dividers & Artwork Frames:** Antique Gold (`#B89130`).
- **Front & Back Covers:**
  - **Front Cover:** Full-bleed reproduction of Bartolomé Esteban Murillo's *The Virgin of the Rosary* with the title **"Pray the Rosary"** and subtitle set in warm gold/ivory serif typography over the upper crimson drapery.
  - **Back Cover:** Deep Baroque Crimson (`#4A1215` / `#2A090B`) background with warm gold (`#D4AF37`) borders and ivory (`#F7F2E7`) typography featuring Pope St. John Paul II's epigraph from *Rosarium Virginis Mariae*, the book synopsis, and St. Louis Marie de Montfort's full verbatim Marian counsel quote from *The Secret of the Rosary* (25th Rose).

### 3.2 Typography
- Classical serif typeface family (**Cormorant Garamond** or **EB Garamond**, Regular, Bold, and Italic weights) used consistently across all headings, Catholic Public Domain Version (CPDV) Scripture readings, meditations, and prayers.

### 3.3 Editorial & Contemplative Layout Rules
1. **No Numerical Page Numbers:**
   - Do **not** print numerical page numbers (`1..50`) on any pages. Navigation relies cleanly on the 6 index tabs (`O`, `J`, `L`, `S`, `G`, `C`) and the top section/Mystery headers.
2. **Distraction-Free Right-Hand Artwork Pages (`Page Sides 5, 7, 9, ..., 47`):**
   - **Top Header Band Required:** Every right-hand artwork page displays the Mystery/Section ordinal subtitle (e.g., *The First Joyful Mystery*) and Mystery title (e.g., **The Annunciation**) at the top of the page. This ensures that when a reader folds the spiral-bound book $360^\circ$ back so only the painting page is showing, they always know which Mystery they are praying.
   - **Gold-Framed Uncropped Masterpiece:** Below the top header, the painting is enclosed in a thin antique-gold border (`#B89130`) on the warm ivory page, preserving the complete uncropped composition.
   - **No On-Page Artist or Museum Captions:** To keep the artwork page completely pure for prayer and visual contemplation, **no artist names, dates, or museum credits appear on the artwork pages**. All 23 artwork attributions appear exclusively on the **Sacred Artwork Credits spread (`Spread 24`, Page Sides 48–49)** in exact sequential order of appearance in the book (12 items on Page Side 48: Front Cover, Opening Prayers, Joyful Mysteries 1–5, and Luminous Mysteries 1–5; 11 items + Colophon on Page Side 49: Sorrowful Mysteries 1–5, Glorious Mysteries 1–5, and Closing Prayers last), with each credit entry displaying its non-numbered section/Mystery placement label (`section_label`) alongside the painting title.
3. **Left-Hand Mystery Prayer Pages (`Even Page Sides 6, 8, 10, ..., 44`):**
   - Self-contained on a single $6" \times 9"$ page so the reader never turns a page mid-decade:
     - Mystery Ordinal Subtitle, Title, and **Fruit of the Mystery**
     - Public-domain **Catholic Public Domain Version (CPDV)** verbatim Scripture passage and clean book, chapter, and verse citation (without repeating a trailing `" (CPDV)"` suffix on each page, since the `Catholic Public Domain Version of the Bible` is noted once in the front matter on Page Side 3 under *"How This Book Is Organized"* and in the Page Side 49 colophon; uses modern Catholic book nomenclature and Psalm numbering where applicable, such as *Psalm 131:8 (132:8); Luke 1:48–49; Judith 15:10*, *Isaiah 53:5*, *Sirach 24:7*, and *Revelation 12:1*, ordered strictly to match the sequence of quoted verses)
     - 1–2 sentence Contemplative Meditation
     - Full text of the Decade Prayers (*The Our Father* `1×`, *The Hail Mary* `10×`, *The Glory Be* `1×`, and *The Fatima Prayer* `1×`, using the simplified titles `"The Our Father"` and `"The Glory Be"` without parenthetical `"The Lord's Prayer"` or `"(Doxology)"`)
4. **Front-Matter Instructional Guide (`Page Side 3`, *Structure of This Book & How to Pray*):**
   - Page Side 2 features subheading *"Origins and Tradition of the Most Holy Rosary"*.
   - In Section 1 (*"How This Book Is Organized"*), notes that Scripture readings are taken from the Catholic Public Domain Version of the Bible ([SacredBible.org](https://www.sacredbible.org/) / [draino7n7/cpdv](https://github.com/draino7n7/cpdv)), and specifies leader (regular) and group unison (bold) recitation.
   - In Section 2 (*"Step-by-Step Guide to Praying the Rosary"*), Step 2 (*"2. The Decades (Tabs J, L, S, G)"*) instructs the reader to pray either the five decades of the day's Mystery set or all four Mystery sets (twenty decades) back-to-back in chronological order (*Joyful, Luminous, Sorrowful, Glorious*) for a complete Rosary.
5. **Sacred Artwork Credits & Colophon Spread (`Spread 24`, `Page Sides 48–49`):**
   - **Page Side 48 (Part I):** Lists 12 masterwork attributions (Front Cover, Opening Prayers, Joyful Mysteries 1–5, Luminous Mysteries 1–5).
   - **Page Side 49 (Part II & Colophon):** Lists 11 masterwork attributions (Sorrowful Mysteries 1–5, Glorious Mysteries 1–5, Closing Prayers), followed by:
     - **Scripture Colophon Notice:** *"Scripture quotations are taken from the Catholic Public Domain Version (CPDV) of the Holy Bible (sacredbible.org), which is in the public domain."* (referencing [SacredBible.org](https://www.sacredbible.org/) and [draino7n7/cpdv](https://github.com/draino7n7/cpdv)).
     - **Artwork Colophon Notice:** Confirms that all twenty-three paintings are public-domain masterworks courtesy of their respective holding museums and collections.

---

## 4. Archival Master Artworks (`assets/2D/gimp/`)

- **Immutable Original Downloads:** All 23 high-resolution archival master files are stored in `assets/2D/gimp/original_downloads/` and cataloged in `assets/2D/gimp/attributions.json` in exact sequential order of appearance in the book (with `"closing_prayers"` ordered last after `"glorious_5_coronation"`), maintaining complete museum `inventory_number`, `original_dimensions`, `creation_date`, `current_location`, and non-numbered placement `section_label` records synchronized with `game/data/mysteries.json`, `game/data/book_layout.json`, and `RosaryDataLoader`.
- **Print Prep Guidelines:** Any print-ready CMYK/300-DPI exports or GIMP `.xcf` working files must be saved in `assets/2D/gimp/` (outside `original_downloads/`), leaving the 23 files in `assets/2D/gimp/original_downloads/` untouched.

---

## 5. Affinity Publishing & Prepress Workflow (`assets/Affinity/`)

### 5.1 Content Synchronization & Scripture Translation
- The Affinity book layout and automated PDF generator consume prayer, mystery, and layout data directly from `game/data/` (`mysteries.json`, `book_layout.json`, `prayers.json`).
- Scripture citations and readings are standardized on the **Catholic Public Domain Version (CPDV)** of the Holy Bible ([SacredBible.org](https://www.sacredbible.org/) / [draino7n7/cpdv](https://github.com/draino7n7/cpdv)), maintaining perfect textual alignment between the interactive digital application and the printed volume.

### 5.2 Prepress Layout Specifications & Files
All editable layout files, fonts, and press-ready exports for the 50-page spiral-bound book live in `assets/Affinity/` (tracked via Git LFS):

- **Master Affinity Project (`assets/Affinity/PrayTheRosary.af`):**
  - Editable 50-page **Affinity** (`Layout` mode) document (`6.0" × 9.0"` trim size, `0.125"` bleed on all 4 sides, Facing Pages starting on Right, `CMYK/8` — `U.S. Web Coated (SWOP) v2`, `300 DPI`).
  - **Spiral-Binding Gutter Margins:** Every interior page (`Pages 2–49`) reserves a **`0.625"` (`5/8"`) Inner Margin** along the punched spine edge (`Left` on Odd/Right-hand pages; `Right` on Even/Left-hand pages) and **`0.50"` (`1/2"`)** on the Outer, Top, and Bottom edges so twin-loop wire-o punching (`~0.375"` depth) never encroaches on gold borders or typography.
- **Press-Ready 50-Page PDF (`assets/Affinity/PrayTheRosary.pdf`):**
  - Exported from Affinity using **`PDF (press ready)`** with **`Area: All Pages`** (50 individual `6.25" × 9.25"` pages with `0.125"` bleed included and `6.00" × 9.00"` `TrimBox`), **`Include bleed: ON`**, **`Include printers marks: OFF`**, **`Convert image color spaces: ON`**, and **`Embed Fonts: All Fonts`**.
- **Required Font Installation (`assets/Affinity/fonts/`):**
  - Before opening `assets/Affinity/PrayTheRosary.af`, install all four **`EB Garamond Book`** fonts (`EBGaramondBook-Regular.ttf`, `EBGaramondBook-Bold.ttf`, `EBGaramondBook-Italic.ttf`, `EBGaramondBook-BoldItalic.ttf`).
  - These fonts are custom-packaged from `EB Garamond` with OpenType terminal swash features (`fina`, `init`, `swsh`, `calt`, `dlig`, `hlig`) stripped so Affinity never substitutes long-tailed word-final `e` glyphs (`e.fina`).
- **Automated PDF Layout Generator (`assets/Affinity/build_affinity_pdf.py`):**
  - Rebuilds the 50-page vector PDF directly from `game/data/*.json` and `assets/2D/gimp/original_downloads/` via `python assets/Affinity/build_affinity_pdf.py`.

