/// Parsed library search box input: title keyword or metadata expression.
sealed class LibrarySearchQuery {
  const LibrarySearchQuery();
}

final class LibrarySearchKeywordQuery extends LibrarySearchQuery {
  const LibrarySearchKeywordQuery(this.keyword);

  final String keyword;
}

final class LibrarySearchMetadataQuery extends LibrarySearchQuery {
  const LibrarySearchMetadataQuery({
    required this.mustInclude,
    required this.optionalOr,
    required this.mustExclude,
  });

  final Set<String> mustInclude;
  final Set<String> optionalOr;
  final Set<String> mustExclude;
}

/// Parses search-box text with `+` (AND), space (OR), `-` (exclude).
///
/// Tokens that exactly match a known tag or author name (case-insensitive)
/// participate in a metadata expression. If there is no positive known token,
/// falls back to a whole-string title keyword query.
LibrarySearchQuery parseLibrarySearchQuery(
  String input, {
  required Set<String> knownTagNames,
  required Set<String> knownAuthorNames,
}) {
  final String trimmed = input.trim();
  if (trimmed.isEmpty) {
    return const LibrarySearchKeywordQuery('');
  }

  final Set<String> known = <String>{
    ...knownTagNames.map((String n) => n.trim().toLowerCase()),
    ...knownAuthorNames.map((String n) => n.trim().toLowerCase()),
  }..removeWhere((String n) => n.isEmpty);

  final Set<String> mustExclude = _extractExcludedTokens(trimmed);
  final String positiveExpr = trimmed
      .replaceAllMapped(RegExp(r'\-([^\s+\-]+)'), (_) => ' ')
      .trim();

  final Set<String> mustInclude = <String>{};
  final Set<String> optionalOr = <String>{};
  if (positiveExpr.contains(' ')) {
    final List<String> tokens = positiveExpr
        .split(RegExp(r'\s+'))
        .expand((String token) => token.split('+'))
        .map(_normalizeToken)
        .whereType<String>()
        .toList();
    optionalOr.addAll(tokens);
  } else if (positiveExpr.isNotEmpty) {
    final List<String> tokens = positiveExpr
        .split('+')
        .map(_normalizeToken)
        .whereType<String>()
        .toList();
    mustInclude.addAll(tokens);
  }

  final Set<String> knownInclude = mustInclude.where(known.contains).toSet();
  final Set<String> knownOptional = optionalOr.where(known.contains).toSet();
  final Set<String> knownExclude = mustExclude.where(known.contains).toSet();

  if (knownInclude.isEmpty && knownOptional.isEmpty) {
    return LibrarySearchKeywordQuery(trimmed);
  }

  return LibrarySearchMetadataQuery(
    mustInclude: knownInclude,
    optionalOr: knownOptional,
    mustExclude: knownExclude,
  );
}

Set<String> _extractExcludedTokens(String body) {
  final RegExp regex = RegExp(r'\-([^\s+\-]+)');
  final Set<String> excluded = <String>{};
  for (final RegExpMatch match in regex.allMatches(body)) {
    final String? value = _normalizeToken(match.group(1));
    if (value != null) {
      excluded.add(value);
    }
  }
  return excluded;
}

String? _normalizeToken(String? raw) {
  final String value = (raw ?? '').trim().toLowerCase();
  if (value.isEmpty || value == '-' || value == '+') {
    return null;
  }
  return value;
}
