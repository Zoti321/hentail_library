import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_age_restriction_filter.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_media_type_filter.dart';

/// Browse 壳枚举 → 展示文案（owner extension；ARB 源在 `app/l10n`，生成文案在 `design-system/l10n`）。
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
