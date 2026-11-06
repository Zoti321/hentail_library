#!/usr/bin/env python3
"""Strip md3e_ / Md3e naming from production Dart paths and identifiers.

Convention (ADR-0031 Cutover naming):
- Production FooMd3ePage -> FooPage (foo_md3e_page.dart -> foo_page.dart)
- Presentational Md3eFooPage -> FooLayout (sibling foo_page.dart -> foo_layout.dart)
- Screen UI data aggregates -> FooViewObject (e.g. Md3eComicDetailEntry)
- Other symbols: strip Md3e unless collision

Rename order: rewrite contents -> rename files in place -> rename directories.
Widgetbook paths keep md3e_; package imports/symbols are rewritten.
"""

from __future__ import annotations

import argparse
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app"

PRESENTATIONAL_PAGE_STEMS = {
    "comic_detail_page",
    "comic_metadata_edit_page",
    "series_detail_page",
    "series_metadata_edit_page",
    "author_detail_page",
    "reader_page",
}

SYMBOL_OVERRIDES: dict[str, str] = {
    "Md3eComicDetailPage": "ComicDetailLayout",
    "Md3eSeriesDetailPage": "SeriesDetailLayout",
    "Md3eAuthorDetailPage": "AuthorDetailLayout",
    "Md3eReaderPage": "ReaderLayout",
    "Md3eHomePage": "HomeLayout",
    "Md3eComicMetadataEditPage": "ComicMetadataEditLayout",
    "Md3eSeriesMetadataEditPage": "SeriesMetadataEditLayout",
    "ComicMetadataEditMd3eView": "ComicMetadataEditFormLayout",
    "SeriesMetadataEditMd3eView": "SeriesMetadataEditFormLayout",
    "Md3eComicDetailEntry": "ComicDetailViewObject",
    "Md3eSeriesDetailEntry": "SeriesDetailViewObject",
    "HomeMd3ePage": "HomePage",
    "ComicDetailMd3ePage": "ComicDetailPage",
    "SeriesDetailMd3ePage": "SeriesDetailPage",
    "AuthorDetailMd3ePage": "AuthorDetailPage",
    "ReaderMd3ePage": "ReaderPage",
    "LibraryMd3ePage": "LibraryPage",
    "TrashMd3ePage": "TrashPage",
    "SettingsMd3ePage": "SettingsPage",
    "MetadataMd3ePage": "MetadataPage",
    "Md3eLibraryScrollToTopButton": "ExpressiveLibraryScrollToTopButton",
    "_Md3eLibraryScrollToTopButtonState": "_ExpressiveLibraryScrollToTopButtonState",
    "Md3eNamedFacetMultiSelectField": "FacetMultiSelectField",
    "Md3eReaderTapZone": "ReaderViewportTapZone",
    "md3eResolveReaderTapZone": "resolveReaderViewportTapZone",
    # Flutter / motor / existing API collisions
    "Md3eFilledButton": "ExpressiveFilledButton",
    "Md3eNavigationRail": "ExpressiveNavigationRail",
    "Md3eNavigationRailDestination": "ExpressiveNavigationRailDestination",
    "Md3eNavigationRailMetrics": "ExpressiveNavigationRailMetrics",
    "Md3eMotion": "LabMotion",
    "showMd3eComicMetadataEdit": "showComicMetadataEditLayout",
    "showMd3eSeriesMetadataEdit": "showSeriesMetadataEditLayout",
    "kMd3eLibraryPageSizeOptions": "kLibraryPageSizeOptions",
    "_Md3eClearReadingHistoryConfirmDialog": "_ClearReadingHistoryConfirmPanel",
    "_Md3eMetadataImportConfirmDialog": "_MetadataImportConfirmPanel",
    "_Md3eMetadataImportResultDialog": "_MetadataImportResultPanel",
    "_LibraryMd3eForm": "_LibraryFormFields",
    "_ReaderMd3eContent": "_ReaderPageContent",
    "kMd3eLabSeedColor": "kLabSeedColor",
}


def git_mv(src: Path, dst: Path) -> None:
    if src.resolve() == dst.resolve():
        return
    if not src.exists():
        raise SystemExit(f"missing source: {src}")
    if dst.exists():
        raise SystemExit(f"target exists: {src} -> {dst}")
    dst.parent.mkdir(parents=True, exist_ok=True)
    subprocess.check_call(["git", "mv", str(src), str(dst)], cwd=ROOT)


