# Pull Request Review, Documentation & Merge Standards

This document establishes the official standards and workflow for reviewing, documenting, and merging Pull Requests in the **Pray The Rosary** repository, whether handled by a human developer or an autonomous agent.

---

## 1. Role Overview & Responsibilities

The **PR Reviewer & Documentation Agent** acts as the quality gatekeeper and documentation steward for the repository.

### Primary Responsibilities
1. **Review Diff & Context:** Inspect the Pull Request description, code diff, and automated test results provided by the Issue Resolver.
2. **Verify Acceptance Criteria:** Confirm that all criteria in the linked issue are satisfied.
3. **Visual QA & Asset Verification:** Verify UI changes using MCP visual QA (`python mcp_client.py screenshot`) and verify that all referenced asset paths exist on disk.
4. **Synchronize Documentation:** Update `documents/requirements.md`, `documents/manual_testing.md`, and `README.md` on the feature branch to keep all project documentation strictly aligned with code changes.
5. **Clean Up Worktrees & Merge to Main:** Remove the feature worktree, perform a standard Git merge commit (preserving full history), and delete the feature branch.
6. **Workspace Synchronization:** Pull latest `main` into the root repository and re-register assets.

---

## 2. Review Checklist

Before approving or merging any Pull Request, verify the following:

### 1. Pre-Review & Dependency Check
* [ ] **Dependencies Resolved:** If the linked issue or PR mentions `Depends on #<number>`, confirm that all dependency issues are `CLOSED` and their PRs are already merged into `main`.
* [ ] **Reviewer Handoff Notes:** Check the PR description's **"Handoff for PR Reviewer & Documentation Agent"** section for specific documentation and testing notes provided by the resolver.

### 2. Code Quality & Standards
* [ ] **Static Typing:** GDScript code strictly uses static typing for all variables, function arguments, and return types.
* [ ] **Naming Conventions:** Classes/Nodes use `PascalCase`; functions/variables/signals use `snake_case`; constants use `UPPER_SNAKE_CASE`.
* [ ] **Logging:** No raw `print()` statements in gameplay or UI scripts. Uses `print_debug()`, `push_warning()`, or `push_error()`.
* [ ] **Comments:** Explains the *why*, not the obvious *what*.
* [ ] **Asset Verification:** Any file paths referenced in configuration files (like `export_presets.cfg` or `project.godot`) or dynamically constructed in GDScript must actually exist on disk.
* [ ] **Source Verification Ledger (`documents/references.md`):** If the PR touches `game/data/prayers.json`, `game/data/mysteries.json`, `game/data/book_layout.json`, `assets/2D/gimp/attributions.json`, or any sacred text, verify that all prayers, Scripture citations, and artwork metadata match the primary source citations in `documents/references.md`, and confirm that `documents/references.md` has been updated and synchronized per `.agents/rules/references_verification.md`.

### 3. Testing Verification
* [ ] **Automated Test Report:** PR body includes evidence that all automated tests pass (`Test Results: X Passed, 0 Failed`).
* [ ] **Independent Test Execution:** Reviewer independently runs the test suite on the checked-out branch and confirms zero failures.
* [ ] **Python Unit Tests:** Run `python -m unittest discover -s scripts -p "test_*.py" -v` and confirm 0 test failures.
* [ ] **Print PDF Asset Synchronization:** Confirm all eight tracked print PDFs (`assets/print/PrayTheRosary.pdf`, `assets/print/PrayTheRosary_Tabs.pdf`, `assets/print/PrayTheRosary_Tabs_Bleed.pdf`, `assets/print/Vervante/PrayTheRosary_Vervante.pdf`, `assets/print/Vervante/PrayTheRosary_Vervante_Covers.pdf`, `assets/print/Vervante/PrayTheRosary_Vervante_Interior.pdf`, `assets/print/Vervante/PrayTheRosary_Vervante_Tabs.pdf`, and `assets/print/Vervante/README_Print_and_Assembly_Guide.pdf`) have been rebuilt via `python scripts/build_print_pdf.py --all` and committed if book page styling, prayers, Scripture, typography, or version numbers changed.
* [ ] **New Tests Added:** If core logic, autoloads, or calculations were altered, corresponding unit tests are present in `game/tests/`.
* [ ] **Visual QA (MCP Bridge):** If the PR modifies UI or visual layout, launch the game locally and capture a screenshot via `python mcp_client.py screenshot` to verify the layout visually.

---

## 3. PR Inspection & Local Testing Protocol

All review operations (inspecting code, running automated tests, and committing documentation updates) take place within an isolated Git worktree under `.worktrees/`. Remember that in agent tool environments, each `run_command` call starts at the repository root, so always pass `-C <worktree_path>` to `git` and `--path <worktree_path>/game` to `godot`.

### 1. View PR Overview & Diff
Inspect the PR description and diff via the GitHub CLI:

