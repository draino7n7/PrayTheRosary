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

## 2. Rosary Structure & Content Flow

### 2.1 Introductory Prayers Spread
- Sign of the Cross
- Apostles' Creed
- Opening Our Father
- Three Hail Marys (for the virtues of Faith, Hope, and Charity)
- Glory Be
- Accompanied on the right by contemplative art (e.g., The Crucifixion or Holy Trinity).

### 2.2 The Four Mystery Sets (5 Decades Each)
Each decade is represented as an independent spread:
1. **The Joyful Mysteries** (Traditionally prayed on Mondays & Saturdays; during Advent/Christmas)
   1. The Annunciation (*Luke 1:26–38*) — Fruit: Humility
   2. The Visitation (*Luke 1:39–56*) — Fruit: Love of Neighbor
   3. The Nativity (*Luke 2:1–20*) — Fruit: Poverty of Spirit / Detachment
   4. The Presentation in the Temple (*Luke 2:22–38*) — Fruit: Obedience / Purity
   5. The Finding of Jesus in the Temple (*Luke 2:41–52*) — Fruit: Joy in finding Jesus / Piety
2. **The Luminous Mysteries (Mysteries of Light)** (Traditionally prayed on Thursdays)
   1. The Baptism of Jesus in the Jordan (*Matthew 3:13–17*) — Fruit: Openness to the Holy Spirit
   2. The Wedding at Cana (*John 2:1–11*) — Fruit: To Jesus through Mary
   3. The Proclamation of the Kingdom (*Mark 1:14–15*) — Fruit: Repentance & Trust in God
   4. The Transfiguration (*Luke 9:28–36*) — Fruit: Desire for Holiness
   5. The Institution of the Eucharist (*Matthew 26:26–30*) — Fruit: Eucharistic Adoration
3. **The Sorrowful Mysteries** (Traditionally prayed on Tuesdays & Fridays; daily during Lent)
   1. The Agony in the Garden (*Luke 22:39–46*) — Fruit: Sorrow for Sin / Conformity to God's Will
   2. The Scourging at the Pillar (*John 19:1*) — Fruit: Mortification of the Senses / Purity
   3. The Crowning with Thorns (*Mark 15:16–20*) — Fruit: Moral Courage
   4. The Carrying of the Cross (*Luke 23:26–32*) — Fruit: Patience in Trials
   5. The Crucifixion and Death of Our Lord (*Luke 23:33–46*) — Fruit: Salvation / Forgiveness
4. **The Glorious Mysteries** (Traditionally prayed on Wednesdays & Sundays; during Eastertide)
   1. The Resurrection (*Mark 16:1–7*) — Fruit: Faith
   2. The Ascension (*Luke 24:50–53*) — Fruit: Hope / Desire for Heaven
   3. The Descent of the Holy Spirit at Pentecost (*Acts 2:1–4*) — Fruit: Love of God / Wisdom
   4. The Assumption of the Blessed Virgin Mary into Heaven (*Tradition / Rev 12:1*) — Fruit: Grace of a Happy Death
   5. The Coronation of Mary as Queen of Heaven and Earth (*Rev 12:1*) — Fruit: Trust in Mary's Intercession

### 2.3 Each Decade Spread Contents
- **Decade Header:** Mystery name, decade number, traditional day of the week, fruit of the mystery.
- **Scriptural Meditation:** 1–3 verse reading grounding the mystery.
- **Prayers of the Decade:**
  - The Lord's Prayer (Our Father)
  - The Angelic Salutation (Hail Mary) - provided in full text once with decade bead progress counter.
  - The Doxology (Glory Be)
  - The Fatima Prayer ("O My Jesus, forgive us our sins...")
- **Sacred Artwork (Right Pane):** High-resolution public-domain masterpiece with painter, year, and museum attribution.

### 2.4 Concluding Prayers Spread
- Hail Holy Queen (*Salve Regina*)
- Rosary Concluding Prayer ("O God, whose only begotten Son...")
- Optional Memorare or Prayer to St. Michael the Archangel
- Concluding Sign of the Cross

---

## 3. UI and Visual Layout Specifications

### 3.1 Book Spread Layout (Default / Tablet / Desktop)
- Aspect ratio: Two 6:9 portrait pages side-by-side produce an overall 12:9 (4:3) landscape canvas.
- **Left Container (50% Width):**
  - Margins: 32px padding all sides.
  - Header: Subtitle (Mystery Set), Title (Decade), Fruit tag.
  - Body: Scroll-free RichTextLabel with crisp font rendering.
  - Bead Tracker: An intuitive 10-bead indicator showing decade progress.
- **Right Container (50% Width):**
  - Margins: 16px padding with elegant inner border or subtle shadow frame.
  - TextureRect: `expand_mode = EXPAND_IGNORE_SIZE`, `stretch_mode = STRETCH_KEEP_ASPECT_CENTERED`.
  - Attribution caption footer: Artist, Title, Year, Source Institution.

### 3.2 Navigation & Controls
- **Top / Sidebar Navigation Tabs:** Direct access to:
  - Intro Prayers
  - Joyful Mysteries (Decades 1–5)
  - Luminous Mysteries (Decades 1–5)
  - Sorrowful Mysteries (Decades 1–5)
  - Glorious Mysteries (Decades 1–5)
  - Concluding Prayers
- **Page Flipping Controls:**
  - Previous / Next buttons.
  - Keyboard shortcuts (Left/Right Arrow, PageUp/PageDown, Space).
  - Touch swipe gestures for mobile/tablet.

### 3.3 Mobile / Portrait Mode Adaptation
- When viewport aspect ratio is portrait (height > width):
  - Provide a toggle or swipeable layout between the **Art View** and **Prayer Text View**, or split layout (Top: Art, Bottom: Prayer Text).

---

## 4. Data Architecture & Asset Guidelines

### 4.1 Data Structure
- `res://data/mysteries.json` (or GDScript typed resources in `res://resources/`):
  - Array of Mystery Groups (`id`, `title`, `days`, `decades`).
  - Decades contain:
    - `decade_number`: int (1..5)
    - `title`: String
    - `scripture_ref`: String
    - `scripture_text`: String
    - `fruit`: String
    - `meditation`: String
    - `image_path`: String
    - `art_title`: String
    - `art_artist`: String
    - `art_year`: String
    - `art_source`: String

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
