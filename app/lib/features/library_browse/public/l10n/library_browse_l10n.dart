import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_age_restriction_filter.dart';
import 'package:hentai_library/shared/domain/library/library_media_type_filter.dart';

/// Browse 壳枚举 → 展示文案（owner extension；ARB 源仍在 `core/l10n`）。
extension LibraryBrowseL10nX on AppLocalizations {
  String libraryAgeRestrictionFilterLabel(LibraryAgeRestrictionFilter filter) {
    return switch (filter) {
      LibraryAgeRestrictionFilter.unrestricted => filterAgeUnrestricted,
      LibraryAgeRestrictionFilter.allAges => filterAgeAllAges,
      LibraryAgeRestrictionFilter.r18Only => filterAgeR18Only,
    };
  }

  String libraryMediaTypeFilterLabel(LibraryMediaTypeFilterOption option) {
    return switch (option) {
      LibraryMediaTypeFilterOption.pdf => filterMediaTypePdf,

      LibraryMediaTypeFilterOption.epub => filterMediaTypeEpub,

      LibraryMediaTypeFilterOption.archive => filterMediaTypeArchive,
    };
  }
}