> [!WARNING]
> **NEVER run a bare `gh pr view <pr_number>` command.** The repository's token configuration will trigger a `read:project` scope error for the bare command. You must ALWAYS use the `--json` flag:

```powershell
gh pr view <pr_number> --json title,body,state,baseRefName,headRefName,commits,files
gh pr diff <pr_number>
```

### 2. Locate or Create the Review Worktree
First inspect active worktrees:
```powershell
git worktree list
```
Git does not allow the same branch to be checked out in two worktrees at the same time:
* **If a local worktree for the feature branch already exists** (typically `.worktrees/issue-<number>` created by the Issue Resolver):
  Reuse that exact worktree path (`<worktree_path> = .worktrees/issue-<number>`) for testing and documentation commits.
* **If no worktree exists locally for the branch**:
  Fetch the branch and create `.worktrees/review-pr-<pr_number>`:
  ```powershell
  git fetch origin
  git worktree add .worktrees/review-pr-<pr_number> feature/issue-<number>-<short-description>
  ```

### 3. Run Automated Tests Locally
Inside the feature worktree (`<worktree_path>`), run the headless Godot asset import and test suite:
```powershell
godot --headless --editor --quit --path <worktree_path>/game
godot --headless --path <worktree_path>/game -s res://tests/test_runner.gd
```

Run the Python unit test suite:
```powershell
python -m unittest discover -s scripts -p "test_*.py" -v
```

---

## 4. Documentation Coordination (Mandatory Prior to Merge)

The reviewing agent is directly responsible for synchronizing project documentation with code changes inside `<worktree_path>/`:

### 1. `<worktree_path>/documents/requirements.md`
* Update existing requirement specifications or add new requirement IDs if functionality, UI dimensions, or constraints changed.

### 2. `<worktree_path>/documents/manual_testing.md`
* Add or update manual test scenarios to provide human testers and QA agents with reproduction and validation steps for the new functionality.

### 3. `<worktree_path>/README.md`
* Update if user-facing behavior, controls, rules, or visuals changed.

### 4. `<worktree_path>/documents/references.md`
* Verify that any additions, fixes, or modifications to prayers, Catholic Public Domain Version (CPDV) Scripture verses, historical summaries, or artwork metadata are verified against primary sources and recorded in `documents/references.md` in strict book order per `.agents/rules/references_verification.md`.

### Committing Documentation Updates
Commit documentation updates directly to the feature branch inside `<worktree_path>` **prior to merging**:
```powershell
git -C <worktree_path> add documents/ README.md
git -C <worktree_path> commit -m "docs: update requirements and manual testing for issue #<number>"
git -C <worktree_path> push origin feature/issue-<number>-<short-description>
```

---

## 5. Review Decisions & Protocol

### Scenario A: Changes Required
If the PR violates static typing, includes raw `print()` statements, lacks necessary test cases, fails the test suite, or does not meet the linked issue's acceptance criteria, **do not merge**. Submit a review requesting changes:
```powershell
gh pr review <pr_number> --request-changes --body "<Detailed description of what needs to be fixed>"
```

### Scenario B: Approved & Ready to Merge
Once all acceptance criteria are met, automated tests pass, and documentation is updated and pushed to the feature branch, proceed to merge.

#### 1. Stop Background Processes & Remove the Worktree Before Merging
Before calling `gh pr merge --delete-branch`, you **must** remove the worktree holding the feature branch (otherwise Git refuses to delete a branch checked out in an active worktree, and Windows locks `.godot/` if Godot is running):
```powershell
# Kill any background Godot instances, orphaned git processes, or open PDF viewers holding file locks
Stop-Process -Name "godot", "git", "Acrobat", "AcroRd32" -Force -ErrorAction SilentlyContinue

# Remove the worktree holding the feature branch and prune stale metadata
git worktree remove <worktree_path> --force
git worktree prune
```

#### 2. Merge the Pull Request
Merge using the GitHub CLI with a **standard merge commit** (preserving complete Git history):
```powershell
gh pr merge <pr_number> --merge --delete-branch
```
> [!IMPORTANT]
> **DO NOT squash** (`--squash`) or rebase (`--rebase`). Standard merge commits (`--merge`) preserve the detailed history of atomic commits in the repository.

#### 3. Verify Issue Closure
Confirm that the linked issue (`Resolves #<number>`) has transitioned to `CLOSED`:
```powershell
gh issue view <issue_number> --json state
```
If GitHub did not automatically close the issue:
```powershell
gh issue close <issue_number> --comment "Resolved via PR #<pr_number>."
```

#### 4. Local Repository Synchronization & Asset Re-registration
From the main project directory:
```powershell
# Prune worktree metadata
git worktree prune

# Ensure main is up to date with the newly merged PR
git checkout main
git pull origin main

# Delete local branch if lingering (use 2>$null, NOT -ErrorAction, with external git.exe)
git branch -d feature/issue-<number>-<short-description> 2>$null

# Force an editor import pass to register newly merged classes and assets
godot --headless --editor --quit --path game
```
