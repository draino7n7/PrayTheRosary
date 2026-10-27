"""
Canonical JSON data loader and cross-indexer for the Pray The Rosary print PDF pipeline.

Responsibilities:
  1. `get_project_version(root_dir)`: Dynamically reads `config/version` from `game/project.godot`
     so the Page 48 colophon automatically matches the Godot application release version.
  2. `load_all_data(project_root)`: Reads the three canonical data files shared between the
     interactive Godot 4 app and the print book generator:
       - `game/data/book_layout.json` (front/back cover text, 24 two-page spreads, colophons)
       - `game/data/prayers.json` (canonical prayer titles, leader/response splits, full texts)
       - `game/data/mysteries.json` (4 Mystery sets × 5 decades, Scripture citations, fruits,
         meditations, and artwork metadata)
     Cross-indexes mysteries and paintings by ID so page renderers can look up any decade or
     artwork attribution in O(1) time.
"""

import json
import re
from pathlib import Path
from typing import Any, Dict, Tuple


def get_project_version(root_dir: Path) -> str:
    """
    Dynamically extracts `application/config/version` from `game/project.godot`.

    Args:
        root_dir: Path to the repository root containing `game/project.godot`.

    Returns:
        The version string (e.g. `"1.0.2"`), or `"1.0.2"` as a safe fallback if
        `project.godot` is absent (such as in isolated temporary test directories).
    """
    godot_file = root_dir / "game" / "project.godot"
    if godot_file.exists():
        content = godot_file.read_text(encoding="utf-8")
        match = re.search(r'config/version="([^"]+)"', content)
        if match:
            return match.group(1).strip()
    return "1.0.2"


def load_all_data(
    project_root: Path,
) -> Tuple[Dict[str, Any], Dict[str, Any], Dict[str, Any], Dict[str, Any], Dict[str, Any]]:
    """
    Loads all canonical JSON data files from `game/data/` and builds cross-indexed lookup maps.

    How Cross-Indexing Works:
      - `mysteries_by_id`: Maps each mystery ID (e.g., `"joyful_1"`) to its decade dictionary
        from `mysteries.json`. Used when rendering Spreads 3..22 (`mystery_spread`).
      - `artworks_by_id`: Maps each artwork ID (e.g., `"cover"`, `"opening_prayers"`,
        `"joyful_1"`, `"closing_prayers"`) to a shallow copy of its artwork metadata dictionary
        augmented with a human-readable `"section_label"` (such as `"Front Cover"`,
        `"Opening Prayers"`, or `"1st Joyful Mystery (The Annunciation)"`). Used when rendering
        Pages 48 & 49 (`Sacred Artwork Credits`).

    Args:
        project_root: Path to the repository root directory.

    Returns:
        A 5-tuple `(book_layout, prayers, mysteries_raw, mysteries_by_id, artworks_by_id)`.
    """
    data_dir = project_root / "game" / "data"

    with open(data_dir / "book_layout.json", "r", encoding="utf-8") as f:
        book_layout: Dict[str, Any] = json.load(f)

    with open(data_dir / "prayers.json", "r", encoding="utf-8") as f:
        prayers: Dict[str, Any] = json.load(f)["prayers"]

    with open(data_dir / "mysteries.json", "r", encoding="utf-8") as f:
        mysteries_raw: Dict[str, Any] = json.load(f)

    mysteries_by_id: Dict[str, Any] = {}
    artworks_by_id: Dict[str, Any] = {}
    ordinal_map = {1: "1st", 2: "2nd", 3: "3rd", 4: "4th", 5: "5th"}

    # 1. Index all 20 Mysteries and their corresponding master paintings
    for mset in mysteries_raw["mystery_sets"]:
        short_title = mset.get("short_title", "").strip()
        for dec in mset["decades"]:
            mid = dec["id"]
            mysteries_by_id[mid] = dec
            art = dict(dec.get("artwork", {}))
            if art:
                dnum = int(dec.get("decade_number", 1))
                dtitle = dec.get("title", "").strip()
                art["section_label"] = f"{ordinal_map.get(dnum, f'{dnum}th')} {short_title} Mystery ({dtitle})"
                artworks_by_id[art.get("id", mid)] = art

    # 2. Index the Front Cover artwork (Murillo's Madonna of the Rosary)
    cover_art = dict(book_layout["front_cover"]["artwork"])
    cover_art["section_label"] = "Front Cover"
    artworks_by_id["cover"] = cover_art

    # 3. Index non-mystery spread artworks (Opening Prayers & Closing Prayers)
    for sp in book_layout["spreads"]:
        rp_art = sp.get("right_page", {}).get("artwork")
        if rp_art:
            rp_art_copy = dict(rp_art)
            aid = rp_art_copy["id"]
            if aid == "opening_prayers":
                rp_art_copy["section_label"] = "Opening Prayers"
            elif aid == "closing_prayers":
                rp_art_copy["section_label"] = "Closing Prayers"
            artworks_by_id[aid] = rp_art_copy

    return book_layout, prayers, mysteries_raw, mysteries_by_id, artworks_by_id
