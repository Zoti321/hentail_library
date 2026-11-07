#!/usr/bin/env python3
"""Inventory Dart tests under app/test: gate manifest vs slow track + rubric tags (#448)."""

from __future__ import annotations

import argparse
import json
from collections import Counter
from dataclasses import dataclass
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
APP = REPO / "app"
TEST_ROOT = APP / "test"
MANIFEST = TEST_ROOT / "gate" / "manifest.txt"

Rubric = str  # architecture-guard | thin-edge | ui-contract | candidate-retire

THIN_EDGE_PREFIXES = (
    "test/frb_wire/",
    "test/shared/data/",
    "test/shared/domain/",
    "test/core/",
    "test/shared/di/",
)


def read_manifest_entries(manifest_path: Path = MANIFEST) -> list[str]:
    entries: list[str] = []
    for line in manifest_path.read_text(encoding="utf-8").splitlines():
        line = line.split("#", 1)[0].strip()
        if line:
            entries.append(line)
    return entries


def expand_manifest_to_test_paths(
    entries: list[str],
    *,
    app_root: Path = APP,
    test_root: Path = TEST_ROOT,
) -> set[str]:
    covered: set[str] = set()
    for entry in entries:
        path = app_root / entry if entry.startswith("test/") else test_root / entry
        if path.is_dir():
            for test_file in path.rglob("*_test.dart"):
                rel = test_file.relative_to(app_root).as_posix()
                covered.add(rel)
        elif path.is_file():
            covered.add(path.relative_to(app_root).as_posix())
    return covered


def collect_all_test_files(
    test_root: Path = TEST_ROOT, app_root: Path = APP
) -> list[str]:
    if not test_root.is_dir():
        return []
    return sorted(
        f.relative_to(app_root).as_posix()
        for f in test_root.rglob("*_test.dart")
    )


def classify_rubric(relative_path: str, in_manifest: bool) -> Rubric:
    p = relative_path.replace("\\", "/")

    if p.startswith("test/gate/") or p == "test/project_layout_test.dart":
        return "architecture-guard"

    if p.startswith(THIN_EDGE_PREFIXES):
        return "thin-edge"
    if p.startswith("test/features/") and (
        "/data/" in p or "/domain/" in p or "/application/" in p
    ):
        return "thin-edge"
    if p.startswith("test/support/"):
        return "thin-edge"

    if in_manifest:
        return "ui-contract"

    if p.startswith("test/shared/ui/") or p.startswith("test/features/"):
        return "candidate-retire"

    return "candidate-retire"


def bucket_slow_track(relative_path: str) -> str:
    p = relative_path.replace("\\", "/")
    parts = Path(p).parts
    if len(parts) >= 3 and parts[0] == "test" and parts[1] == "features":
        return f"features/{parts[2]}"
    if len(parts) >= 3 and parts[0] == "test" and parts[1] == "shared":
        return f"shared/{parts[2]}"
    return "/".join(parts[:3]) if len(parts) >= 3 else p


@dataclass(frozen=True)
class InventoryReport:
    total: int
    manifest_covered: int
    slow_track: int
    rubric_counts: dict[str, int]
    slow_track_buckets: dict[str, int]
    files: list[dict[str, object]]

    def to_summary_dict(self) -> dict[str, object]:
        return {
            "total": self.total,
            "manifest_covered": self.manifest_covered,
            "slow_track": self.slow_track,
            "rubric_counts": self.rubric_counts,
            "slow_track_buckets": self.slow_track_buckets,
        }


def build_inventory(
    *,
    app_root: Path = APP,
    test_root: Path = TEST_ROOT,
    manifest_path: Path = MANIFEST,
) -> InventoryReport:
    entries = read_manifest_entries(manifest_path)
    covered = expand_manifest_to_test_paths(
        entries, app_root=app_root, test_root=test_root
    )
    all_tests = collect_all_test_files(test_root, app_root=app_root)
    slow = [p for p in all_tests if p not in covered]

    rubric_counts: Counter[str] = Counter()
    file_rows: list[dict[str, object]] = []
    slow_buckets: Counter[str] = Counter()

    for path in all_tests:
        in_manifest = path in covered
        rubric = classify_rubric(path, in_manifest)
        rubric_counts[rubric] += 1
        tier = "gate-fast" if in_manifest else "slow-track"
        row = {
            "path": path,
            "tier": tier,
            "rubric": rubric,
            "in_manifest": in_manifest,
        }
        file_rows.append(row)
        if not in_manifest:
            slow_buckets[bucket_slow_track(path)] += 1

    return InventoryReport(
        total=len(all_tests),
        manifest_covered=len(covered),
        slow_track=len(slow),
        rubric_counts=dict(sorted(rubric_counts.items())),
        slow_track_buckets=dict(slow_buckets.most_common()),
        files=file_rows,
    )


def print_summary(report: InventoryReport) -> None:
    print(f"total *_test.dart: {report.total}")
    print(f"manifest-covered (expanded): {report.manifest_covered}")
    print(f"slow-track (not in manifest): {report.slow_track}")
    print("\nrubric counts:")
    for tag, count in sorted(report.rubric_counts.items()):
        print(f"  {tag}: {count}")
    print("\nslow-track buckets:")
    for bucket, count in report.slow_track_buckets.items():
        print(f"  {bucket}: {count}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--json",
        action="store_true",
        help="Full report as JSON (includes per-file rows)",
    )
    parser.add_argument(
        "--summary-json",
        action="store_true",
        help="Summary only as JSON (no per-file list)",
    )
    parser.add_argument(
        "--rubric",
        choices=(
            "architecture-guard",
            "thin-edge",
            "ui-contract",
            "candidate-retire",
        ),
        help="List paths with this rubric tag",
    )
    parser.add_argument(
        "--slow-only",
        action="store_true",
        help="With --rubric, only slow-track paths",
    )
    args = parser.parse_args()

    report = build_inventory()

    if args.rubric:
        for row in report.files:
            if row["rubric"] != args.rubric:
                continue
            if args.slow_only and row["tier"] != "slow-track":
                continue
            print(row["path"])
        return

    if args.json:
        payload = report.to_summary_dict()
        payload["files"] = report.files
        print(json.dumps(payload, indent=2, ensure_ascii=False))
        return

    if args.summary_json:
        print(json.dumps(report.to_summary_dict(), indent=2, ensure_ascii=False))
        return

    print_summary(report)


if __name__ == "__main__":
    main()
