# Issue Resolution Workflow & Standards

This document establishes the official standards, Git worktree workflow, and coding guidelines for anyone resolving issues in the **Pray The Rosary** repository, whether human contributor or autonomous agent.

---

## 0. Operational Rules
* **PowerShell Chaining:** When executing shell commands, NEVER use `&&` to chain commands together (it requires PowerShell 7+). Instead, use `;` or execute commands sequentially in separate tool calls.
* **Stateless Shell Sessions:** In agent tool execution, each command runs in a new shell session starting at the repository root. Working directory changes do not persist. When working inside a worktree, always target paths explicitly: `git -C .worktrees/issue-<number> ...` and `godot --headless --path .worktrees/issue-<number>/game ...`.
* **File Generation Encoding:** Generating text files via PowerShell pipes (e.g., `>` or `Set-Content`) or .NET APIs often creates UTF-16 LE encoding errors or adds a UTF-8 BOM (Byte Order Mark). Godot will completely fail to parse `.tscn` files that contain a BOM (`Parse Error: Expected '['`). ALWAYS use the native `write_file` and `edit_file` agent tools to generate or edit text and script files to ensure proper UTF-8 encoding without BOMs.
* **Documentation Redundancy:** Before requesting the PR Reviewer to document a feature or testing steps, always verify if the documentation already exists in `documents/requirements.md` or `documents/manual_testing.md`. Do not duplicate existing specification notes.
* **Source Verification Ledger (`documents/references.md`):** Whenever modifying or adding prayers, Scripture citations, mysteries, meditations, historical summaries, or artwork attributions, you MUST consult `documents/references.md` and comply with `.agents/rules/references_verification.md`. Verify all textual and metadata changes against the cited authoritative primary sources (Vatican archives, USCCB, Catholic Public Domain Version via SacredBible.org / GitHub cpdv, Douay-Rheims Bible Online comparative reference, museum collection catalogs) and maintain source synchronization in `documents/references.md`.
* **Print PDF Pipeline Synchronization (`scripts/build_print_pdf.py`):** Whenever modifying book page visual styling, typography rules, prayer/Scripture text, or `game/data/*.json` structure, you MUST keep `scripts/build_print_pdf.py` synchronized and verify Python unit tests (`python -m unittest discover -s scripts -p "test_*.py" -v`). When book layout, text content, or version numbers change, regenerate all eight tracked print PDFs via `python scripts/build_print_pdf.py --all` (`assets/print/PrayTheRosary.pdf`, `assets/print/PrayTheRosary_Tabs.pdf`, `assets/print/PrayTheRosary_Tabs_Bleed.pdf`, `assets/print/Vervante/PrayTheRosary_Vervante.pdf`, `assets/print/Vervante/PrayTheRosary_Vervante_Covers.pdf`, `assets/print/Vervante/PrayTheRosary_Vervante_Interior.pdf`, `assets/print/Vervante/PrayTheRosary_Vervante_Tabs.pdf`, and `assets/print/Vervante/README_Print_and_Assembly_Guide.pdf`).

---

## 1. Role Overview & Core Boundaries

The **Issue Resolver** is responsible for taking an open issue from conception to an unmerged, thoroughly tested, and documented Pull Request.

### Primary Responsibilities
1. **Triage & Select:** Identify the next unblocked issue based on issue number and dependencies.
2. **Worktree Isolation:** Create and work within an isolated Git worktree under `.worktrees/`.
3. **Implement:** Write clean, modular, and statically typed GDScript code meeting all acceptance criteria.
4. **Test:** Run the automated test suite, perform visual QA via MCP, and add new automated tests in `game/tests/`.
5. **Detailed Pull Request:** Push the feature branch and submit a highly detailed PR against `main`.

