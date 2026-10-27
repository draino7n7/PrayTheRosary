# Physical Book Requirements: Pray The Rosary (6" × 9" Spiral-Bound Edition)

This document defines the physical production, layout, typography, index tab, and prepress specifications for the **Pray The Rosary** 6" × 9" spiral-bound prayer book.

*(Note: Specifications for the Godot 4.7.2 interactive digital application are maintained in [`documents/requirements.md`](requirements.md). Both the physical book and the digital app share the canonical prayer, Scripture, Mystery, and artwork data in `game/data/` and `assets/2D/gimp/`.)*

---

## 1. Physical Format, Dimensions & Binding

- **Binding Style:** Twin-loop wire-o / spiral binding along the 9.0" vertical spine edge, allowing the book to lie completely flat ($180^\circ$) on a table or fold completely back on itself ($360^\circ$) for one-handed use while holding Rosary beads.
- **Interior Body Page Trim Size:** $6.0" \text{ wide} \times 9.0" \text{ tall}$ ($2:3$ portrait aspect ratio).
- **Open Two-Page Spread Size:** $12.0" \text{ wide} \times 9.0" \text{ tall}$ ($4:3$ landscape aspect ratio).
- **Protruding Die-Cut Index Tabs (`O`, `J`, `L`, `S`, `G`, `C`):**
  - **Tab Extension Width:** $0.375"$ ($3/8"$, `27.0 pt`) protruding beyond the $6.0"$ right fore-edge.
  - **Tabbed Sheet Width:** $6.375" \times 9.0"$ (`459 × 648 pt`) prior to die-cutting.
  - **Vertical Tab Stepping (`1/6-Cut`):** 6 stepped tabs along an $8.0"$ (`576 pt`) vertical track aligned with the top and bottom of the Master A gold border frame ($0.50"$ top and bottom margins), with each tab measuring **$1.333"$ (`96.0 pt`) tall**.
  - **Tab Visual Styling:** Deep Baroque Crimson (`#4A1215`) fill with a `1.5pt` gold shoulder rule along the $6.0"$ edge, an inset Antique Gold (`#D4AF37`) rounded border frame, and an upright `EBGaramond-Bold` (`17.5pt`) gold monogram (`O`, `J`, `L`, `S`, `G`, `C`) printed on both the front (odd page, right edge) and back (even page, left edge) for duplex back-to-back registration.
