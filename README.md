# Pray The Rosary

An interactive prayer companion and visual contemplation guide for the Holy Rosary, built with **Godot 4.7.2** for the **OpenGameStack (OGS)** ecosystem and designed as the digital foundation for a high-quality printed prayer book.

## About the Project

*Pray The Rosary* bridges digital devotions with classical fine art and traditional book design. Designed around a two-page spread concept mirroring a 6" x 9" spiral-bound prayer book:
- **Left Page / Side:** Clear, distraction-free prayers for each decade (Apostles' Creed, Our Father, Hail Marys, Glory Be, Fatima Prayer), alongside scriptural passages and meditative reflections. Everything needed to pray the decade is presented on a single screen without cumbersome scrolling.
- **Right Page / Side:** Large, contemplative public-domain Sacred Art masterpieces (from renowned institutions like the National Gallery of Art and The Metropolitan Museum of Art) corresponding to each mystery.
- **Structured Content Architecture:** All mysteries, prayers, scripture verses, and art metadata are organized as structured data, serving as the single source of truth for both the interactive application and future printed book layout exports.

### The Four Mysteries
1. **The Joyful Mysteries** (The Annunciation, The Visitation, The Nativity, The Presentation, The Finding in the Temple)
2. **The Luminous Mysteries** (The Baptism in the Jordan, The Wedding at Cana, The Proclamation of the Kingdom, The Transfiguration, The Institution of the Eucharist)
3. **The Sorrowful Mysteries** (The Agony in the Garden, The Scourging at the Pillar, The Crowning with Thorns, The Carrying of the Cross, The Crucifixion)
4. **The Glorious Mysteries** (The Resurrection, The Ascension, The Descent of the Holy Spirit, The Assumption of Mary, The Coronation of Mary)

---

## Assets & Visual Theme

- **Classical Typography (`game/assets/fonts/`):** Bundles **EB Garamond** (SIL Open Font License 1.1) across Regular, Bold, Italic, and BoldItalic weights.
- **Runtime Sacred Art Textures (`game/assets/images/`):** Contains 23 optimized runtime `.webp` textures generated from archival public-domain masterpieces in `assets/2D/gimp/original_downloads/` (quality 85, max height 1800px, aspect ratio strictly preserved).
- **Application Theme (`game/resources/rosary_theme.tres`):** Canonical Godot theme configured with an illuminated manuscript palette featuring warm ivory parchment (`#FAF6EE`), Marian crimson headers (`#6B1D21`), deep charcoal text (`#1E1815`), warm umber rubrics (`#5C4338`), and antique gold borders (`#B89130`).

---

## 2:3 Portrait Page Card Architecture

The UI is built around a modular page card component architecture designed for the continuous 50-page vertical scroll:
- **Unified Root Facade (`game/scenes/ui/page_card.tscn` / `game/scripts/ui/page_card.gd`):** Uses Godot's `AspectRatioContainer` (`ratio = 2.0 / 3.0`) to enforce a clean 2:3 portrait card geometry across mobile, tablet, and desktop display viewports.
- **Specialized Sub-Cards (`game/scenes/ui/pages/`):** Dynamically instantiates the appropriate sub-card component for each page type:
  - `CoverPageCard`: Full-bleed Murillo painting with gold/ivory title typography in the drapery.
  - `FrontMatterPageCard`: History and guide spreads on ivory parchment panels.
  - `PrayerSequencePageCard`: Opening (Page 4) and closing (Page 46) prayer sequences with rubrics.
  - `MysteryPrayerPageCard`: Decade prayers, fruit badge, scripture passage, and meditation.
  - `ArtworkPageCard`: Centered, uncropped sacred art painting in an antique gold frame with strictly no captions or page numbers.
  - `CreditsPageCard`: Comprehensive artwork attributions across Pages 48 and 49.
  - `BackCoverPageCard`: Deep crimson card with Pope St. John Paul II's epigraph and book synopsis.
- **Data-Driven Hydration:** Cards are hydrated directly from `RosaryDataLoader` via `PageCard.create_for_page(page_data, loader)` or `card.bind_page_data(page_data, loader)`.

---

## OpenGameStack Integration

This project is configured as an **OpenGameStack (OGS)** project. It includes `stack.json` and `ogs_config.json` files which define the exact environment (Godot 4.7.2) required to run and build the application.

To get started with OGS:
1. Download the [OGS Launcher](https://github.com/OpenGameStack-Launcher/ogs-launcher).
2. Open the OGS Launcher and click **Add Project** to register this repository.
3. The launcher will read `stack.json` and automatically provide the correct Godot version and dependencies.

---

## Running and Testing

### Headless Unit Tests
To run the automated test suite locally:
```powershell
godot --headless --path game -s res://tests/test_runner.gd
```

---

## AI Agent Integration (MCP)

This project integrates the Model Context Protocol (MCP) to allow AI assistants (like Claude Desktop, Cursor, or Antigravity) to directly interact with the running game.

The `McpInteractionServer` is pre-registered as an AutoLoad (`res://autoloads/mcp_interaction_server.gd`). When you run the application, it exposes a local TCP bridge on port `9090`.

### Python Client for Agents
A lightweight CLI script `mcp_client.py` is included in the project root:
```powershell
python mcp_client.py screenshot      # Captures visual snapshot
python mcp_client.py click 360 640   # Sends click input
python mcp_client.py get_scene_tree  # Returns full SceneTree hierarchy
python mcp_client.py get_ui_elements # Lists interactive UI controls
python mcp_client.py raw '<json>'    # Sends custom MCP JSON payload
```

---

## Cross-Platform Builds & CI/CD

This repository includes production-tested GitHub Actions workflows:
- **Android Release (`android_release.yml`):** Automatically triggers on tag push (`v*`). Runs headless tests, validates 16 KiB page size compliance, builds an Android App Bundle (`.aab`), signs the bundle, and publishes release assets.
- **Web Release (`web_release.yml`):** Automatically builds an HTML5 Web export and attaches a zip archive to GitHub Releases.
- **GL Compatibility Renderer:** Configured with `gl_compatibility` (OpenGL ES 3.0 / WebGL 2.0), guaranteeing optimal compatibility across Web, Desktop, and Mobile.

---

## Git LFS Requirement

This repository uses [Git Large File Storage (LFS)](https://git-lfs.com/) for artwork and binary assets.
1. Ensure Git LFS is installed on your machine (`git lfs install`).
2. `.gitattributes` tracks images, audio, fonts, and model assets automatically.

---

## License

This project uses a split license:
- **Source Code:** Licensed under the [GNU General Public License v3.0 (GPLv3)](LICENSE).
- **Assets & Media:** Unless otherwise specified, art and assets in `game/assets/` are licensed under [Creative Commons Attribution-ShareAlike 4.0 (CC BY-SA 4.0)](LICENSE-ASSETS) or are in the Public Domain (CC0 / Open Access).
