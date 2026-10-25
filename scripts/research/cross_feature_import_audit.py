#!/usr/bin/env python3
"""Audit app/lib imports against target feature-module boundaries (#223)."""

from __future__ import annotations

import json
import re
from collections import defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
LIB = REPO / "app" / "lib"

IMPORT_RE = re.compile(
    r"^import\s+'package:hentai_library/([^']+)';", re.MULTILINE
)

MODULES = frozenset(
    {
        "bootstrap",
        "home",
        "library_admin",
        "library_browse",
        "read_session",
        "comic_trash",
        "named_metadata",
        "app_settings",
        "metadata_backup",
        "shared",
        "md3e",
        "frb_generated",
    }
)


def classify(relative: str) -> str:
    p = relative.replace("\\", "/")
    if p.startswith("src/rust/"):
        return "frb_generated"
    if p.startswith("features/"):
        parts = p.split("/")
        if len(parts) >= 2:
            return parts[1]
    if p.startswith("shared/"):
        return "shared"
    if p.startswith("md3e/"):
        return "md3e"
    if p == "main.dart":
        return "bootstrap"
    return "shared"


def resolve_file(import_path: str) -> Path | None:
    candidates = [
        LIB / import_path,
        LIB / f"{import_path}.dart",
    ]
    for c in candidates:
        if c.is_file():
            return c
    return None


def resolve_module(import_path: str) -> str | None:
    if import_path.startswith("src/rust/"):
        return "frb_generated"
    f = resolve_file(import_path)
    if f is None:
        return None
    return classify(str(f.relative_to(LIB)).replace("\\", "/"))


def is_ui_layer(path: str) -> bool:
    return (
        (path.startswith("features/") and "/presentation/" in path)
        or path.startswith("shared/ui/")
        or path.startswith("md3e/")
    )


def main() -> None:
    files = [
        f
        for f in LIB.rglob("*.dart")
        if not f.name.endswith(".g.dart") and not f.name.endswith(".freezed.dart")
    ]

    domain_to_data: list[str] = []
    shared_domain_to_features: list[str] = []
    non_data_to_frb: list[str] = []
    browse_to_reading: list[str] = []
    edge_counts: dict[tuple[str, str], int] = defaultdict(int)
    edge_examples: dict[tuple[str, str], list[str]] = defaultdict(list)
    ui_cross: dict[tuple[str, str], list[str]] = defaultdict(list)

    for f in sorted(files):
        rel = str(f.relative_to(LIB)).replace("\\", "/")
        mod = classify(rel)
        text = f.read_text(encoding="utf-8", errors="replace")
        for m in IMPORT_RE.finditer(text):
            imp = m.group(1)
            target = resolve_module(imp)
            if target is None:
                continue

            if rel.startswith("shared/domain/") and imp.startswith("shared/data/"):
                domain_to_data.append(f"{rel} -> {imp}")
            if rel.startswith("shared/domain/") and imp.startswith("features/"):
                shared_domain_to_features.append(f"{rel} -> {imp}")
            if (
                "/domain/" in rel
                and rel.startswith("features/")
                and mod in MODULES
                and mod not in ("shared", "bootstrap", "frb_generated")
                and imp.startswith(f"features/{mod}/data/")
            ):
                domain_to_data.append(f"{rel} -> {imp}")

            if target == "frb_generated" and not rel.startswith("shared/data/"):
                non_data_to_frb.append(rel)

            if mod == "library_browse" and imp.startswith("features/read_session/"):
                browse_to_reading.append(f"{rel} -> {imp}")

            if mod != target and mod in MODULES and target in MODULES:
                if mod != "shared" and target != "shared":
                    edge_counts[(mod, target)] += 1
                    ex = f"{rel} -> {imp}"
                    if len(edge_examples[(mod, target)]) < 5:
                        edge_examples[(mod, target)].append(ex)

            if is_ui_layer(imp) and is_ui_layer(rel):
                src_m, dst_m = mod, target
                if (
                    src_m != dst_m
                    and src_m not in ("shared", "bootstrap")
                    and dst_m not in ("shared", "bootstrap")
                    and src_m in MODULES
                    and dst_m in MODULES
                ):
                    ui_cross[(src_m, dst_m)].append(f"{rel} -> {imp}")

    out = {
        "domain_to_data": sorted(set(domain_to_data)),
        "shared_domain_to_features": sorted(set(shared_domain_to_features)),
        "non_data_to_frb": sorted(set(non_data_to_frb)),
        "library_browse_to_reading_domain": sorted(set(browse_to_reading)),
        "module_edge_counts": {
            f"{a}->{b}": c for (a, b), c in sorted(edge_counts.items())
        },
        "module_edge_examples": {
            f"{a}->{b}": v for (a, b), v in sorted(edge_examples.items())
        },
        "ui_feature_cross_examples": {
            f"{a}->{b}": sorted(set(v))[:15]
            for (a, b), v in sorted(ui_cross.items())
            if v
        },
    }
    print(json.dumps(out, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
