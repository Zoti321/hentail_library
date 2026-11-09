#!/usr/bin/env python3
"""Unit tests for audit_dart_tests (#448)."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from audit_dart_tests import (
    build_inventory,
    classify_rubric,
    expand_manifest_to_test_paths,
    read_manifest_entries,
)


class AuditDartTestsTest(unittest.TestCase):
    def test_read_manifest_entries_strips_comments(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            manifest = Path(tmp) / "manifest.txt"
            manifest.write_text(
                "# comment\n"
                "test/foo_test.dart\n"
                "\n"
                "test/bar # inline\n",
                encoding="utf-8",
            )
            self.assertEqual(
                read_manifest_entries(manifest),
                ["test/foo_test.dart", "test/bar"],
            )

    def test_expand_manifest_directory_and_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            app = Path(tmp)
            test_root = app / "test"
            (test_root / "gate").mkdir(parents=True)
            (test_root / "features" / "home").mkdir(parents=True)
            (test_root / "widget_test.dart").write_text("//", encoding="utf-8")
            (test_root / "features" / "home" / "a_test.dart").write_text(
                "//", encoding="utf-8"
            )
            (test_root / "features" / "home" / "b_test.dart").write_text(
                "//", encoding="utf-8"
            )
            manifest = test_root / "gate" / "manifest.txt"
            manifest.write_text(
                "test/widget_test.dart\ntest/features/home\n", encoding="utf-8"
            )
            covered = expand_manifest_to_test_paths(
                read_manifest_entries(manifest),
                app_root=app,
                test_root=test_root,
            )
            self.assertEqual(
                covered,
                {
                    "test/widget_test.dart",
                    "test/features/home/a_test.dart",
                    "test/features/home/b_test.dart",
                },
            )

    def test_classify_rubric_precedence(self) -> None:
        self.assertEqual(
            classify_rubric("test/gate/import_boundary_test.dart", True),
            "architecture-guard",
        )
        self.assertEqual(
            classify_rubric("test/shared/data/frb/foo_mapper_test.dart", True),
            "thin-edge",
        )
        self.assertEqual(
            classify_rubric("test/features/reader/domain/spread_test.dart", False),
            "thin-edge",
        )
        self.assertEqual(
            classify_rubric("test/shared/ui/widgets/foo_test.dart", True),
            "ui-contract",
        )
        self.assertEqual(
            classify_rubric("test/shared/ui/widgets/foo_test.dart", False),
            "candidate-retire",
        )

    def test_build_inventory_matches_repo_baseline_order_of_magnitude(self) -> None:
        report = build_inventory()
        self.assertGreater(report.total, 200)
        self.assertGreater(report.manifest_covered, 100)
        self.assertGreater(report.slow_track, 50)
        self.assertEqual(
            report.total, report.manifest_covered + report.slow_track
        )
        self.assertIn("architecture-guard", report.rubric_counts)
        self.assertIn("candidate-retire", report.rubric_counts)


if __name__ == "__main__":
    unittest.main()
