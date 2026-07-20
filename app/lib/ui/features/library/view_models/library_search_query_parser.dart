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

/// Wraps [name] as a quoted exact metadata token (`"..."`), escaping `\` and `"`.
String formatLibrarySearchExactMetaQuery(String name) {
  final String escaped = name.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
  return '"$escaped"';
}

/// If [input] is exactly one fully quoted string, returns its unescaped content.
String? unwrapFullyQuotedLibrarySearchQuery(String input) {
  final String trimmed = input.trim();
  if (!trimmed.startsWith('"')) {
    return null;
  }
  final _QuotedRead? read = _readQuotedString(trimmed, 0);
  if (read == null || read.endIndex != trimmed.length) {
    return null;
  }
  return read.content;
}

/// Parses search-box text with `+` (AND), space (OR), `-` (exclude), and
/// `"..."` quoted exact tokens (`\"` / `\\` escapes).
///
/// Tokens that exactly match a known tag or author name (case-insensitive)
/// participate in a metadata expression. If there is no positive known token,
/// falls back to a whole-string title keyword query. Unmatched quotes also
/// fall back to a whole-string keyword query.
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

  final _LexResult? lexed = _lexSearchExpression(trimmed);
  if (lexed == null) {
    return LibrarySearchKeywordQuery(trimmed);
  }

  final Set<String> mustInclude = <String>{};
  final Set<String> optionalOr = <String>{};
  final Set<String> mustExclude = <String>{};

  for (final _LexToken token in lexed.tokens) {
    final String? normalized = _normalizeToken(token.value);
    if (normalized == null) {
      continue;
    }
    if (token.excluded) {
      mustExclude.add(normalized);
      continue;
    }
    if (lexed.hasSpaceBetweenPositive) {
      optionalOr.add(normalized);
    } else {
      mustInclude.add(normalized);
    }
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

final class _LexToken {
  const _LexToken({required this.value, required this.excluded});

  final String value;
  final bool excluded;
}

final class _LexResult {
  const _LexResult({
    required this.tokens,
    required this.hasSpaceBetweenPositive,
  });

  final List<_LexToken> tokens;
  final bool hasSpaceBetweenPositive;
}

final class _QuotedRead {
  const _QuotedRead({required this.content, required this.endIndex});

  final String content;
  final int endIndex;
}

/// Returns null when a quote is opened but never closed.
_LexResult? _lexSearchExpression(String input) {
  final List<_LexToken> tokens = <_LexToken>[];
  bool hasSpaceBetweenPositive = false;
  bool lastWasPositive = false;
  bool pendingSpace = false;
  int i = 0;

  while (i < input.length) {
    if (_isSearchWhitespace(input.codeUnitAt(i))) {
      pendingSpace = true;
      i++;
      continue;
    }

    if (input[i] == '+') {
      i++;
      continue;
    }

    bool excluded = false;
    if (input[i] == '-') {
      final int next = i + 1;
      if (next >= input.length) {
        i++;
        continue;
      }
      final String nextChar = input[next];
      if (nextChar == '+' || _isSearchWhitespace(input.codeUnitAt(next))) {
        i++;
        continue;
      }
      excluded = true;
      i++;
      if (i >= input.length) {
        break;
      }
    }

    if (input[i] == '+') {
      i++;
      continue;
    }

    final String value;
    if (input[i] == '"') {
      final _QuotedRead? quoted = _readQuotedString(input, i);
      if (quoted == null) {
        return null;
      }
      value = quoted.content;
      i = quoted.endIndex;
    } else {
      final int start = i;
      while (i < input.length) {
        final String ch = input[i];
        if (ch == '+' ||
            ch == '-' ||
            ch == '"' ||
            _isSearchWhitespace(input.codeUnitAt(i))) {
          break;
        }
        i++;
      }
      value = input.substring(start, i);
      if (value.isEmpty) {
        continue;
      }
    }

    if (!excluded && pendingSpace && lastWasPositive) {
      hasSpaceBetweenPositive = true;
    }
    pendingSpace = false;

    tokens.add(_LexToken(value: value, excluded: excluded));
    if (!excluded) {
      lastWasPositive = true;
    }
  }

  return _LexResult(
    tokens: tokens,
    hasSpaceBetweenPositive: hasSpaceBetweenPositive,
  );
}

_QuotedRead? _readQuotedString(String input, int start) {
  if (start >= input.length || input[start] != '"') {
    return null;
  }
  final StringBuffer buffer = StringBuffer();
  int i = start + 1;
  while (i < input.length) {
    final String ch = input[i];
    if (ch == '\\') {
      if (i + 1 >= input.length) {
        return null;
      }
      final String next = input[i + 1];
      if (next == '"' || next == '\\') {
        buffer.write(next);
        i += 2;
        continue;
      }
      buffer.write(ch);
      i++;
      continue;
    }
    if (ch == '"') {
      return _QuotedRead(content: buffer.toString(), endIndex: i + 1);
    }
    buffer.write(ch);
    i++;
  }
  return null;
}

bool _isSearchWhitespace(int codeUnit) {
  return codeUnit == 0x20 ||
      codeUnit == 0x09 ||
      codeUnit == 0x0A ||
      codeUnit == 0x0D;
}

String? _normalizeToken(String? raw) {
  final String value = (raw ?? '').trim().toLowerCase();
  if (value.isEmpty || value == '-' || value == '+') {
    return null;
  }
  return value;
}
