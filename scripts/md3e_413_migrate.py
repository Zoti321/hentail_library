#!/usr/bin/env python3
"""Issue #413: move app/lib/md3e/* to shared/features/widgetbook and rewrite imports."""
from __future__ import annotations

import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app"
LIB_MD3E = APP / "lib" / "md3e"
LIB = APP / "lib"

L10N_IMPORT = "package:hentai_library/core/l10n/app_localizations.dart"
L10N_X_IMPORT = "package:hentai_library/core/l10n/app_localizations_x.dart"

# Lab-only pages (Widgetbook / md3e tests).
LAB_PAGES = {
    "pages/md3e_history_browse_page.dart",
    "pages/md3e_library_browse_page.dart",
}

# Production page → feature lib path (under app/lib/).
PAGE_DEST: dict[str, str] = {
    "pages/md3e_reader_page.dart": "features/reader/presentation/views/reader_md3e/reader_page.dart",
    "pages/md3e_settings_page.dart": "features/app_settings/presentation/views/settings_page/settings_page_body.dart",
    "pages/md3e_comic_detail_page.dart": "features/library_browse/presentation/views/comic_detail_md3e/comic_detail_page.dart",
    "pages/md3e_series_detail_page.dart": "features/library_browse/presentation/views/series_detail_md3e/series_detail_page.dart",
    "pages/md3e_comic_metadata_edit_page.dart": "features/library_browse/presentation/views/metadata_edit_md3e/comic_metadata_edit_page.dart",
    "pages/md3e_series_metadata_edit_page.dart": "features/library_browse/presentation/views/metadata_edit_md3e/series_metadata_edit_page.dart",
    "pages/md3e_library_edit_page.dart": "features/library_admin/presentation/views/library_md3e/library_edit_page.dart",
    "pages/md3e_comic_detail_entry.dart": "features/library_browse/presentation/views/comic_detail_md3e/comic_detail_page_entry.dart",
    "pages/md3e_series_detail_entry.dart": "features/library_browse/presentation/views/series_detail_md3e/series_detail_page_entry.dart",
    "pages/md3e_history_browse_entry.dart": "widgetbook/lab/pages/history_browse_entry.dart",
}

# md3e package URI → path under app/widgetbook/ (for relative import rewrite).
WIDGETBOOK_URI_TARGETS: dict[str, str] = {
    "package:hentai_library/md3e/pages/md3e_history_browse_page.dart": "lab_pages/history_browse_page.dart",
    "package:hentai_library/md3e/pages/md3e_library_browse_page.dart": "lab_pages/library_browse_page.dart",
    "package:hentai_library/md3e/pages/md3e_history_browse_entry.dart": "lab_pages/history_browse_entry.dart",
    "package:hentai_library/md3e/data/md3e_lab_library_catalog.dart": "lab_data/lab_library_catalog.dart",
    "package:hentai_library/md3e/theme/md3e_theme.dart": "lab_theme/md3e_theme.dart",
}


def strip_md3e_filename(name: str) -> str:
    if name.startswith("md3e_"):
        return name[5:]
    return name


def lib_dest_for(rel: str) -> str | None:
    """Return path under app/lib/ (posix), or None to skip/delete."""
    rel = rel.replace("\\", "/")
    if rel in ("md3e.dart",):
        return None
    if rel.startswith("l10n/"):
        return None

    base_name = Path(rel).name
    stripped = strip_md3e_filename(base_name)

    if rel.startswith("data/"):
        return f"widgetbook/lab_data/{stripped}"

    if rel in LAB_PAGES:
        return f"widgetbook/lab/pages/{stripped}"

    if rel in PAGE_DEST:
        return PAGE_DEST[rel]

    if rel.startswith("theme/"):
        if rel == "theme/md3e_theme.dart":
            return "widgetbook/lab/theme/md3e_theme.dart"
        return f"shared/ui/theme/{stripped}"

    if rel.startswith("layout/"):
        return f"shared/ui/layout/{stripped}"

    if rel.startswith("motion/"):
        return f"shared/ui/motion/{stripped}"

    if rel.startswith("interaction/"):
        if stripped == "pointer_target.dart":
            return "shared/ui/widgets/foundation/expressive_pointer_target.dart"
        return f"shared/ui/widgets/foundation/{stripped}"

    if rel.startswith("widgets/"):
        rest = rel[len("widgets/") :]
        sub = str(Path(rest).parent)
        if rel == "widgets/navigation/md3e_library_scroll_to_top_button.dart":
            return "shared/ui/widgets/navigation/expressive_library_scroll_to_top_button.dart"
        if sub == ".":
            return f"shared/ui/widgets/{stripped}"
        return f"shared/ui/widgets/{sub}/{stripped}"

    if rel.startswith("patterns/desktop/"):
        return f"shared/ui/shell/{stripped}"

    if rel.startswith("patterns/dialog/"):
        return f"shared/ui/patterns/dialog/{stripped}"

    if rel.startswith("patterns/shared/"):
        return f"shared/ui/patterns/shared/{stripped}"

    feature_prefixes = [
        ("patterns/history/", "features/home/presentation/patterns/history/"),
        ("patterns/reader/", "features/reader/presentation/patterns/reader/"),
        ("patterns/comic_detail/", "features/library_browse/presentation/patterns/comic_detail/"),
        ("patterns/series_detail/", "features/library_browse/presentation/patterns/series_detail/"),
        ("patterns/metadata_edit/", "features/library_browse/presentation/patterns/metadata_edit/"),
        ("patterns/library/", "features/library_browse/presentation/patterns/library/"),
        ("patterns/library_admin/", "features/library_admin/presentation/patterns/"),
        ("patterns/settings/", "features/app_settings/presentation/patterns/settings/"),
        ("patterns/home/", "features/home/presentation/patterns/home/"),
    ]
    for prefix, dest_prefix in feature_prefixes:
        if rel.startswith(prefix):
            sub = rel[len(prefix) :]
            parent = str(Path(sub).parent)
            if parent == ".":
                return f"{dest_prefix}{stripped}"
            return f"{dest_prefix}{parent}/{strip_md3e_filename(Path(sub).name)}"

    print(f"WARN: no destination for {rel}", file=sys.stderr)
    return None


