import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/catalog_selection_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_page_comics_providers.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/domain/library/sync_library_types.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 库页页头「更多」菜单条目（MD3E）：刷新、选择漫画、扫描、深度扫描；扫描进行中仅显示取消扫描。
///
/// 行为与 Baseline 溢出菜单一致；页面大小子菜单由页头自行追加。
List<M3EMenuNode> buildLibraryMd3eOverflowEntries({
  required BuildContext context,
  required WidgetRef ref,
  required bool scanning,
  required bool showSelectionEntry,
}) {
  final AppLocalizations l10n = context.l10n;
  if (scanning) {
    return <M3EMenuNode>[
      M3EMenuEntry(
        label: l10n.libraryCancelScan,
        leading: const Icon(Icons.close),
        onPressed: () => ref.read(libraryScanCommandPortProvider).cancel(),
      ),
    ];
  }
  return <M3EMenuNode>[
    M3EMenuEntry(
      label: l10n.libraryRefresh,
      leading: const Icon(Icons.refresh),
      onPressed: () => ref.read(libraryRefreshActionProvider).call(),
    ),
    if (showSelectionEntry)
      M3EMenuEntry(
        label: l10n.catalogSelectionEnter,
        leading: const Icon(Icons.checklist),
        onPressed: () => ref.read(catalogSelectionProvider.notifier).enter(),
      ),
    M3EMenuEntry(
      label: l10n.libraryScan,
      leading: const Icon(Icons.manage_search),
      onPressed: () =>
          ref.read(libraryScanCommandPortProvider).start(silent: true),
    ),
    M3EMenuEntry(
      label: l10n.libraryDeepScan,
      leading: const Icon(Icons.travel_explore),
      onPressed: () => ref
          .read(libraryScanCommandPortProvider)
          .start(mode: ScanMode.full, silent: true),
    ),
  ];
}