### Explicit Boundaries (What the Issue Resolver Does NOT Do)
* **DO NOT merge into `main`:** The Issue Resolver must never merge the PR or push directly to `main`.
* **Documentation Boundary:** By default, updating `documents/requirements.md`, `documents/manual_testing.md`, or `README.md` is handled by the **PR Reviewer & Documentation Agent** using the resolver's PR handoff notes. **Exceptions:**
  1. Whenever modifying prayers, Scripture citations, mysteries, historical prose, or artwork attributions, the Issue Resolver **MUST** update `documents/references.md` to keep the canonical source ledger synchronized.
  2. When a data or docs-focused issue's Acceptance Criteria or orchestrator prompt explicitly mandates updating `documents/requirements.md` or `documents/manual_testing.md`, the Issue Resolver should update those files directly as part of the PR (and the PR Reviewer will verify them prior to merge).

---

## 2. Issue Discovery & Triage Protocol

When tasked with resolving an issue, follow this triage procedure:

### 1. Inspect Open Issues
List open issues via the GitHub CLI:
```powershell
gh issue list --state open
```

> [!WARNING]
> **NEVER run a bare `gh issue view <id>` command.** The repository's token configuration will trigger a `read:project` scope error for the bare command. You must ALWAYS use the `--json` flag to avoid this error:

```powershell
gh issue view <issue_number> --json title,body,state,labels,assignees
```

### 2. Dependency Checking (`Depends on #X`)
* Read the issue description carefully.
* If the issue header contains **`Depends on #<number>`**, check the status of the dependency:
  ```powershell
  gh issue view <dependency_number> --json state
  ```
* If the dependency issue is still `OPEN`, **do not begin work on this issue**. Move to the next unblocked issue or report the blocker.
* Only begin work if all dependencies are `CLOSED` and their pull requests merged into `main`.

### 3. Issue Selection Strategy
Unless instructed to work on a specific issue:
1. Select the lowest-numbered open issue that has no open dependencies.
2. If multiple issues are ready, prioritize bugs and foundational features (`core`, `autoloads`) before downstream UI enhancements.

---

## 3. Git Worktree & Branching Workflow

All work must occur inside an isolated worktree to keep the primary working tree clean.

### 1. Ensure `main` is Synchronized
```powershell
git checkout main
git pull origin main
```

### 2. Create the Worktree
Create a new feature branch and isolated worktree inside `.worktrees/`:
```powershell
git worktree add .worktrees/issue-<number> -b feature/issue-<number>-<short-description>
```
*Example:*
```powershell
git worktree add .worktrees/issue-21 -b feature/issue-21-absent-color-red
```

