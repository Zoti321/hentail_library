/// Case-insensitive contains match used by Named facet MultiSelect filtering.
///
/// Trims [rawQuery]; empty / whitespace-only means match-all.
bool nameMatchesContainsFilter(String name, String rawQuery) {
  final String query = rawQuery.trim().toLowerCase();
  if (query.isEmpty) {
    return true;
  }
  return name.toLowerCase().contains(query);
}
