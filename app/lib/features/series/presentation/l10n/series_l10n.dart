import 'package:hentai_library/features/series/domain/value_objects/serialization_status.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/features/series/domain/library_serialization_status_filter.dart';
import 'package:hentai_library/features/series/domain/library_series_sort_option.dart';

/// Series 枚举 → 展示文案（owner extension；ARB 源在 `app/l10n`，生成文案在 `design-system/l10n`）。
extension SeriesL10nX on AppLocalizations {
  String seriesVolumeCountLabel(int count) => seriesDetailVolumeCount(count);

  String? seriesVolumeProgressLabel({
    required int current,
    required int? total,
  }) {
    if (total == null || total <= 0) {
      return null;
    }

    return seriesDetailVolumeProgress(current, total);
  }

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
