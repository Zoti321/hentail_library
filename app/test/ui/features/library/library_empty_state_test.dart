import 'package:hentai_library/core/l10n/app_strings.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/features/library/views/library_page/library_empty_state.dart';
import 'package:test/test.dart';

void main() {
  group('resolveLibraryEmptyStateContent', () {
    test('comics table empty shows library empty copy', () {
      final LibraryEmptyStateContent content = resolveLibraryEmptyStateContent(
        entity: LibraryDisplayTarget.comics,
        isTableEmpty: true,
      );

      expect(content.title, AppStrings.libraryEmptyTitle);
      expect(content.hint, AppStrings.libraryEmptyHint);
      expect(content.icon, LibraryEmptyStateIcon.library);
      expect(content.showManagePathsEntry, isTrue);
    });

    test('comics filtered empty shows no-match copy', () {
      final LibraryEmptyStateContent content = resolveLibraryEmptyStateContent(
        entity: LibraryDisplayTarget.comics,
        isTableEmpty: false,
      );

      expect(content.title, AppStrings.libraryNoMatchTitle);
      expect(content.hint, AppStrings.libraryNoMatchFilterHintComics);
      expect(content.icon, LibraryEmptyStateIcon.listFilter);
      expect(content.showManagePathsEntry, isFalse);
    });

    test('series table empty shows series empty copy', () {
      final LibraryEmptyStateContent content = resolveLibraryEmptyStateContent(
        entity: LibraryDisplayTarget.series,
        isTableEmpty: true,
      );

      expect(content.title, AppStrings.librarySeriesEmptyTitle);
      expect(content.hint, AppStrings.librarySeriesEmptyHint);
      expect(content.icon, LibraryEmptyStateIcon.library);
      expect(content.showManagePathsEntry, isFalse);
    });

    test('series filtered empty shows no-match copy', () {
      final LibraryEmptyStateContent content = resolveLibraryEmptyStateContent(
        entity: LibraryDisplayTarget.series,
        isTableEmpty: false,
      );

      expect(content.title, AppStrings.libraryNoMatchTitle);
      expect(content.hint, AppStrings.libraryNoMatchFilterHintSeries);
      expect(content.icon, LibraryEmptyStateIcon.listFilter);
      expect(content.showManagePathsEntry, isFalse);
    });
  });
}
