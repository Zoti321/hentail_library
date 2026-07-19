import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/domain/models/enums.dart';

enum LibraryEmptyStateIcon { library, listFilter }

typedef LibraryEmptyStateContent = ({
  String title,
  String hint,
  LibraryEmptyStateIcon icon,
  bool showManagePathsEntry,
});

LibraryEmptyStateContent resolveLibraryEmptyStateContent({
  required AppLocalizations l10n,
  required LibraryDisplayTarget entity,
  required bool isTableEmpty,
}) {
  if (isTableEmpty) {
    return switch (entity) {
      LibraryDisplayTarget.comics => (
        title: l10n.libraryEmptyTitle,
        hint: l10n.libraryEmptyHint,
        icon: LibraryEmptyStateIcon.library,
        showManagePathsEntry: true,
      ),
      LibraryDisplayTarget.series => (
        title: l10n.librarySeriesEmptyTitle,
        hint: l10n.librarySeriesEmptyHint,
        icon: LibraryEmptyStateIcon.library,
        showManagePathsEntry: false,
      ),
    };
  }

  return (
    title: l10n.libraryNoMatchTitle,
    hint: switch (entity) {
      LibraryDisplayTarget.comics => l10n.libraryNoMatchFilterHintComics,
      LibraryDisplayTarget.series => l10n.libraryNoMatchFilterHintSeries,
    },
    icon: LibraryEmptyStateIcon.listFilter,
    showManagePathsEntry: false,
  );
}