def strip_md3e_path_component(name: str) -> str:
    n = name
    n = re.sub(r"^md3e_", "", n, flags=re.I)
    n = re.sub(
        r"_md3e(?=_page|_view|_layout|_entry|_cover|_form|_actions|_sections|_sheet|"
        r"_dialog|_presenter|_metrics|_header|_body|_links|_overflow|_filter|"
        r"_sort|_grouping|_selection|_purge|_confirm|_lab|_copy|_row|_section|"
        r"_menu|_toggle|_layout|_field|_chip|_adapters|_hosts|_navigation)",
        "",
        n,
        flags=re.I,
    )
    n = re.sub(r"_md3e_", "_", n, flags=re.I)
    n = re.sub(r"_md3e$", "", n, flags=re.I)
    return re.sub(r"__+", "_", n)


def fix_dart_filename(stem: str, parent_parts: list[str]) -> str:
    in_md3e_dir = any("md3e" in p.lower() for p in parent_parts)
    if stem.startswith("md3e_") and stem.endswith("_page"):
        stem2 = strip_md3e_path_component(stem)
        return stem2[: -len("_page")] + "_layout" if stem2.endswith("_page") else stem2
    if in_md3e_dir and stem in PRESENTATIONAL_PAGE_STEMS and "_md3e" not in stem:
        return stem[: -len("_page")] + "_layout"
    return strip_md3e_path_component(stem)


def fix_import_uri(uri: str) -> str:
    parts = uri.split("/")
    out: list[str] = []
    for part in parts:
        if part.endswith(".dart"):
            out.append(fix_dart_filename(part[:-5], out) + ".dart")
        else:
            out.append(
                strip_md3e_path_component(part) if "md3e" in part.lower() else part
            )
    return "/".join(out)


def rewrite_import_paths(text: str) -> str:
    def repl(m: re.Match[str]) -> str:
        kw, q1, uri, q2 = m.group(1), m.group(2), m.group(3), m.group(4)
        if q1 != q2 or "md3e" not in uri.lower():
            return m.group(0)
        return f"{kw} {q1}{fix_import_uri(uri)}{q2}"

    return re.sub(r"""\b(import|export)\s+(['"])([^'"]+)(['"])""", repl, text)


def collect_defined_symbols(dart_files: list[Path]) -> set[str]:
    symbols: set[str] = set()
    decl = re.compile(
        r"^\s*(?:abstract\s+|final\s+|base\s+|sealed\s+|interface\s+)?"
        r"(?:class|typedef|enum|mixin|extension)\s+([A-Za-z_][A-Za-z0-9_]*)",
        re.M,
    )
    const = re.compile(
        r"^\s*(?:static\s+)?const\s+(?:[A-Za-z0-9_<>,\s?]+\s+)?"
        r"(k[A-Za-z0-9_]*)\s*=",
        re.M,
    )
    for p in dart_files:
        text = p.read_text(encoding="utf-8")
        symbols.update(decl.findall(text))
        symbols.update(const.findall(text))
    return symbols


def default_symbol_target(name: str, defined: set[str]) -> str | None:
    if "md3e" not in name.lower() and "Md3e" not in name:
        return None
    if name in SYMBOL_OVERRIDES:
        return SYMBOL_OVERRIDES[name]
    if name.startswith("Md3e"):
        cand = name[len("Md3e") :]
    elif name.startswith("md3e") and len(name) > 4 and name[4].isupper():
        # camelCase md3eFooBar only — never snake_case md3e_foo (import URIs).
        rest = name[len("md3e") :]
        cand = rest[:1].lower() + rest[1:] if rest else name
    elif "Md3e" in name:
        cand = name.replace("Md3e", "")
    else:
        # snake_case _md3e_ / Foo_md3e_bar identifiers
        cand = re.sub(r"_?md3e_?", "_", name, flags=re.I)
        cand = re.sub(r"_+", "_", cand).strip("_")
        if name.startswith("_") and not cand.startswith("_"):
            cand = "_" + cand
    if not cand or cand[0].isdigit():
        return None
    if cand not in defined or cand == name:
        return cand
    if cand.endswith("Page"):
        alt = cand[: -len("Page")] + "Layout"
        if alt not in defined:
            return alt
    if cand.endswith("Entry"):
        alt = cand[: -len("Entry")] + "ViewObject"
        if alt not in defined:
            return alt
    alt = "App" + cand
    if alt not in defined:
        return alt
    return name


