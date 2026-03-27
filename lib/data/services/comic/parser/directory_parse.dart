import 'dart:io';

import 'package:hentai_library/data/models/models.dart';
import 'package:hentai_library/data/services/comic/scanner/directory_scan_helper.dart';
import 'package:hentai_library/core/logging/log_manager.dart';
import 'package:talker/talker.dart';

class DirectoryParseService {
  final Talker _log;

  DirectoryParseService({Talker? log}) : _log = log ?? LogManager.instance;

  Stream<Directory> analyzeDirectory(Directory dir) async* {
    try {
      final result = await _checkDirectoryContent(dir);

      if (result.isManga) {
        _log.info('🎯 找到漫画目录: ${dir.path}');
        yield dir;
      } else {
        for (final subDir in result.subDirs) {
          yield* analyzeDirectory(subDir);
        }
      }
    } catch (e, st) {
      _log.handle(e, st, '目录扫描错误: ${dir.path}');
    }
  }

  Future<DirectoryScanResult> _checkDirectoryContent(Directory dir) async {
    try {
      final result = await scanTopLevelForManga(dir);
      return DirectoryScanResult(
        images: result.images,
        subDirs: result.subDirs,
        isManga: result.isManga,
      );
    } catch (e, st) {
      _log.warning('IO 访问 Denied/Error: ${dir.path}', e, st);
    }
    return DirectoryScanResult(
      images: <File>[],
      subDirs: <Directory>[],
      isManga: false,
    );
  }
}
