#!/usr/bin/env python3
"""Unit tests validating GitHub Actions workflow files for common parser pitfalls."""

from __future__ import annotations

import json
import re
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent.parent
WORKFLOWS_DIR = REPO_ROOT / ".github" / "workflows"
EXPECTED_WORKFLOWS = ("ci.yml", "android_release.yml", "web_release.yml", "pdf_release.yml")


class WorkflowValidationTests(unittest.TestCase):
    def test_workflows_exist_and_have_no_utf8_bom(self) -> None:
        for name in EXPECTED_WORKFLOWS:
            wf = WORKFLOWS_DIR / name
            self.assertTrue(wf.exists(), f"Expected workflow file {name} to exist")
            raw = wf.read_bytes()
            self.assertFalse(
                raw.startswith(b"\xef\xbb\xbf"),
                f"{wf.name} must not contain a UTF-8 BOM",
            )

    def test_workflows_do_not_reference_secrets_context_in_if_conditionals(self) -> None:
        # GitHub Actions rejects workflows that reference secrets.* directly in if: expressions.
        if_secrets_pattern = re.compile(r"^\s*if\s*:.*\bsecrets\.", re.MULTILINE)
        for wf in sorted(WORKFLOWS_DIR.glob("*.yml")):
            text = wf.read_text(encoding="utf-8")
            match = if_secrets_pattern.search(text)
            self.assertIsNone(
                match,
                f"{wf.name} references `secrets.` inside an `if:` expression "
                "(bind to `env:` first and check `env.<VAR> != ''`).",
            )

    def test_ogs_stack_manifest_exists_and_is_valid(self) -> None:
        ogs_stack_file = REPO_ROOT / "ogs_stack.json"
        legacy_stack_file = REPO_ROOT / "stack.json"

        self.assertFalse(
            legacy_stack_file.exists(),
            "Legacy stack.json must not exist at repository root; use ogs_stack.json instead.",
        )
        self.assertTrue(
            ogs_stack_file.exists(),
            "ogs_stack.json must exist at repository root.",
        )

        raw = ogs_stack_file.read_bytes()
        self.assertFalse(
            raw.startswith(b"\xef\xbb\xbf"),
            "ogs_stack.json must not contain a UTF-8 BOM.",
        )

        content = json.loads(raw.decode("utf-8"))
        self.assertIsInstance(content, dict)
        self.assertIn("schema_version", content)
        self.assertIn("stack_name", content)
        self.assertIn("tools", content)

        self.assertEqual(content["schema_version"], 1)
        self.assertEqual(content["stack_name"], "Pray The Rosary")
        self.assertIsInstance(content["tools"], list)

        tool_map = {tool["id"]: tool["version"] for tool in content["tools"]}
        self.assertIn("godot", tool_map)
        self.assertEqual(tool_map["godot"], "4.7.2")
        self.assertIn("gimp", tool_map)
        self.assertEqual(tool_map["gimp"], "3.2.4")


if __name__ == "__main__":
    unittest.main()
