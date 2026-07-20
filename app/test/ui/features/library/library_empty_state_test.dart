import 'package:hentai_library/core/l10n/app_localizations_zh.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/features/library/views/library_page/library_empty_state.dart';
import 'package:test/test.dart';

void main() {
  final AppLocalizationsZh l10n = AppLocalizationsZh();

  group('resolveLibraryEmptyStateContent', () {
    test('comics table empty shows library empty copy', () {
      final LibraryEmptyStateContent content = resolveLibraryEmptyStateContent(
        l10n: l10n,
        entity: LibraryDisplayTarget.comics,
        isTableEmpty: true,
      );

      expect(content.title, l10n.libraryEmptyTitle);
      expect(content.hint, l10n.libraryEmptyHint);
      expect(content.icon, LibraryEmptyStateIcon.library);
      expect(content.showManagePathsEntry, isTrue);
    });

    test('comics filtered empty shows no-match copy', () {
      final LibraryEmptyStateContent content = resolveLibraryEmptyStateContent(
        l10n: l10n,
        entity: LibraryDisplayTarget.comics,
        isTableEmpty: false,
      );

      expect(content.title, l10n.libraryNoMatchTitle);
      expect(content.hint, l10n.libraryNoMatchFilterHintComics);
      expect(content.icon, LibraryEmptyStateIcon.listFilter);
      expect(content.showManagePathsEntry, isFalse);
    });

    test('series table empty shows series empty copy', () {
      final LibraryEmptyStateContent content = resolveLibraryEmptyStateContent(
        l10n: l10n,
        entity: LibraryDisplayTarget.series,
        isTableEmpty: true,
      );

      expect(content.title, l10n.librarySeriesEmptyTitle);
      expect(content.hint, l10n.librarySeriesEmptyHint);
      expect(content.icon, LibraryEmptyStateIcon.library);
      expect(content.showManagePathsEntry, isFalse);
    });

    test('series filtered empty shows no-match copy', () {
      final LibraryEmptyStateContent content = resolveLibraryEmptyStateContent(
        l10n: l10n,
        entity: LibraryDisplayTarget.series,
        isTableEmpty: false,
      );

      expect(content.title, l10n.libraryNoMatchTitle);
      expect(content.hint, l10n.libraryNoMatchFilterHintSeries);
      expect(content.icon, LibraryEmptyStateIcon.listFilter);
      expect(content.showManagePathsEntry, isFalse);
    });
  });
}
