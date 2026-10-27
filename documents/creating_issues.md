# GitHub Issue Creation Standard & Guidelines

This document outlines the standard specifications, structure, and workflow for creating GitHub issues for the **Pray The Rosary** project. Adhering to these standards ensures that any contributor—human developer or autonomous agent—can pick up an issue, understand the context and requirements without ambiguity, implement the change, and properly verify their work.

---

## 1. Principles & Quality Bar

Every issue created in this repository must meet the following criteria:
1. **Self-Contained & Actionable:** Provide all necessary context, architectural decisions, and acceptance criteria. A contributor should never have to guess design intent or look for unlinked resources.
2. **Clear Boundaries:** Group requirements logically by affected components (e.g., UI, Core Logic, AutoLoads, Tests, Documentation).
3. **Traceability:** Explicitly list any dependencies and note which documentation files need to be synchronized as part of the implementation.
4. **No Duplicates:** Always search open and closed issues (`gh issue list --state all`) before submitting a new issue.

---

## 2. Standard Issue Structure

All issues filed in Pray The Rosary must follow this standardized layout. When creating an issue on GitHub, use one of the predefined templates in `.github/ISSUE_TEMPLATE/`:
* **Bug Report (`.github/ISSUE_TEMPLATE/bug_report.md`):** For defects, unexpected behavior, logic bugs, or UI glitches. Pre-labeled with `bug`.
* **Feature Request (`.github/ISSUE_TEMPLATE/feature_request.md`):** For new gameplay mechanics, visual enhancements, or architectural improvements. Pre-labeled with `enhancement`.

Both templates implement the following required markdown structure:

```markdown
**Depends on #<issue_number>** (Include only if this issue has blockers)

### 1. Problem & Context
A concise explanation of the problem, bug, or feature request.
- For bugs: Reproduction steps, observed behavior, and expected behavior.
- For features/enhancements: User story, design motivation, and why the change improves the game.

### 2. Technical Scope & Affected Files
Direct references to the files, scenes, or scripts that need modification or inspection:
- `game/scripts/<script_name>.gd`
- `game/scenes/<scene_name>.tscn`
- `game/autoloads/<autoload_name>.gd`
- `game/tests/<test_name>.gd`

### 3. Acceptance Criteria
Checklist grouped by component or responsibility:

#### [Component / Feature Area 1]
- [ ] Explicit requirement 1
- [ ] Explicit requirement 2

#### [Component / Feature Area 2]
- [ ] Explicit requirement 3

#### Automated Tests (`game/tests/`, `scripts/`)
- [ ] Add or update unit test cases verifying the new behavior.
- [ ] Ensure all existing automated test suites pass without regressions (`godot --headless --path game -s res://tests/test_runner.gd` and `python -m unittest discover -s scripts -p "test_*.py"`).

#### Print PDF Pipeline Synchronization (Mandatory if page styling, typography, or data JSON change)
- [ ] Maintain and verify `scripts/build_print_pdf.py` and run `python -m unittest discover -s scripts -p "test_*.py"`.
- [ ] Regenerate `assets/print/PrayTheRosary.pdf`, `assets/print/PrayTheRosary_Tabs.pdf`, and `assets/print/PrayTheRosary_Tabs_Bleed.pdf` if page layout, text content, or version numbers change.