def package_uri(lib_relative: str) -> str:
    return f"package:hentai_library/{lib_relative.replace(chr(92), '/')}"


def collect_moves() -> list[tuple[str, str]]:
    moves: list[tuple[str, str]] = []
    for path in sorted(LIB_MD3E.rglob("*.dart")):
        rel = path.relative_to(LIB_MD3E).as_posix()
        dest = lib_dest_for(rel)
        if dest is None:
            continue
        if dest.startswith("widgetbook/"):
            dest_full = APP / dest
        else:
            dest_full = LIB / dest
        moves.append((path.as_posix(), dest_full.as_posix()))
    return moves


def git_mv(src: str, dst: str) -> None:
    dst_path = Path(dst)
    dst_path.parent.mkdir(parents=True, exist_ok=True)
    if dst_path.exists():
        raise SystemExit(f"Destination exists: {dst}")
    subprocess.run(["git", "mv", src, dst], cwd=ROOT, check=True)


def build_import_map(moves: list[tuple[str, str]]) -> dict[str, str]:
    mapping: dict[str, str] = {}
    for src, dst in moves:
        old_rel = Path(src).relative_to(LIB).as_posix()
        dst_path = Path(dst)
        try:
            new_rel = dst_path.relative_to(LIB).as_posix()
        except ValueError:
            continue
        mapping[package_uri(old_rel)] = package_uri(new_rel)
    return mapping


def relative_widgetbook_import(from_file: Path, wb_target: str) -> str:
    wb_file = APP / "widgetbook" / wb_target
    rel = os.path.relpath(wb_file, from_file.parent).replace("\\", "/")
    return rel


def rewrite_file(path: Path, import_map: dict[str, str]) -> bool:
    text = path.read_text(encoding="utf-8")
    original = text

    for old_uri, wb_target in WIDGETBOOK_URI_TARGETS.items():
        needle = f"import '{old_uri}';"
        if needle in text:
            rel = relative_widgetbook_import(path, wb_target)
            text = text.replace(needle, f"import '{rel}';")

    # l10n barrel → core
    text = text.replace(
        "import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';",
        f"import '{L10N_IMPORT}';\nimport '{L10N_X_IMPORT}';",
    )
    text = text.replace(
        'import "package:hentai_library/md3e/l10n/md3e_l10n.dart";',
        f'import "{L10N_IMPORT}";\nimport "{L10N_X_IMPORT}";',
    )
    text = text.replace(
        "export 'package:hentai_library/md3e/l10n/md3e_l10n.dart';",
        f"export '{L10N_IMPORT}';\nexport '{L10N_X_IMPORT}';",
    )

    # Longest URI first to avoid partial replacements
    for old, new in sorted(import_map.items(), key=lambda kv: -len(kv[0])):
        text = text.replace(old, new)

    # Remove md3e.dart barrel imports if any
    text = re.sub(
        r"import 'package:hentai_library/md3e/md3e\.dart';\n",
        "",
        text,
    )

    if text != original:
        path.write_text(text, encoding="utf-8")
        return True
    return False


def rewrite_tree(dirs: list[Path], import_map: dict[str, str]) -> int:
    changed = 0
    for base in dirs:
        if not base.exists():
            continue
        for path in base.rglob("*.dart"):
            if rewrite_file(path, import_map):
                changed += 1
    return changed


def delete_md3e_leftovers() -> None:
    for path in sorted(LIB_MD3E.rglob("*"), reverse=True):
        if path.is_file():
            path.unlink()
        elif path.is_dir() and not any(path.iterdir()):
            path.rmdir()
    if LIB_MD3E.exists() and not any(LIB_MD3E.iterdir()):
        LIB_MD3E.rmdir()


def main() -> None:
    cmd = sys.argv[1] if len(sys.argv) > 1 else "all"
    moves = collect_moves()
    print(f"Planned moves: {len(moves)}")

    if cmd in ("plan", "all"):
        for src, dst in moves[:5]:
            print(f"  {src} -> {dst}")
        if len(moves) > 5:
            print(f"  ... and {len(moves) - 5} more")

    if cmd in ("move", "all"):
        for src, dst in moves:
            git_mv(src, dst)

    if cmd in ("rewrite", "all", "import-map"):
        import_map = build_import_map(moves)
    else:
        import_map = {}

    if cmd in ("rewrite", "all"):
        targets = [
            LIB,
            APP / "test",
            APP / "widgetbook",
        ]
        n = rewrite_tree(targets, import_map)
        print(f"Rewrote {n} files")

    if cmd in ("cleanup", "all"):
        # Remove l10n and md3e.dart if still present
        for rel in [
            "l10n/md3e_l10n.dart",
            "l10n/md3e_material_localizations.dart",
            "md3e.dart",
        ]:
            p = LIB_MD3E / rel
            if p.exists():
                p.unlink()
        delete_md3e_leftovers()

    if cmd == "import-map":
        for k, v in sorted(import_map.items()):
            print(f"{k} -> {v}")


if __name__ == "__main__":
    main()
