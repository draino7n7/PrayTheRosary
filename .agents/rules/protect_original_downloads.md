# Archival Artwork Protection (`assets/2D/gimp/original_downloads/`)

**CRITICAL DIRECTIVES FOR ALL AGENTS:**

1. **DO NOT TOUCH `assets/2D/gimp/original_downloads/`**:
   - All 23 `.jpg` files inside `assets/2D/gimp/original_downloads/` are **unmodified, byte-for-byte original archival downloads** from museum open-access repositories and Wikimedia Commons.
   - You are **strictly forbidden** from modifying, cropping, resizing, re-encoding, overwriting, renaming, moving, or deleting any file inside `assets/2D/gimp/original_downloads/`.

2. **READ-ONLY SOURCE OF TRUTH**:
   - Treat `assets/2D/gimp/original_downloads/` as a **read-only** input directory.
   - When creating GIMP projects, cropped print masters, or downscaled game textures:
     - Read from `assets/2D/gimp/original_downloads/<filename>.jpg`.
     - Save working GIMP project files (`.xcf`) or cropped print derivatives into `assets/2D/gimp/` (outside `original_downloads/`).
     - Save runtime game textures (`.webp` / `.png` / `.jpg`) into `game/assets/`.
