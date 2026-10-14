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