def build_symbol_map(dart_files: list[Path]) -> dict[str, str]:
    defined = collect_defined_symbols(dart_files)
    mapping = dict(SYMBOL_OVERRIDES)
    # Dart identifiers only: Md3eFoo, md3eFoo (camel), FooMd3eBar — not md3e_snake.
    ident = re.compile(
        r"\b(?:Md3e[A-Za-z0-9_]*|md3e[A-Z][A-Za-z0-9_]*|[A-Za-z_][A-Za-z0-9_]*Md3e[A-Za-z0-9_]*)\b"
    )
    found: set[str] = set()
    for p in dart_files:
        found.update(ident.findall(p.read_text(encoding="utf-8")))
    for name in sorted(found, key=len, reverse=True):
        if name in mapping:
            continue
        target = default_symbol_target(name, defined | set(mapping.values()))
        if target and target != name:
            mapping[name] = target
            defined.add(target)
    return mapping


def rewrite_text(text: str, mapping: dict[str, str]) -> str:
    if not mapping:
        return text
    items = sorted(mapping.items(), key=lambda kv: len(kv[0]), reverse=True)
    pattern = re.compile(r"\b(" + "|".join(re.escape(k) for k, _ in items) + r")\b")
    return pattern.sub(lambda m: mapping[m.group(1)], text)


def map_filename_in_place(src: Path) -> Path:
    """Rename only the file basename; keep current parent directory."""
    parent_parts = list(src.parent.relative_to(ROOT).parts)
    new_name = fix_dart_filename(src.stem, parent_parts) + src.suffix
    return src.with_name(new_name)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    apply = args.apply

    lib_test = list((APP / "lib").rglob("*.dart")) + list(
        (APP / "test").rglob("*.dart")
    )
    widgetbook = list((APP / "widgetbook").rglob("*.dart"))
    mapping = build_symbol_map(lib_test)
    print(f"symbol renames: {len(mapping)}")

    changed = 0
    for p in lib_test:
        old = p.read_text(encoding="utf-8")
        new = rewrite_import_paths(rewrite_text(old, mapping))
        if new != old:
            changed += 1
            if apply:
                p.write_text(new, encoding="utf-8")
    # Widgetbook keeps md3e_ path basenames; rewrite symbols only.
    for p in widgetbook:
        old = p.read_text(encoding="utf-8")
        new = rewrite_text(old, mapping)
        if new != old:
            changed += 1
            if apply:
                p.write_text(new, encoding="utf-8")
    print(f"content files changed: {changed}")

    candidates = list((APP / "lib").rglob("*")) + list((APP / "test").rglob("*"))
    all_files = sorted(
        {
            p
            for p in candidates
            if p.is_file()
            and (
                "md3e" in p.name.lower()
                or (
                    p.suffix == ".dart"
                    and p.stem in PRESENTATIONAL_PAGE_STEMS
                    and any("md3e" in part.lower() for part in p.parts)
                )
            )
        },
        key=lambda p: len(p.parts),
        reverse=True,
    )

    presentational: list[tuple[Path, Path]] = []
    others: list[tuple[Path, Path]] = []
    for src in all_files:
        if not src.is_file():
            continue
        dst = map_filename_in_place(src)
        if src == dst:
            # still may need move after dir rename only — skip for now
            if "md3e" not in src.name.lower():
                continue
            continue
        if src.stem in PRESENTATIONAL_PAGE_STEMS or (
            src.stem.startswith("md3e_") and src.stem.endswith("_page")
        ):
            presentational.append((src, dst))
        else:
            others.append((src, dst))

    dirs = sorted(
        [
            p
            for p in list((APP / "lib").rglob("*")) + list((APP / "test").rglob("*"))
            if p.is_dir() and "md3e" in p.name.lower()
        ],
        key=lambda x: len(x.parts),
        reverse=True,
    )

    print(
        f"in-place file renames: {len(presentational) + len(others)} "
        f"(presentational {len(presentational)}); dir renames: {len(dirs)}"
    )
    if apply:
        for src, dst in presentational + others:
            if src.exists():
                git_mv(src, dst)
        for d in dirs:
            new_name = strip_md3e_path_component(d.name)
            if new_name == d.name or not d.exists():
                continue
            git_mv(d, d.with_name(new_name))

    for a, b in list(mapping.items())[:12]:
        print(f"  {a} -> {b}")


if __name__ == "__main__":
    main()
