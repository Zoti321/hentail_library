import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// 将日志文本按 ADR-0004 规则脱敏：路径替换与业务 ID 短哈希。
String redactLogText(String input, {String? homeDirectory}) {
  var result = _redactHomeDirectory(input, homeDirectory);
  result = _redactWindowsPaths(result);
  result = _redactUnixPaths(result);
  result = _redactBusinessIds(result);
  return result;
}

String? normalizeHomeDirectory(String? homeDirectory) {
  if (homeDirectory == null || homeDirectory.trim().isEmpty) {
    return null;
  }
  return p.normalize(homeDirectory.trim());
}

String _redactHomeDirectory(String input, String? homeDirectory) {
  final String? home = normalizeHomeDirectory(homeDirectory);
  if (home == null) {
    return input;
  }
  var result = input.replaceAll(home, '<HOME>');
  final String forwardHome = home.replaceAll(r'\', '/');
  if (forwardHome != home) {
    result = result.replaceAll(forwardHome, '<HOME>');
  }
  return result;
}

String _redactWindowsPaths(String input) {
  return input.replaceAllMapped(
    RegExp(r'[A-Za-z]:\\(?:[^\\/"<>|*?\s]+\\)*[^\\/"<>|*?\s]+'),
    (Match match) => _pathBasenameForRedaction(match.group(0)!),
  );
}

String _redactUnixPaths(String input) {
  return input.replaceAllMapped(RegExp(r'/(?:[^/\s"<>|*?]+/)+[^/\s"<>|*?]+'), (
    Match match,
  ) {
    final String value = match.group(0)!;
    if (value.startsWith('//')) {
      return value;
    }
    return _pathBasenameForRedaction(value);
  });
}

String _pathBasenameForRedaction(String path) {
  return p.basename(path.replaceAll(r'\', '/'));
}

String _redactBusinessIds(String input) {
  return input.replaceAllMapped(
    RegExp(r'(comic_id\s*[=:]\s*)([^\s,}\]]+)', caseSensitive: false),
    (Match match) => '${match.group(1)}${hashBusinessId(match.group(2)!)}',
  );
}

String hashBusinessId(String value) {
  final List<int> bytes = utf8.encode(value.trim());
  if (bytes.isEmpty) {
    return '00000000';
  }
  return sha256.convert(bytes).toString().substring(0, 8);
}
