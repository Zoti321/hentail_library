import 'package:hentai_library/core/l10n/app_strings.dart';
import 'package:hentai_library/domain/models/enums.dart';

enum LibraryEmptyStateIcon { library, listFilter }

typedef LibraryEmptyStateContent = ({
  String title,
  String hint,
  LibraryEmptyStateIcon icon,
  bool showManagePathsEntry,
});

LibraryEmptyStateContent resolveLibraryEmptyStateContent({
  required LibraryDisplayTarget entity,
  required bool isTableEmpty,
}) {
  if (isTableEmpty) {
    return switch (entity) {
      LibraryDisplayTarget.comics => (
        title: AppStrings.libraryEmptyTitle,
        hint: AppStrings.libraryEmptyHint,
        icon: LibraryEmptyStateIcon.library,
        showManagePathsEntry: true,
      ),
      LibraryDisplayTarget.series => (
        title: AppStrings.librarySeriesEmptyTitle,
        hint: AppStrings.librarySeriesEmptyHint,
        icon: LibraryEmptyStateIcon.library,
        showManagePathsEntry: false,
      ),
    };
  }

  return (
    title: AppStrings.libraryNoMatchTitle,
    hint: switch (entity) {
      LibraryDisplayTarget.comics => AppStrings.libraryNoMatchFilterHintComics,
      LibraryDisplayTarget.series => AppStrings.libraryNoMatchFilterHintSeries,
    },
    icon: LibraryEmptyStateIcon.listFilter,
    showManagePathsEntry: false,
  );
}
