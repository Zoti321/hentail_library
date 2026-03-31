import 'dart:io';

import 'package:hentai_library/data/services/comic/resource_parser.dart';
import 'package:hentai_library/data/services/comic/resource_types.dart';
import 'package:hentai_library/domain/util/enums.dart';
import 'package:path/path.dart' as p;

/// 统一扫描与解析：路径校验 → 文件/目录分流 → 目录先判定漫画文件夹否则非递归下钻。
class ComicScanParseService {
  ComicScanParseService({
    required List<ResourceParser> parsers,
    required ParseContext parseContext,
  }) : _parsers = List<ResourceParser>.unmodifiable(parsers),
       _parseContext = parseContext;

  final List<ResourceParser> _parsers;
  final ParseContext _parseContext;

  ResourceParser? get _dirParser {
    for (final parser in _parsers) {
      if (parser.type == ResourceType.dir) return parser;
    }
    return null;
  }

  late final List<ResourceParser> _fileParsers = _parsers
      .where((p) => p.type != ResourceType.dir)
      .toList(growable: false);

  /// 对每个根路径 trim；不存在则跳过；产出 [ParsedResource]（解析失败则跳过）。
  Stream<ParsedResource> scanAndParseRoots(
    Iterable<String> roots, {
    bool Function()? isCancelled,
  }) async* {
    for (final root in roots) {
      if (isCancelled?.call() == true) return;

      final path = root.trim();
      if (path.isEmpty) continue;

      final entityType = await FileSystemEntity.type(path, followLinks: false);
      if (entityType == FileSystemEntityType.notFound) continue;

      if (entityType == FileSystemEntityType.file) {
        final file = File(path);
        final parsed = await _parseFile(file);
        if (parsed != null) yield parsed;
        continue;
      }

      if (entityType == FileSystemEntityType.directory) {
        yield* _scanDirectory(Directory(path), isCancelled);
      }
    }
  }

  Future<ParsedResource?> _parseFile(File file) async {
    final name = p.basename(file.path);
    if (name.startsWith('.')) return null;

    for (final parser in _fileParsers) {
      if (parser.supports(file)) {
        return parser.parse(file, _parseContext);
      }
    }
    return null;
  }

  Stream<ParsedResource> _scanDirectory(
    Directory dir,
    bool Function()? isCancelled,
  ) async* {
    if (isCancelled?.call() == true) return;

    try {
      final dirParser = _dirParser;
      if (dirParser != null && dirParser.supports(dir)) {
        final manga = await dirParser.parse(dir, _parseContext);
        if (manga != null) {
          yield manga;
          return;
        }
      }

      await for (final entity in dir.list(
        recursive: false,
        followLinks: false,
      )) {
        if (isCancelled?.call() == true) return;

        if (entity is Directory) {
          yield* _scanDirectory(entity, isCancelled);
        } else if (entity is File) {
          final parsed = await _parseFile(entity);
          if (parsed != null) yield parsed;
        }
      }
    } catch (_) {
      return;
    }
  }
}
