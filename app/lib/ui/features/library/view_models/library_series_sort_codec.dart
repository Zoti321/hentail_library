import 'package:hentai_library/domain/library/library_series_sort_option.dart';

LibrarySeriesSortOption decodeLibrarySeriesSortOption(String? raw) {
  if (raw == null || raw.isEmpty) {
    return kLibraryDefaultSeriesSortOption;
  }
  final List<String> parts = raw.split(',');
  if (parts.length != 2) {
    return kLibraryDefaultSeriesSortOption;
  }
  final String fieldName = parts[0] == 'title' ? 'name' : parts[0];
  final LibrarySeriesSortField? field = LibrarySeriesSortField.values
      .asNameMap()[fieldName];
  if (field == null) {
    return kLibraryDefaultSeriesSortOption;
  }
  return LibrarySeriesSortOption(
    field: field,
    descending: parts[1] == 'true',
  );
}

String encodeLibrarySeriesSortOption(LibrarySeriesSortOption option) {
  return '${option.field.name},${option.descending}';
}

bool isDefaultLibrarySeriesSort(LibrarySeriesSortOption option) {
  return option.field == kLibraryDefaultSeriesSortOption.field &&
      option.descending == kLibraryDefaultSeriesSortOption.descending;
}