#### Documentation Coordination (Mandatory)
- [ ] Update `documents/requirements.md` to reflect any new or modified specifications.
- [ ] Update `documents/manual_testing.md` with new/updated manual verification test cases.
- [ ] Update `README.md` if user-facing behavior, controls, or visuals are altered.
```

---

## 3. Title & Labeling Conventions

### Title Format
Titles must be concise and use standard prefixes to indicate the area of the codebase:
- `UI - <Action/Description>` (e.g., `UI - Update Absent Letter Color to Flat Red`)
- `Core - <Action/Description>` (e.g., `Core - Validate Daily Seed Calculation`)
- `Stats - <Action/Description>` (e.g., `Stats - Fix Streak Reset on Loss`)
- `Docs - <Action/Description>` (e.g., `Docs - Update Architecture Diagram`)

Conventional commits format (`feat:`, `fix:`, `refactor:`, `docs:`) is also acceptable.

### Labels
Apply at least one standard GitHub label when creating the issue:
- `enhancement`: New features, visual improvements, or gameplay enhancements.
- `bug`: Defects, incorrect logic, UI glitches, or broken mechanics.
- `documentation`: Purely documentation-focused tasks.
- `good first issue`: Self-contained, straightforward tasks suitable for beginners.

---

## 4. Pre-Creation Checklist (For Authors & Agents)

Before publishing an issue via GitHub:
1. [ ] **Search Existing Issues:** Run `gh issue list --state all --json number,title,state` to confirm the issue doesn't already exist or duplicate past work. When inspecting a specific issue, **NEVER run bare `gh issue view <id>`** (which triggers a `read:project` token scope error); always pass `--json`: `gh issue view <id> --json number,title,body,state,labels`.
2. [ ] **Inspect Codebase:** Verify the exact file paths, variable names, and current behavior in the code. *(PowerShell tip: `Select-String` does not support `-Recurse`; use `Get-ChildItem -Recurse -File | Select-String -Pattern "<pattern>"` when searching across files via PowerShell, or use built-in search tools).*
3. [ ] **Clarify Design Choices:** Resolve any open design questions (e.g., color hex codes, UI behaviors, platform fallbacks) before publishing so the issue body contains firm decisions rather than open questions. When proposing prose edits to front-matter cards (`Pages 2 & 3`), note that `FrontMatterPageCard` computes `total_chars` as the sum of both section `title` and `body` lengths (`sum(len(s['title']) + len(s['body']) for s in sections)`) against the `1,650`-character density threshold.
4. [ ] **Include Documentation Acceptance Criteria:** Ensure the mandatory documentation coordination checklist is included per `documents/reviewing_and_merging_prs.md`.
5. [ ] **Check Canonical References Ledger (`documents/references.md`):** If proposing any additions, modifications, or fixes to sacred text, prayers, translations, Scripture citations, mysteries, historical summaries, or artwork attributions, consult `documents/references.md` and `.agents/rules/references_verification.md` to ensure doctrinal and archival accuracy, and include an acceptance criterion to keep `documents/references.md` synchronized.
6. [ ] **Print PDF Pipeline Impact (`scripts/build_print_pdf.py`):** If proposing changes that modify book page visual styling, typography rules, prayers/Scripture, or `game/data/*.json` structure, include explicit acceptance criteria requiring `scripts/build_print_pdf.py` maintenance, running `python -m unittest discover -s scripts -p "test_*.py"`, and regenerating `assets/print/PrayTheRosary.pdf`, `assets/print/PrayTheRosary_Tabs.pdf`, and `assets/print/PrayTheRosary_Tabs_Bleed.pdf`.

---

## 5. Creating Issues via GitHub CLI

Contributors and agents can create issues directly from the command line using the GitHub CLI (`gh`).

> [!WARNING]
> **NEVER run a bare `gh issue view <id>` command.** The repository's token configuration triggers a `read:project` scope error for bare view commands. Always pass `--json` (e.g., `gh issue view <id> --json number,title,body,state,labels`).

### Option A: Using Predefined Templates
You can invoke the repository issue templates directly with the `--template` flag:
```powershell
# Create a bug report using the bug_report.md template
gh issue create --template "bug_report.md"

# Create a feature request using the feature_request.md template
gh issue create --template "feature_request.md" --title "UI - Add Haptic Feedback on Keypress"
```

### Option B: Scripted / Headless Creation via `--body-file` (Recommended for Agents)
When generating or editing an issue programmatically on Windows PowerShell, **always write the markdown body to a temporary `.md` file** (using your file-writing tool in your scratch directory) and pass `--body-file` to `gh issue create` or `gh issue edit`, then delete the temporary file. This avoids PowerShell multiline quoting, backtick escaping, and newline distortion issues:
```powershell
# 1. Write the formatted markdown issue body to a temporary file (e.g., issue_body.md)
# 2. Create (or edit) the issue using --body-file:
gh issue create --title "<Prefix> - <Short Summary>" --body-file issue_body.md --label "<bug|enhancement>"
# Or when editing an existing issue:
# gh issue edit <issue_number> --title "<Prefix> - <Short Summary>" --body-file issue_body.md

# 3. Clean up the temporary file:
Remove-Item -Force issue_body.md
```

---

## 6. Reference Example

See [Issue #21: UI - Layout Guide](https://github.com/draino7n7/PrayTheRosary/issues/21) as an example of an issue meeting this standard.

