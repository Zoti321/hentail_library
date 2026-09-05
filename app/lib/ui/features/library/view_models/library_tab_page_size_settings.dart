import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';

typedef LibraryTabPageSizeSettings = ({int comics, int series});

const List<int> kLibraryPageSizeOptions = <int>[20, 50, 100, 200];

const LibraryTabPageSizeSettings kDefaultLibraryTabPageSizeSettings = (
  comics: kDefaultPageSize,
  series: kDefaultPageSize,
);

int normalizeLibraryPageSize(int? raw) {
  // Legacy stored value; 500 was removed from the options list.
  if (raw == 500) {
    return 200;
  }
  if (raw == null || !kLibraryPageSizeOptions.contains(raw)) {
    return kDefaultPageSize;
  }
  return raw;
}

int pageSizeForTarget(
  LibraryTabPageSizeSettings settings,
  LibraryDisplayTarget target,
) {
  return switch (target) {
    LibraryDisplayTarget.comics => settings.comics,
    LibraryDisplayTarget.series => settings.series,
  };
}

LibraryTabPageSizeSettings copyPageSizeForTarget(
  LibraryTabPageSizeSettings settings,
  LibraryDisplayTarget target,
  int value,
) {
  return switch (target) {
    LibraryDisplayTarget.comics => (comics: value, series: settings.series),
    LibraryDisplayTarget.series => (comics: settings.comics, series: value),
  };
}
