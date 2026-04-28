import 'dart:io';

import 'package:hentai_library/core/logging/log_manager.dart';
import 'package:hentai_library/model/enums.dart';
import 'package:hentai_library/services/comic/scan/directory_scanner.dart';
import 'package:hentai_library/services/comic/scan/resource_parse_dispatcher.dart';
import 'package:hentai_library/services/comic/scan/resource_parser.dart';

/// 从资源中提取的元数据。
typedef ComicMeta = ({String title, List<String> authors, int? pageCount});

/// 解析阶段输出的基础单元。
typedef ParsedResource = ({String path, ResourceType type, ComicMeta meta});

/// 统一扫描与解析：路径校验 → 文件/目录分流 → 目录先判定漫画文件夹否则非递归下钻。
class ComicScanParseService {
  ComicScanParseService({
    required List<ResourceParser> parsers,
    ParseContext? parseContext,
  }) : _dispatcher = ResourceParseDispatcher(
         parsers: parsers,
         parseContext: parseContext ?? defaultComicParseContext(),
       ),
       _scanner = const DirectoryScanner();

  final DirectoryScanner _scanner;
  final ResourceParseDispatcher _dispatcher;

  /// 对每个根路径 trim；不存在则跳过；产出 [ParsedResource]（解析失败则跳过）。
  Stream<ParsedResource> scanAndParseRoots(
    Iterable<String> roots, {
    bool Function()? isCancelled,
  }) async* {
    for (final String root in roots) {
      if (_isCancelled(isCancelled)) {
        return;
      }
      final String path = root.trim();
      if (path.isEmpty) {
        continue;
      }
      final FileSystemEntityType entityType = await FileSystemEntity.type(
        path,
        followLinks: false,
      );
      if (entityType == FileSystemEntityType.notFound) {
        continue;
      }
      if (entityType == FileSystemEntityType.directory) {
        yield* _scanDirectory(Directory(path), isCancelled);
        continue;
      }
      if (entityType != FileSystemEntityType.file) {
        continue;
      }
      yield* _yieldParsedFile(File(path));
    }
  }

  Stream<ParsedResource> _scanDirectory(
    Directory dir,
    bool Function()? isCancelled,
  ) async* {
    if (_isCancelled(isCancelled)) {
      return;
    }

    try {
      final ParsedResource? manga = await _dispatcher.parseDirectory(dir);
      if (manga != null) {
        yield manga;
        return;
      }

      await for (final FileSystemEntity entity in _scanner.scanDirectory(dir)) {
        if (_isCancelled(isCancelled)) {
          return;
        }
        if (entity is Directory) {
          yield* _scanDirectory(entity, isCancelled);
          continue;
        }
        if (entity is! File) {
          continue;
        }
        yield* _yieldParsedFile(entity);
      }
    } catch (error, stackTrace) {
      LogManager.instance.handle(
        error,
        stackTrace,
        '[COMIC_SCAN_PARSE] 目录扫描失败，path=${dir.path}',
      );
      return;
    }
  }

  Stream<ParsedResource> _yieldParsedFile(File file) async* {
    final ParsedResource? parsed = await _dispatcher.parseFile(file);
    if (parsed == null) {
      return;
    }
    yield parsed;
  }

  bool _isCancelled(bool Function()? isCancelled) {
    return isCancelled?.call() == true;
  }
}
