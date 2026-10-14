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
  - Murillo's *The Virgin of the Rosary* (`cover.webp`) fills the card in full bleed without distortion.
  - Title "Pray the Rosary" and subtitle "A Contemplative Visual Guide to the Twenty Mysteries" are positioned over the upper crimson drapery in warm gold (`#D4AF37`) and ivory (`#F7F2E7`) serif typography.
  - The Virgin and Christ Child remain fully unobstructed in the center/foreground.
  - Strictly no numerical page numbers appear.

### TC-PAGE-02: Front-Matter Text Cards (`Pages 2 & 3`)
- **Step 1:** Inspect Page 2 (*The History of the Holy Rosary*) and Page 3 (*Structure of the Book & How to Pray*).
- **Expected:**
  - Rendered on warm ivory parchment panels (`#FAF6EE`) with antique gold borders (`#B89130`).
  - Crimson section headings (`#6B1D21`), muted warm umber subtitles (`#5C4338`), and dark charcoal body paragraphs (`#1E1815`).
  - Text flows cleanly across all subsections without overflow or clipping.

### TC-PAGE-03: Prayer Sequence Cards (`Pages 4 & 46`)
- **Step 1:** Inspect Page 4 (*The Opening Prayers*) and Page 46 (*The Closing Prayers*).
- **Expected:**
  - Page 4 displays exactly 5 introductory prayer steps (Sign of the Cross, Apostles' Creed, Our Father, Three Hail Marys, Glory Be).
  - Page 46 displays exactly 4 concluding prayer steps (Hail, Holy Queen, Versicle & Response, Concluding Rosary Prayer, Sign of the Cross).
  - Distinct muted umber rubric tags (e.g., `[1×]`, `[10×]`, `[Sign of the Cross]`) precede each prayer item.

### TC-PAGE-04: Mystery Prayer Cards (`Even Pages 6, 8, 10, ..., 44`)
- **Step 1:** Inspect all 20 Mystery Prayer Cards.
- **Expected:**
  - Header displays mystery ordinal (e.g., *The First Joyful Mystery*), title (e.g., **The Annunciation**), and fruit badge (*Fruit of the Mystery: Humility*).
  - Douay-Rheims Scripture citation and contemplative meditation are clearly formatted.
  - Full text of the decade prayers (*Our Father*, *Hail Mary*, *Glory Be*, *Fatima Prayer*) fits on the card with zero internal scrolling.

### TC-PAGE-05: Sacred Artwork Cards (`Odd Pages 5, 7, 9, ..., 47`)
- **Step 1:** Inspect all 22 Artwork Cards (Opening, 20 Mysteries, Closing).
- **Expected:**
  - Top header band displays the mystery ordinal subheading and mystery title.
  - Painting renders centered inside the antique gold border (`#B89130`) preserving original aspect ratio.
  - Strictly **NO captions** (artist, museum, date) and **NO numerical page numbers** appear on the artwork card.

### TC-PAGE-06: Credits & Back Cover Cards (`Pages 48, 49, & 50`)
- **Step 1:** Inspect Pages 48 and 49 (*Sacred Artwork Credits Parts I & II*) and Page 50 (*Back Cover*).
- **Expected:**
  - Page 48 lists 13 attributions (Cover, Opening/Closing, Joyful 1–5, Luminous 1–5) with artist, dates, title, medium, and museum location.
  - Page 49 lists 10 attributions (Sorrowful 1–5, Glorious 1–5), Douay-Rheims Scripture notice, and museum open-access colophon.
  - Page 50 displays deep Baroque crimson (`#4A1215`) card with warm gold typography, Pope St. John Paul II's epigraph, book synopsis, and St. Louis Marie de Montfort's Marian counsel.

