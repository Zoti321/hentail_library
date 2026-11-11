import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/features/series/domain/library_serialization_status_filter.dart';
import 'package:hentai_library/features/series/domain/library_series_sort_option.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';

/// Series 枚举 → 展示文案（owner extension；ARB 源仍在 `core/l10n`）。
extension SeriesL10nX on AppLocalizations {
  String librarySeriesSortFieldLabel(LibrarySeriesSortField field) {
    return switch (field) {
      LibrarySeriesSortField.name => librarySeriesSortName,
      LibrarySeriesSortField.comicCount => librarySeriesSortComicCount,
      LibrarySeriesSortField.random => librarySeriesSortRandom,
    };
  }

  String librarySerializationStatusFilterLabel(
    LibrarySerializationStatusFilter option,
  ) {
    return switch (option) {
      LibrarySerializationStatusFilter.unrestricted => filterAgeUnrestricted,
      LibrarySerializationStatusFilter.ongoing => serializationStatusOngoing,
      LibrarySerializationStatusFilter.ended => serializationStatusEnded,
      LibrarySerializationStatusFilter.hiatus => serializationStatusHiatus,
      LibrarySerializationStatusFilter.unknown => serializationStatusUnknown,
    };
  }

  String serializationStatusLabel(SerializationStatus status) {
    return switch (status) {
      SerializationStatus.unknown => serializationStatusUnknown,

      SerializationStatus.ongoing => serializationStatusOngoing,

      SerializationStatus.ended => serializationStatusEnded,

      SerializationStatus.hiatus => serializationStatusHiatus,
    };
  }
}
