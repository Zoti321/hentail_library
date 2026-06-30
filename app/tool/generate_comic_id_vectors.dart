import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

String normalizeForFileSystem(String rawPath) {
  final String trimmed = rawPath.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  return p.normalize(trimmed);
}

String trimTrailingSlash(String normalizedPosixPath) {
  if (normalizedPosixPath == '/' ||
      RegExp(r'^[A-Za-z]:/$').hasMatch(normalizedPosixPath)) {
    return normalizedPosixPath;
  }
  var current = normalizedPosixPath;
  while (current.endsWith('/')) {
    current = current.substring(0, current.length - 1);
  }
  return current;
}

String normalizeForKey(String rawPath) {
  final String normalizedFsPath = normalizeForFileSystem(rawPath);
  if (normalizedFsPath.isEmpty) {
    return '';
  }
  final String posixPath = p.posix.normalize(
    normalizedFsPath.replaceAll('\\', '/'),
  );
  return trimTrailingSlash(posixPath);
}

String generateComicId(String normalizedPath) {
  final List<int> bytes = utf8.encode(normalizedPath);
  return sha1.convert(bytes).toString();
}

void main() {
  final List<Map<String, String>> specs = <Map<String, String>>[
    <String, String>{
      'description': 'windows backslash',
      'raw': r'C:\漫画\test.zip',
    },
    <String, String>{
      'description': 'windows trailing slash',
      'raw': r'C:\漫画\test.zip\',
    },
    <String, String>{
      'description': 'posix',
      'raw': '/home/user/comics/foo.cbz',
    },
    <String, String>{'description': 'mixed separators', 'raw': r'C:/漫画\子目录'},
    <String, String>{
      'description': 'trim and trailing slash',
      'raw': '  /foo/bar/  ',
    },
    <String, String>{'description': 'windows drive root', 'raw': r'C:\'},
    <String, String>{'description': 'posix root', 'raw': '/'},
    <String, String>{'description': 'empty', 'raw': ''},
    <String, String>{'description': 'whitespace only', 'raw': '   '},
  ];

  final List<Map<String, String>> cases = specs.map((Map<String, String> spec) {
    final String raw = spec['raw']!;
    final String normalized = normalizeForKey(raw);
    final String comicId = normalized.isEmpty
        ? ''
        : generateComicId(normalized);
    return <String, String>{
      'description': spec['description']!,
      'raw': raw,
      'normalized': normalized,
      'expected_comic_id': comicId,
    };
  }).toList();

  final File file = File('../core/tests/fixtures/comic_id_vectors.json');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(
    const JsonEncoder.withIndent(
      '  ',
    ).convert(<String, Object>{'cases': cases}),
  );
  stdout.writeln('wrote ${file.absolute.path}');
}
