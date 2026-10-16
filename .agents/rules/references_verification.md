# Sacred Text, History, Scripture & Artwork Verification Rule (`documents/references.md`)

**CRITICAL DIRECTIVE FOR ALL AGENTS (Issue Creator, Issue Resolver, PR Reviewer):**

1. **CANONICAL VERIFICATION LEDGER**:
   - `documents/references.md` is the canonical, book-ordered verification ledger for all sacred content in **Pray The Rosary**.
   - It covers every page from Page 1 to Page 50 in sequential order: all 12 prayers, all 20 mysteries, all Douay-Rheims Scripture citations, all historical and doctrinal assertions, and all 23 master artwork attributions.

2. **CONSULT BEFORE MODIFYING**:
   - Whenever you create an issue, implement a feature or bug fix, or review a pull request that touches:
     - `game/data/prayers.json`
     - `game/data/mysteries.json`
     - `game/data/book_layout.json`
     - `assets/2D/gimp/attributions.json`
     - Or any sacred text, prayer, Scripture citation, meditation, fruit, or artwork attribution in code or scenes,
   - You **MUST** consult `documents/references.md` to verify accuracy against the cited authoritative primary sources (Vatican archives, USCCB, Douay-Rheims Bible Online, museum collection catalogs).

3. **MAINTAIN SYNCHRONIZATION**:
   - Any approved addition, alteration, or correction to prayers, Scripture verses, historical summaries, or artwork metadata MUST be simultaneously reflected and cited in `documents/references.md` with verifiable external URLs.
   - Never introduce unsourced prayers, apocryphal citations, or modified artwork attributions without documenting the verified primary sources in `documents/references.md`.

4. **URL INTEGRITY & ENCODING STANDARDS**:
   - All external hyperlinks in `documents/references.md` and project metadata must strictly use secure `https://` protocol (zero insecure `http://` links).
   - Any Markdown hyperlink `[text](url)` containing parentheses must have them percent-encoded (`(` as `%28` and `)` as `%29`) so that Markdown parsers do not prematurely truncate the destination URL at the first closing parenthesis.
   - Museum catalog references should include verified permanent catalog UUIDs/object numbers and permanent Wikidata authority entity records (`https://www.wikidata.org/wiki/Q...`).
   - Image assets must include human-readable Wikimedia Commons File dossier pages (`https://commons.wikimedia.org/wiki/File:...`) in addition to or in preference to raw image binary URLs.
   - Automated test suite assertions in `game/tests/test_rosary_data.gd` (`test_references_document_completeness_and_book_order()`) enforce these constraints.