### 3. Commit Guidelines
* Follow [Conventional Commits](https://www.conventionalcommits.org/):
  * `feat: <description>` for new features
  * `fix: <description>` for bug fixes
  * `test: <description>` for test additions
  * `refactor: <description>` for code restructuring
* Keep commits atomic, well-described, and focused on the issue.

---

## 4. Coding & Architecture Standards

### Godot 4.x & GDScript Standards
1. **Static Typing Everywhere:**
   * Always annotate variable types and function returns. This applies equally to production scripts AND unit test files (`tests/*.gd`).
   * Dynamic node lookups (`get_node()`, `get_node_or_null()`) MUST include explicit type annotations and type casting:
     ```gdscript
     var my_label: Label = get_node_or_null("Header/Title") as Label
     ```
2. **Metadata Files (`.uid`):**
   * Godot 4 generates `.uid` metadata files alongside `.gd` scripts, scenes, and assets. Always stage and commit these `.uid` files alongside your changes.
3. **Naming Conventions:**
   * **Classes & Nodes:** `PascalCase` (e.g., `Main`, `NavigationDrawer`, `BasePageCard`)
   * **Variables & Functions:** `snake_case` (e.g., `current_page`, `_on_page_selected()`)
   * **Constants:** `UPPER_SNAKE_CASE` (e.g., `TOTAL_PAGES = 50`, `COLOR_GOLD`)
   * **Signals:** `snake_case` in past tense or action oriented (e.g., `page_changed`, `drawer_toggled`)
4. **UI Design & Responsiveness:**
   * When using `GridContainer`, Godot natively ignores invisible children (`visible = false`), causing remaining nodes to reflow. If you need fixed slot positions, keep nodes visible and clear text or modulate opacity.
   * Root screen scripts are responsible for explicitly wiring child components to domain models. Verify that methods invoked on child nodes actually exist on those component scripts before calling them.
5. **Commenting & Documentation:**
   * Do not write redundant comments stating the obvious.
   * Document the *intent*, *assumptions*, or mathematical and algorithmic logic.
   * Every autoload and major script must contain a header docstring explaining its domain responsibility.
6. **Font Fallbacks & Unicode UI Symbols (Cross-Platform / Web Export):**
   * When UI controls display Unicode symbols (such as hamburger menu `☰`, close `✕`, disclosure arrows `▸` / `▾`, or stars `★`), NEVER replace the primary serif font (`EB Garamond`) with a `SystemFont` or change font metrics globally, as doing so breaks book page layout metrics, text line heights, and margin auto-fitting.
   * On Web / HTML5 (WASM), browser sandboxing prevents Godot from querying host OS system fallback fonts, causing missing glyphs to render as tofu boxes (`□`).
   * Always bundle an open-source OFL symbol font (`NotoSansSymbols-Regular.ttf`) and configure it strictly as a **fallback**:
     - In `.import` files: add `NotoSansSymbols-Regular.ttf` to `fallbacks` of the primary font.
     - In theme resources (`rosary_theme.tres`): wrap base fonts using `FontVariation` sub-resources with `fallbacks = [NotoSansSymbols]`.
     - In programmatic UI loaders: wrap base fonts in a `FontVariation` and assign `fv.fallbacks = [font_symbols]`.

---

## 5. Logging Standards

Avoid raw `print()` statements in production code. Use categorized, engine-native logging:
* `print_debug(...)`: Diagnostic info and state transitions (e.g., `print_debug("Main: Loaded page %d" % page_num)`).
* `push_warning(...)`: Non-fatal issues or recoverable conditions (e.g., `push_warning("ReadingProgressManager: Corrupted save file detected, resetting.")`).
* `push_error(...)`: Critical logic failures or invariant violations.

---

## 6. Automated Testing Standards

Every feature or bug fix touching game logic, autoloads, or page hydration must be backed by automated tests.

### Agentic Visual QA (MCP Bridge)
If your issue involves UI layout, coloring, or visual polish, you MUST visually verify your changes before submitting the PR:
1. Ensure no stale Godot instance holds port 9090:
   ```powershell
   Stop-Process -Name "godot" -Force -ErrorAction SilentlyContinue
   ```
2. Start a fresh instance of the game in the background:
   ```powershell
   godot --path .worktrees/issue-<number>/game
   ```
   This fresh instance will automatically spin up the `McpInteractionServer` AutoLoad.
3. Verify bridge readiness and inspect:
   ```powershell
   python mcp_client.py ping
   python mcp_client.py screenshot
   python mcp_client.py get_ui_elements
   ```
4. Visually inspect `screenshot.png` with `view_file` to confirm there is no text clipping, overlap, missing glyphs, or broken alignment.
5. **CRITICAL:** Once your visual QA is complete, you must kill the background task running the Godot process to close the window and free up port 9090 and Windows file locks:
   ```powershell
   Stop-Process -Name "godot" -Force -ErrorAction SilentlyContinue
   ```

### Test Architecture
* Tests are located in `game/tests/`.
* Test scripts inherit from `res://tests/test_base.gd`.
* Every test method starts with `test_`.
* Assertions use `assert_true()`, `assert_false()`, `assert_eq()`, `assert_ne()`, `assert_gt()`, `assert_gte()`, `assert_lt()`, `assert_lte()`, `assert_approx()`, `assert_null()`, `assert_not_null()`, `assert_contains()`, and `assert_file_exists()`.
* Per-test setup and teardown: override `before_each() -> void` and `after_each() -> void` on `TestBase` subclasses.
* Suite teardown: override `cleanup() -> void`.
* **CRITICAL**: When modifying UI layout or styling, write lightweight structural unit tests verifying component properties (e.g., font sizes, minimum dimensions, custom themes).
* **CRITICAL**: When adding an Autoload, configuring an asset path in `project.godot`/`export_presets.cfg`, or generating resources, assert `FileAccess.file_exists(...)` for that exact path to ensure the asset actually exists.
* **CRITICAL**: GDScript lambdas capture primitives by VALUE, not by reference. When using inline lambdas to verify signal emissions, capture variables via an `Array` wrapper (e.g., `var count: Array[int] = [0]`) or an object property.
* **CRITICAL**: The `test_runner.gd` does not initialize `project.godot` autoloads natively. To ensure testability, avoid hardcoded singleton identifier calls inside `RefCounted` or core logic classes. Use dependency injection, mock nodes, or look up peer singletons dynamically using `/root/SingletonName`.
* **CRITICAL**: When testing `Control` nodes headlessly, `_ready()` is NOT invoked organically unless nodes enter the scene tree. Use `test_root_window.add_child(node)` or build a mock SceneTree structure in your test setup, and clean up with `.free()` in teardown.

### Running Automated Tests
Run the headless Godot test suite. First, **CRITICALLY**, force an editor import pass to cache any newly added binary files or `class_name` definitions:
```powershell
godot --headless --editor --quit --path game
godot --headless --path game -s res://tests/test_runner.gd
```
*(When inside a worktree, pass `--path .worktrees/issue-<number>/game`).*

Run the Python unit test suite:
```powershell
python -m unittest discover -s scripts -p "test_*.py" -v
```

If your changes modify book page visual styling, typography rules, prayers, Scripture, or `game/data/*.json` structure, also rebuild all eight tracked print PDFs:
```powershell
python scripts/build_print_pdf.py --all
```

### Verification Gate
* **Zero Failures:** All existing and newly created tests must pass (`Test Results: X Passed, 0 Failed` in Godot, and `OK` across all Python tests, exit code 0).
* **Print PDF Synchronization:** If book layout, prayers, typography, or version numbers were changed, confirm that all eight tracked print PDFs (`assets/print/PrayTheRosary.pdf`, `assets/print/PrayTheRosary_Tabs.pdf`, `assets/print/PrayTheRosary_Tabs_Bleed.pdf`, `assets/print/Vervante/PrayTheRosary_Vervante.pdf`, `assets/print/Vervante/PrayTheRosary_Vervante_Covers.pdf`, `assets/print/Vervante/PrayTheRosary_Vervante_Interior.pdf`, `assets/print/Vervante/PrayTheRosary_Vervante_Tabs.pdf`, and `assets/print/Vervante/README_Print_and_Assembly_Guide.pdf`) were rebuilt via `python scripts/build_print_pdf.py --all` and committed.
* If any test fails, resolve the regression before pushing.

---

## 7. Submitting the Pull Request

Once the fix is implemented and verified:

### 1. Push Feature Branch
```powershell
git -C .worktrees/issue-<number> push -u origin feature/issue-<number>-<short-description>
```

### 2. Create the Pull Request
Submit the PR targeting `main` using GitHub CLI. Always write the PR body to a temporary markdown file using `write_file`, then pass `--body-file` to prevent PowerShell string-escaping issues:

```powershell
gh pr create --title "<type>: <concise description> (Resolves #<number>)" --body-file pr_body.md --base main
Remove-Item -Path pr_body.md -Force -ErrorAction SilentlyContinue
```

### Required PR Body Structure
Every PR submitted by an Issue Resolver must include:
1. **Closes / Resolves Link:** `Resolves #<number>`
2. **Problem & Context:** Summary of the issue being addressed and root cause.
3. **Key Changes & Technical Scope:** Detailed breakdown of modified, added, or deleted files with architectural rationale.
4. **Automated Test Results:** Test execution output confirming pass count and new test methods introduced.
5. **Handoff for PR Reviewer & Documentation Agent:**
   * Specific recommendations on which sections of `documents/requirements.md` need updates.
   * Recommended manual test cases for `documents/manual_testing.md`.
   * Any `README.md` updates if player-facing UI/mechanics changed.

### 3. Stop and Stand Down
After opening the PR:
* **Do not merge the pull request.**
* **Do not delete the worktree yet** (it will be reused and cleaned up by the reviewer agent).
* Report the PR URL and summary back to the user or orchestrator.
