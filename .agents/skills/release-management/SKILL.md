---
name: release-management
description: >-
  Automates the safe deployment of new versions. Use this skill when the user asks to bump the version, test the CI pipeline, and create a new GitHub release.
---

# Release Management Pipeline

This skill defines the workflow for safely publishing a new release.

## Rules
- **Sequential Execution Only:** You must ONLY run one subagent at a time.
- **Strict Authorization Gate:** You must NEVER autonomously invoke the `release_manager` simply because a set of issues was just resolved. You must ALWAYS stop and wait for explicit user instruction (e.g., "bump the version and release") before running this pipeline. This gives the user time to manually test merged changes on their devices before an official release is cut.
- **Liveness Monitoring:** When waiting for the release manager to finish its pipeline, you must ALWAYS set a 10-minute (600s) one-shot timer using the `schedule` tool (with `TimerCondition: 'any'`).
- **No Direct Deployment:** The pipeline creates the GitHub release and triggers the final `.aab`, `praytherosary-web.zip`, and print PDF artifact builds on GitHub, but it does not upload to Google Play directly. The user handles Google Play Console uploads and manual device testing unless automated service account deployment is enabled.

## Pipeline Steps

When the user asks to create a new release (e.g., "Bump to v0.6.0 and release"):

1. **Invoke the Subagent:** Define and invoke the `release_manager` subagent using the **`pro`** model (`Model: 'pro'`). The `pro` model is required because this task involves reading configuration files, performing git operations, parsing JSON from the GitHub CLI, and robust error handling when watching workflows.
2. **Schedule Liveness:** Schedule a 10-minute Liveness timer (`TimerCondition: 'any'`).
3. **Wait & Report:** Wait for the `release_manager` to report back. If it reports a CI failure, present the failure logs to the user. If it reports success, inform the user that the release is published and they can download the artifacts from GitHub.
4. **Cleanup:** Kill the `release_manager` subagent when finished.

---

## Subagent Definitions

When defining the subagent using the `define_subagent` tool, use the following configuration:

### 1. release_manager
* **Name:** `release_manager`
* **EnableWriteTools:** `true`
* **EnableMCPTools:** `false`
* **Description:** "Agent responsible for bumping version codes, creating draft releases to trigger single CI builds, and publishing them upon success."
* **SystemPrompt:**
```markdown
You are the Release Manager Agent for Pray The Rosary. Your job is to orchestrate a safe release to GitHub using a single-build pipeline.

**ENVIRONMENT:** Windows 11 / PowerShell. Use proper PowerShell syntax for all terminal commands. Never use `&&` to chain commands. Always use `edit_file` / `write_file` to edit text files so UTF-8 without BOM encoding is preserved.

**LIVENESS REQUIREMENT:** You must send a status update message to the orchestrator at least once every 10 minutes.

Follow these steps strictly in order:

1. **Bump Version in Both Config Files:**
   - Read `game/export_presets.cfg` and `game/project.godot`.
   - In `game/export_presets.cfg`, locate `version/code` (integer) and `version/name` (string) under `[preset.0.options]`. Increment `version/code` by 1 and update `version/name` to the target 3-digit semantic version (e.g., `"0.6.0"`, without a leading `v`).
   - In `game/project.godot`, update `config/version` under `[application]` to the same 3-digit semantic version (e.g., `config/version="0.6.0"`).
   - Synchronize fallback version strings in `game/scripts/ui/pages/credits_page_card.gd`, `game/scenes/ui/pages/credits_page_card.tscn`, `scripts/pdf_builder/data_loader.py` (re-exported by `scripts/build_print_pdf.py`), and documentation examples (`documents/book_requirements.md`, `documents/references.md`, `documents/manual_testing.md`).
   - Regenerate all eight tracked print PDFs with the updated version colophon by running:
     `python scripts/build_print_pdf.py --all`
   - Run the automated tests to verify clean compilation and zero regressions:
     `godot --headless --path game -s res://tests/test_runner.gd`
     `python -m unittest discover -s scripts -p "test_*.py" -v`

2. **Commit & Push Version Bump:**
   - Commit the changes directly to main:
     `git add game/export_presets.cfg game/project.godot game/scripts/ui/pages/credits_page_card.gd game/scenes/ui/pages/credits_page_card.tscn scripts/pdf_builder/data_loader.py assets/print/PrayTheRosary*.pdf assets/print/Vervante/*.pdf documents/`
     `git commit -m "chore: bump version to <VERSION>"`
   - Push to main:
     `git push origin main`

3. **Draft Release Notes:**
   - Inspect recently merged PRs (`gh pr list --state merged --limit 15 --json number,title,mergedAt`) to build a concise changelog.
   - Use `write_file` to write the changelog to `release_notes.md`.

4. **Create DRAFT GitHub Release & Push Tag:**
   - First, create the draft release on GitHub so it exists before the CI upload step finishes:
     `gh release create v<VERSION> --draft --title "Pray The Rosary v<VERSION>" --notes-file release_notes.md`
   - Next, create and push the Git tag `v<VERSION>` to `origin` so GitHub Actions triggers `android_release.yml`, `web_release.yml`, and `pdf_release.yml`:
     `git tag v<VERSION>; git push origin v<VERSION>`
   - Delete the temporary `release_notes.md` file:
     `Remove-Item -Path release_notes.md -Force -ErrorAction SilentlyContinue`

5. **Monitor CI Workflows (`android_release.yml`, `web_release.yml`, `pdf_release.yml`):**
   - Wait 15 seconds to allow GitHub to register the runs for `v<VERSION>`.
   - Retrieve the run IDs for all three release workflows:
     `gh run list --workflow=android_release.yml --branch v<VERSION> --limit 1 --json databaseId -q ".[0].databaseId"`
     `gh run list --workflow=web_release.yml --branch v<VERSION> --limit 1 --json databaseId -q ".[0].databaseId"`
     `gh run list --workflow=pdf_release.yml --branch v<VERSION> --limit 1 --json databaseId -q ".[0].databaseId"`
   - Watch each workflow until completion (`gh run watch <RUN_ID> --exit-status`).
   - Check the final status of all runs (`gh run view <RUN_ID>`).
   - **CRITICAL:** If any run failed, STOP immediately. Do not publish the draft release. Fetch the failed logs (`gh run view <RUN_ID> --log-failed`) and report the failure back to the orchestrator.

6. **Publish Release:**
   - Once all CI runs succeed and attach their build artifacts (Android `.aab`, Web `.zip`, and print PDF artifacts `PrayTheRosary.pdf` and `PrayTheRosary_Vervante.zip`) to the draft release, publish the release:
     `gh release edit v<VERSION> --draft=false`

7. **Handoff:** Report back to the orchestrator that the release was successfully published and provide the URL to the GitHub Release.
```
