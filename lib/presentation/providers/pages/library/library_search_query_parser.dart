class TagSearchExpression {
  const TagSearchExpression({
    required this.mustInclude,
    required this.optionalOr,
    required this.mustExclude,
  });

  final Set<String> mustInclude;
  final Set<String> optionalOr;
  final Set<String> mustExclude;

  bool get isEmpty =>
      mustInclude.isEmpty && optionalOr.isEmpty && mustExclude.isEmpty;
}

TagSearchExpression? parsePureTagSearchExpression(String input) {
  final String trimmed = input.trim();
  if (!trimmed.startsWith('#')) {
    return null;
  }
  final String body = trimmed.substring(1).trim();
  if (body.isEmpty) {
    return null;
  }
  final Set<String> mustExclude = _extractExcludedTags(body);
  String positiveExpr = body;
  for (final String excludeTag in mustExclude) {
    positiveExpr = positiveExpr.replaceAll('-$excludeTag', ' ');
  }
  positiveExpr = positiveExpr.trim();
  final Set<String> mustInclude = <String>{};
  final Set<String> optionalOr = <String>{};
  if (positiveExpr.contains(' ')) {
    final List<String> tokens = positiveExpr
        .split(RegExp(r'\s+'))
        .expand((String token) => token.split('+'))
        .map(_normalizeTagToken)
        .whereType<String>()
        .toList();
    optionalOr.addAll(tokens);
  } else {
    final List<String> tokens = positiveExpr
        .split('+')
        .map(_normalizeTagToken)
        .whereType<String>()
        .toList();
    mustInclude.addAll(tokens);
  }
  final TagSearchExpression expression = TagSearchExpression(
    mustInclude: mustInclude,
    optionalOr: optionalOr,
    mustExclude: mustExclude,
  );
  if (expression.isEmpty) {
    return null;
  }
  return expression;
}

Set<String> _extractExcludedTags(String body) {
  final RegExp regex = RegExp(r'(^|[\s+])\-([^\s+\-]+)');
  final Set<String> excluded = <String>{};
  for (final RegExpMatch match in regex.allMatches(body)) {
    final String? value = _normalizeTagToken(match.group(2));
    if (value != null) {
      excluded.add(value);
    }
  }
  return excluded;
}

String? _normalizeTagToken(String? raw) {
  final String value = (raw ?? '').trim().toLowerCase();
  if (value.isEmpty || value == '-' || value == '+') {
    return null;
  }
  return value;
}