- **Overhang Front & Back Covers (`Sheets 1 & 25`):**
  - Heavy laminated cover stock measuring **$6.375" \text{ wide} \times 9.0" \text{ tall}$** (`459 × 648 pt`) so the outer edge of the covers is flush with the outer edge of the 6 protruding index tabs, protecting the tabs from damage when the book is closed.
  - **Inside Cover Wrap-Around Overhang Strip (`Pages 2 & 49`):** Because `Page 2` prints on the Inside Front Cover (verso of Sheet 1) and `Page 49` prints on the Inside Back Cover (recto of Sheet 25), their main $6.0"$ parchment page areas align symmetrically with the facing $6.0"$ interior pages while the outer $0.375"$ overhang strip (`left` edge on Page 2, `right` edge on Page 49) is rendered in Deep Baroque Crimson (`#4A1215`) with a vertical `1.5pt` Antique Gold (`#D4AF37`) divider line at the $6.0"$ mark.
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
| **1 (Top)** | **`O`** | **Opening Prayers** | Sheet 2 *(Sides 3–4)* | **Spread 2:** *The Opening Prayers* (Left) \| El Greco, *The Holy Trinity (La Trinidad)* (Right) |
| **2** | **`J`** | **Joyful Mysteries** | Sheet 3 *(Sides 5–6)* | **Spread 3:** *1st Joyful: The Annunciation* (Left) \| Murillo, *The Annunciation (La Anunciación)* (Right) |
| **3** | **`L`** | **Luminous Mysteries** | Sheet 8 *(Sides 15–16)* | **Spread 8:** *1st Luminous: The Baptism of Jesus in the Jordan* (Left) \| Guido Reni, *The Baptism of Christ* (Right) |
| **4** | **`S`** | **Sorrowful Mysteries** | Sheet 13 *(Sides 25–26)* | **Spread 13:** *1st Sorrowful: The Agony in the Garden* (Left) \| Caracciolo, *Christ on the Mount of Olives (Christ's Fear of Death)* (Right) |
| **5** | **`G`** | **Glorious Mysteries** | Sheet 18 *(Sides 35–36)* | **Spread 18:** *1st Glorious: The Resurrection of Our Lord* (Left) \| Murillo, *The Resurrection of the Lord (La Resurrección del Señor)* (Right) |
| **6 (Bottom)** | **`C`** | **Closing Prayers** | Sheet 23 *(Sides 45–46)* | **Spread 23:** *The Closing Prayers* (Left) \| Murillo, *The Immaculate Conception of Los Venerables (Inmaculada de Soult)* (Right) |

---

## 3. Visual Design, Typography & Editorial Rules

### 3.1 Color Palette & Paper Stock
- **Interior Paper Appearance:** Warm Ivory / Parchment (`#FAF6EE`) uncoated or matte-coated archival paper stock (minimum 80–100 lb text weight to prevent show-through, with heavier tab-stock sheets for the 6 tabbed leaves).
- **Body Text Ink:** Deep Charcoal / Espresso (`#1E1815`).
- **Headings & Mystery Titles:** Baroque Marian Crimson (`#6B1D21`).
- **Borders, Dividers & Artwork Frames:** Antique Gold (`#B89130`).
- **Front & Back Covers:**
  - **Front Cover:** Deep Baroque Crimson (`#4A1215` / `#2A090B`) background with warm gold double border (`#D4AF37`), dedicated Top Header Band housing the title **"Pray the Rosary"** in warm gold 38pt bold (`#D4AF37`) and subtitle *"A Contemplative Visual Guide to the Twenty Mysteries"* in warm ivory 22pt regular (`EBGaramond-Regular.ttf`, `#F7F2E7`), and a framed artwork container below enclosing Bartolomé Esteban Murillo's *The Madonna of the Rosary (The Virgin of the Rosary)* (Dulwich Picture Gallery, London, `DPG281`, c. 1675–1680, 197.8 cm × 128 cm), guaranteeing zero text elements overlap any portion of the sacred painting.
  - **Back Cover:** Deep Baroque Crimson (`#4A1215`) background with antique gold border (`#D4AF37`) and dark crimson callout box background (`#2A090B`), featuring Pope St. John Paul II's epigraph from *Rosarium Virginis Mariae*, the book synopsis, and St. Louis Marie de Montfort's full verbatim Marian counsel quote from *The Secret of the Rosary* (25th Rose), with quote attributions set in regular serif typography.

### 3.2 Typography
- Classical serif typeface family (**Cormorant Garamond** or **EB Garamond**, Regular and Bold weights) used consistently across all headings, Catholic Public Domain Version (CPDV) Scripture readings, meditations, rubrics, and prayers. Across all 50 screen and print-facing book pages, typography standardizes on crisp, upright serif typography (`Regular` and `Bold`), eliminating italic slant for enhanced reading clarity, visual weight balance, and optimal print/screen legibility.

### 3.3 Editorial & Contemplative Layout Rules
1. **No Numerical Page Numbers:**
   - Do **not** print numerical page numbers (`1..50`) on any pages. Navigation relies cleanly on the 6 index tabs (`O`, `J`, `L`, `S`, `G`, `C`) and the top section/Mystery headers.
2. **Distraction-Free Right-Hand Artwork Pages (`Page Sides 5, 7, 9, ..., 47`):**
   - **Top Header Band Required:** Every right-hand artwork page displays the Mystery/Section ordinal subtitle (e.g., *The First Joyful Mystery*) and Mystery title (e.g., **The Annunciation**) at the top of the page. This ensures that when a reader folds the spiral-bound book $360^\circ$ back so only the painting page is showing, they always know which Mystery they are praying.
   - **Gold-Framed Uncropped Masterpiece:** Below the top header, the painting is enclosed in a thin antique-gold border (`#B89130`) on the warm ivory page, preserving the complete uncropped composition.
   - **No On-Page Artist or Museum Captions:** To keep the artwork page completely pure for prayer and visual contemplation, **no artist names, dates, or museum credits appear on the artwork pages**. All 23 artwork attributions appear exclusively on the **Sacred Artwork Credits spread (`Spread 24`, Page Sides 48–49)** in exact sequential order of appearance in the book (12 items + Creator Colophon on Page Side 48: Front Cover, Opening Prayers, Joyful Mysteries 1–5, and Luminous Mysteries 1–5; 11 items + Scripture/Artwork Colophon on Page Side 49: Sorrowful Mysteries 1–5, Glorious Mysteries 1–5, and Closing Prayers last), with each credit entry displaying its non-numbered section/Mystery placement label (`section_label`) alongside the painting title.
3. **Left-Hand Mystery Prayer Pages (`Even Page Sides 6, 8, 10, ..., 44`):**
   - Self-contained on a single $6" \times 9"$ page so the reader never turns a page mid-decade:
     - Mystery Ordinal Subtitle, Title, and **Fruit of the Mystery** (standardized on concise traditional USCCB virtues: *Humility*, *Love of Neighbor*, *Poverty*, *Purity of Heart and Body*, *Devotion to Jesus*, *Openness to the Holy Spirit*, *To Jesus through Mary*, *Conversion*, *Desire for Holiness*, *Adoration*, *Obedience to God's Will*, *Mortification*, *Courage*, *Patience*, *Sorrow for Our Sins*, *Faith*, *Hope*, *Wisdom*, *Devotion to Mary*, *Grace of a Happy Death*)
     - Public-domain **Catholic Public Domain Version (CPDV)** verbatim Scripture passage and clean book, chapter, and verse citation (without repeating a trailing `" (CPDV)"` suffix on each page, since the `Catholic Public Domain Version of the Bible` is noted once in the front matter on Page Side 3 under *"How This Book Is Organized"* and in the Page Side 49 colophon; uses modern Catholic book nomenclature and Psalm numbering where applicable, such as *Psalm 131:8 (132:8); Luke 1:48–49; Judith 15:10*, *Isaiah 53:5*, *Sirach 24:7*, and *Revelation 12:1*, ordered strictly to match the sequence of quoted verses)
     - 1–2 sentence Contemplative Meditation
     - Full text of the Decade Prayers (*The Our Father* `1×`, *The Hail Mary* `10×`, *The Glory Be* `1×`, and *The Fatima Prayer* `1×`, using the simplified titles `"The Our Father"` and `"The Glory Be"` without parenthetical `"The Lord's Prayer"` or `"(Doxology)"`)
4. **Front-Matter Instructional Guide (`Page Side 3`, *Structure of This Book & How to Pray*):**
   - Page Side 2 features subheading *"Origins and Tradition of the Most Holy Rosary"*.
   - In Section 1 (*"How This Book Is Organized"*), notes that Scripture readings are taken from the Catholic Public Domain Version of the Bible ([SacredBible.org](https://www.sacredbible.org/) / [draino7n7/cpdv](https://github.com/draino7n7/cpdv)), and specifies leader (regular) and group unison (bold) recitation.
   - In Section 2 (*"Step-by-Step Guide to Praying the Rosary"*), Step 2 (*"2. The Decades (Tabs J, L, S, G)"*) instructs the reader to pray either the five decades of the day's Mystery set or all four Mystery sets (twenty decades) back-to-back in chronological order (*Joyful, Luminous, Sorrowful, Glorious*) for a complete Rosary.
5. **Sacred Artwork Credits & Colophon Spread (`Spread 24`, `Page Sides 48–49`):**
   - **Page Side 48 (Part I & Creator Colophon):** Lists 12 masterwork attributions (Front Cover, Opening Prayers, Joyful Mysteries 1–5, Luminous Mysteries 1–5), formatted cleanly with parenthetical mystery names stripped from section labels where duplicate with artwork titles (e.g. `"1st Joyful Mystery — The Annunciation (La Anunciación)"`), and artist sobriquets and dates cleanly merged into a single parenthetical (e.g. `El Greco (Doménikos Theotokópoulos, 1541–1614)`), preventing `)...(` collisions. Followed below a thin antique-gold divider by a bottom colophon block displaying:
     - **Creator Attribution Notice:** *"This edition of “Pray The Rosary” was created and is maintained by Kevin Audrain."*
     - **Dynamic Edition / Application Version:** *"Version <X.Y.Z>"* (dynamically synchronized with `application/config/version` in `game/project.godot` and `version/name` in `game/export_presets.cfg`, e.g., *"Version 1.0.2"*).
   - **Page Side 49 (Part II & Scripture/Artwork Colophon):** Lists 11 masterwork attributions (Sorrowful Mysteries 1–5, Glorious Mysteries 1–5, Closing Prayers), formatted with non-duplicate mystery headers and cleanly merged artist sobriquet/dates (e.g. `Giovanni Battista Caracciolo (Battistello, 1578–1635)`, `Raphael (Raffaello Sanzio, 1483–1520)`). Followed below a thin antique-gold divider by:
     - **Scripture Colophon Notice:** *"Scripture quotations are taken from the Catholic Public Domain Version (CPDV) of the Holy Bible (sacredbible.org), which is in the public domain."* (referencing [SacredBible.org](https://www.sacredbible.org/) and [draino7n7/cpdv](https://github.com/draino7n7/cpdv)).
     - **Artwork Colophon Notice:** Confirms that all twenty-three paintings are public-domain masterworks courtesy of the Dulwich Picture Gallery (London), the Museo Nacional del Prado (Madrid), the Kunsthistorisches Museum (Vienna), the National Gallery (London), the National Gallery of Art (Washington, D.C.), the Gallerie dell'Accademia (Venice), the Pinacoteca di Brera (Milan), the State Hermitage Museum (St. Petersburg), the Museum of Fine Arts (Boston), the Nelson-Atkins Museum of Art (Kansas City), the Princeton University Art Museum (Princeton), the Museum of National History at Frederiksborg Castle (Hillerød), the Real Academia de Bellas Artes de San Fernando (Madrid), St. Paul's Church (Antwerp), and the Church of Our Lady (Bruges), styled in warm umber (`#5C4338`).

---

## 4. Archival Master Artworks (`assets/2D/gimp/`)

- **Immutable Original Downloads:** All 23 high-resolution archival master files are stored in `assets/2D/gimp/original_downloads/` and cataloged in `assets/2D/gimp/attributions.json` in exact sequential order of appearance in the book (with `"closing_prayers"` ordered last after `"glorious_5_coronation"`), maintaining complete museum `inventory_number`, `original_dimensions`, `creation_date`, `current_location`, and non-numbered placement `section_label` records synchronized with `game/data/mysteries.json`, `game/data/book_layout.json`, and `RosaryDataLoader`.
- **Print Prep Guidelines:** Any print-ready CMYK/300-DPI exports or GIMP `.xcf` working files must be saved in `assets/2D/gimp/` (outside `original_downloads/`), leaving the 23 files in `assets/2D/gimp/original_downloads/` untouched.

### 4.1 Master Artwork Attribution Catalog (23 Works in Book Sequence)

| Spread / Page | Section Placement Label | Artwork Title | Artist (Dates) | Creation Date | Original Dimensions | Holding Museum / Location | Inventory Number |
| :---: | :--- | :--- | :--- | :---: | :---: | :--- | :---: |
| **Page 1** | Front Cover | *The Madonna of the Rosary (The Virgin of the Rosary)* | Bartolomé Esteban Murillo (1617–1682) | c. 1675–1680 | 197.8 cm × 128 cm | Dulwich Picture Gallery, London, UK | `DPG281` |
| **Spread 2 (P. 5)** | Opening Prayers | *The Holy Trinity (La Trinidad)* | El Greco (1541–1614) | 1577–1579 | 300 cm × 179 cm | Museo del Prado, Madrid, Spain | `P00824` |
| **Spread 3 (P. 7)** | 1st Joyful Mystery | *The Annunciation (La Anunciación)* | Bartolomé Esteban Murillo (1617–1682) | c. 1660–1665 | 125 cm × 103 cm | Museo del Prado, Madrid, Spain | `P00970` |
| **Spread 4 (P. 9)** | 2nd Joyful Mystery | *The Visitation* | Philippe de Champaigne (1602–1674) | 1643–1648 | 114.5 cm × 88.5 cm | Princeton University Art Museum, Princeton, NJ | `y1994-17` |
| **Spread 5 (P. 11)** | 3rd Joyful Mystery | *The Adoration of the Shepherds* | Guido Reni (1575–1642) | c. 1640 | 480 cm × 321 cm | National Gallery, London, UK | `NG6270` |
| **Spread 6 (P. 13)** | 4th Joyful Mystery | *Presentation of Jesus in the Temple* | Vittore Carpaccio (c. 1465–1525/1526) | 1510 | 421 cm × 236 cm | Gallerie dell'Accademia, Venice, Italy | `Cat. 44` |
| **Spread 7 (P. 15)** | 5th Joyful Mystery | *Christ among the Doctors* | Bernard van Orley (c. 1488–1541) | c. 1513 | 54.4 cm × 33.3 cm | National Gallery of Art, Washington, D.C. | `1952.5.47.a` |
| **Spread 8 (P. 17)** | 1st Luminous Mystery | *The Baptism of Christ* | Guido Reni (1575–1642) | c. 1622–1623 | 263.5 cm × 186.5 cm | Kunsthistorisches Museum, Vienna, Austria | `GG 222` |
| **Spread 9 (P. 19)** | 2nd Luminous Mystery | *The Marriage Feast at Cana* | Sebastiano Ricci (1659–1734) | c. 1712–1715 | 167.0 cm × 137.2 cm | Nelson-Atkins Museum of Art, Kansas City, MO | `59-2` |
| **Spread 10 (P. 21)** | 3rd Luminous Mystery | *The Sermon on the Mount* | Carl Bloch (1834–1890) | 1877 | 104 cm × 92 cm | Frederiksborg Castle, Hillerød, Denmark | `King's Oratory` |
| **Spread 11 (P. 23)** | 4th Luminous Mystery | *The Transfiguration of Christ* | Gerard David (c. 1460–1523) | c. 1520 | 174 cm × 120 cm | Church of Our Lady, Bruges, Belgium | `OLV.0003.I` |
| **Spread 12 (P. 25)** | 5th Luminous Mystery | *The Last Supper* | Peter Paul Rubens (1577–1640) | 1630–1631 | 304 cm × 250 cm | Pinacoteca di Brera, Milan, Italy | `97` |
| **Spread 13 (P. 27)** | 1st Sorrowful Mystery | *Christ on the Mount of Olives* | Battistello Caracciolo (1578–1635) | c. 1615–1617 | 148 cm × 124 cm | Kunsthistorisches Museum, Vienna, Austria | `GG F 17` |
| **Spread 14 (P. 29)** | 2nd Sorrowful Mystery | *The Flagellation of Christ* | Peter Paul Rubens (1577–1640) | c. 1617 | 219 cm × 161 cm | St. Paul's Church, Antwerp, Belgium | `70926` |
| **Spread 15 (P. 31)** | 3rd Sorrowful Mystery | *The Crowning with Thorns* | Sir Anthony van Dyck (1599–1641) | c. 1618–1620 | 225 cm × 197 cm | Museo del Prado, Madrid, Spain | `P01474` |
| **Spread 16 (P. 33)** | 4th Sorrowful Mystery | *Christ Falling on Way to Calvary* | Raphael (1483–1520) | c. 1515–1516 | 318 cm × 229 cm | Museo del Prado, Madrid, Spain | `P00298` |
| **Spread 17 (P. 35)** | 5th Sorrowful Mystery | *Christ on the Cross* | Bartolomé Esteban Murillo (1617–1682) | c. 1677 | 71 cm × 54 cm | Museo del Prado, Madrid, Spain | `P00967` |
| **Spread 18 (P. 37)** | 1st Glorious Mystery | *The Resurrection of the Lord* | Bartolomé Esteban Murillo (1617–1682) | c. 1650–1660 | 243 cm × 164 cm | Real Academia de Bellas Artes, Madrid, Spain | `0641` |
| **Spread 19 (P. 39)** | 2nd Glorious Mystery | *The Ascension* | John Singleton Copley (1738–1815) | 1775 | 81.3 cm × 73.0 cm | Museum of Fine Arts, Boston, MA | `25.95` |
| **Spread 20 (P. 41)** | 3rd Glorious Mystery | *Pentecost (Pentecostés)* | Juan Bautista Maíno (1581–1649) | 1612–1614 | 285 cm × 163 cm | Museo del Prado, Madrid, Spain | `P03018` |
| **Spread 21 (P. 43)** | 4th Glorious Mystery | *The Assumption of the Virgin* | Bartolomé Esteban Murillo (1617–1682) | c. 1680 | 195 cm × 145 cm | State Hermitage Museum, St. Petersburg, Russia | `ГЭ-387` |
| **Spread 22 (P. 45)** | 5th Glorious Mystery | *The Coronation of the Virgin* | Diego Velázquez (1599–1660) | c. 1635–1636 | 178.5 cm × 134.5 cm | Museo del Prado, Madrid, Spain | `P01168` |
| **Spread 23 (P. 47)** | Closing Prayers | *Immaculate Conception of Los Venerables* | Bartolomé Esteban Murillo (1617–1682) | c. 1678 | 274 cm × 190 cm | Museo del Prado, Madrid, Spain | `P02809` |

---

## 5. Automated Print PDF & Prepress Pipeline (`assets/print/`)

### 5.1 Content Synchronization & Scripture Translation
- The automated Python print PDF pipeline consumes prayer, mystery, and layout data directly from `game/data/` (`mysteries.json`, `book_layout.json`, `prayers.json`), versioning from `game/project.godot`, fonts from `game/assets/fonts/`, and archival artwork from `assets/2D/gimp/original_downloads/`.
- Scripture citations and readings are standardized on the **Catholic Public Domain Version (CPDV)** of the Holy Bible ([SacredBible.org](https://www.sacredbible.org/) / [draino7n7/cpdv](https://github.com/draino7n7/cpdv)), maintaining perfect textual alignment between the interactive digital application and the printed volume.
- Typography is loaded exclusively from `game/assets/fonts/EBGaramond-Regular.ttf` and `game/assets/fonts/EBGaramond-Bold.ttf`, strictly guaranteeing **zero italic fonts** anywhere across all 50 pages.

### 5.2 Prepress Layout Specifications & CLI Options
The canonical print edition and its automated build pipeline live in `scripts/build_print_pdf.py` and `assets/print/`:

- **Canonical Print PDF (`assets/print/PrayTheRosary.pdf`):**
  - 50-page vector PDF (`6.0" × 9.0"`, `432 × 648 pt`) with 300-DPI resampled master paintings and compression (~18 MB, tracked via Git LFS).
  - **Spiral-Binding Gutter Margins:** Every interior page (`Pages 2–49`) reserves an alternating **`0.625"` (`5/8"`) Inner Margin** along the punched spine edge (`Left` on Odd/Right-hand pages; `Right` on Even/Left-hand pages) and **`0.500"` (`1/2"`)** on the Outer, Top, and Bottom edges so twin-loop wire-o punching (`~0.375"` depth) never encroaches on gold borders or typography.
  - **Page 48 Creator Attribution & Dynamic Version Colophon:** Below the 12 masterwork attributions and a thin antique gold divider, renders `"This edition of “Pray The Rosary” was created and is maintained by Kevin Audrain."` and `"Version <X.Y.Z>"` (read dynamically from `application/config/version` in `game/project.godot`).
  - **Page 49 Text Sources Colophon:** Below the 11 masterwork attributions and gold divider, renders the CPDV Scripture notice and museum public-domain artwork credit notice.
  - **Page 50 Back Cover Callout Boxes:** Features Pope St. John Paul II's epigraph and St. Louis Marie de Montfort's Marian counsel encapsulated in subtle gold-bordered callout boxes (`#2A090B` deep fill, `#D4AF37` 0.9pt border, 3.5pt corner radius).

- **Automated Generator Script (`scripts/build_print_pdf.py`):**
  - Rebuilds `assets/print/PrayTheRosary.pdf` directly from canonical project data:
    ```powershell
    python scripts/build_print_pdf.py
    ```
  - **Retail Copy Shop Printing on US Letter (`--office-depot` / `--letter`):**
    ```powershell
    python scripts/build_print_pdf.py --office-depot
    ```
    Generates `assets/print/PrayTheRosary_OfficeDepot.pdf` centered on `8.5" × 11.0"` (`612 × 792 pt`) US Letter sheets with `0.125"` bleed and subtle corner crop marks, designed for retail copy shop printing (e.g., Office Depot, FedEx Office) on standard Letter paper stock.
  - **Commercial Press Full Bleed (`--bleed`):**
    ```powershell
    python scripts/build_print_pdf.py --bleed
    ```
    Generates a `6.25" × 9.25"` (`450 × 666 pt`) PDF with `0.125"` full bleed and embeds PDF `TrimBox` (`Rect(9, 9, 441, 657)`) and `BleedBox` (`Rect(0, 0, 450, 666)`) metadata for commercial offset and digital presses.
  - **Protruding Index Tabs & Overhang Cover Edition (`--tabs`):**
    ```powershell
    python scripts/build_print_pdf.py --tabs
    ```
    Generates `assets/print/PrayTheRosary_Tabs.pdf` at `6.375" × 9.0"` (`459 × 648 pt`), rendering the full-width `6.375" × 9.0"` Front and Back Overhang Covers (`Pages 1 & 50`), the `0.375"` Deep Baroque Crimson (`#4A1215`) wrap-around overhang strips on `Pages 2 & 49` (Inside Covers), and the 6 stepped `1/6-cut` Crimson and Gold monogram tabs (`O`, `J`, `L`, `S`, `G`, `C`) on `Sheets 2, 3, 8, 13, 18, and 23` (`Page Sides 3-4, 5-6, 15-16, 25-26, 35-36, 45-46`). Designed for visual review and attaching to custom print quote requests.
  - **Protruding Index Tabs with Commercial Full Bleed (`--tabs --bleed`):**
    ```powershell
    python scripts/build_print_pdf.py --tabs --bleed
    ```
    Generates `assets/print/PrayTheRosary_Tabs_Bleed.pdf` at `6.625" × 9.25"` (`477 × 666 pt`) with `0.125"` (`9 pt`) full bleed around the overhang covers, pages, and protruding tab ears, embedding PDF `TrimBox` (`Rect(9, 9, 468, 657)`) and `BleedBox` (`Rect(0, 0, 477, 666)`) metadata for commercial press production.
  - **Automated Test Suite (`scripts/test_build_print_pdf.py`):**
    - Executed via `python -m unittest discover -s scripts -p "test_*.py"`.
    - Validates page count (50), page geometry (including `--bleed`, `--office-depot`, `--tabs`, and `--tabs --bleed`), tab monograms, zero italic fonts, CPDV citations, modernized Creed phrasing, and Page 48 colophon.

