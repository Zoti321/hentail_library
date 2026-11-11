import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/features/comic/domain/value_objects/library_comic_sort_option.dart';
import 'package:hentai_library/shared/domain/models/value_objects/comic_language.dart';

/// Comic 枚举 → 展示文案（owner extension；ARB 源仍在 `core/l10n`）。
extension ComicL10nX on AppLocalizations {
  String libraryComicSortFieldLabel(LibraryComicSortField field) {
    return switch (field) {
      LibraryComicSortField.title => libraryComicSortTitle,
      LibraryComicSortField.createdAt => libraryComicSortCreatedAt,
      LibraryComicSortField.lastUpdatedAt => libraryComicSortLastUpdatedAt,
      LibraryComicSortField.publishedAt => libraryComicSortPublishedAt,
      LibraryComicSortField.readAt => libraryComicSortReadAt,
      LibraryComicSortField.fileSize => libraryComicSortFileSize,
      LibraryComicSortField.pageCount => libraryComicSortPageCount,
    };
  }

  String comicLanguageLabel(String canonical) => comicLanguageDisplayLabel(
    canonical,
    closedLabels: <String, String>{
      ComicLanguageNames.chinese: comicLanguageChinese,
      ComicLanguageNames.japanese: comicLanguageJapanese,
      ComicLanguageNames.english: comicLanguageEnglish,
      ComicLanguageNames.korean: comicLanguageKorean,
      ComicLanguageNames.spanish: comicLanguageSpanish,
      ComicLanguageNames.other: comicLanguageOther,
    },
  );
}
