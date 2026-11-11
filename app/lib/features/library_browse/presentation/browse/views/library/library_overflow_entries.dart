import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/domain/catalog/selection/catalog_selection_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_page_comics_providers.dart';
import 'package:hentai_library/shared/di/browse_library_scope_providers.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:hentai_library/features/library_admin/public.dart';

List<M3EMenuNode> buildLibraryOverflowEntries({
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
  final String? browseLibraryId = ref.read(browseLibraryIdProvider);
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
      onPressed: () => ref
          .read(libraryScanCommandPortProvider)
          .start(silent: true, targetLibraryId: browseLibraryId),
    ),
    M3EMenuEntry(
      label: l10n.libraryDeepScan,
      leading: const Icon(Icons.travel_explore),
      onPressed: () => ref
          .read(libraryScanCommandPortProvider)
          .start(
            mode: ScanMode.full,
            silent: true,
            targetLibraryId: browseLibraryId,
          ),
    ),
  ];
}
