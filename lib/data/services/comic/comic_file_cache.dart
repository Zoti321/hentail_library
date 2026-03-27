import 'dart:io';
import 'dart:typed_data';

import 'package:hentai_library/core/logging/log_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:talker/talker.dart';

/// 漫画文件缓存服务
///
/// 为 EPUB 等压缩格式的漫画提供封面和内容图片的缓存目录管理。
/// 封面与内容分目录存储，原样写入原始字节，不进行任何压缩或重编码。
class ComicFileCacheService {
  static const _cacheSubdir = 'comic_cache';
  static const _coversSubdir = 'covers';
  static const _contentSubdir = 'content';

  final Talker _log;
  Directory? _cacheRoot;

  ComicFileCacheService({Talker? log}) : _log = log ?? LogManager.instance;

  /// 获取缓存根目录
  Future<Directory> getCacheRoot() async {
    if (_cacheRoot != null && await _cacheRoot!.exists()) {
      return _cacheRoot!;
    }
    try {
      final appSupport = await getApplicationSupportDirectory();
      final root = Directory(p.join(appSupport.path, _cacheSubdir));
      if (!await root.exists()) {
        await root.create(recursive: true);
      }
      _cacheRoot = root;
      return root;
    } catch (e, st) {
      _log.handle(e, st, '获取漫画缓存根目录失败');
      rethrow;
    }
  }

  /// 获取封面缓存目录
  ///
  /// 路径结构: {cacheRoot}/covers/{comicId}/
  Future<String> getCoverCacheDir(String comicId) async {
    final root = await getCacheRoot();
    try {
      final dir = Directory(p.join(root.path, _coversSubdir, comicId));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir.path;
    } catch (e, st) {
      _log.handle(e, st, '获取封面缓存目录失败: comicId=$comicId');
      rethrow;
    }
  }

  /// 获取内容页缓存目录
  ///
  /// 路径结构: {cacheRoot}/content/{comicId}/
  Future<String> getContentCacheDir(String comicId) async {
    final root = await getCacheRoot();
    try {
      final dir = Directory(p.join(root.path, _contentSubdir, comicId));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir.path;
    } catch (e, st) {
      _log.handle(e, st, '获取内容缓存目录失败: comicId=$comicId');
      rethrow;
    }
  }

  /// 保存封面图片到缓存（原样写入，不压缩）
  ///
  /// [extension] 文件扩展名，如 jpg, png，默认 jpg
  Future<String> saveCover(
    String comicId,
    Uint8List bytes, {
    String extension = 'jpg',
  }) async {
    try {
      final dir = await getCoverCacheDir(comicId);
      final ext = extension.startsWith('.') ? extension : '.$extension';
      final coverPath = p.join(dir, 'cover$ext');
      await File(coverPath).writeAsBytes(bytes);
      return coverPath;
    } catch (e, st) {
      _log.handle(e, st, '保存封面缓存失败: comicId=$comicId');
      rethrow;
    }
  }

  /// 批量保存内容页图片（原样写入，不压缩）
  ///
  /// [images] 每项为 (原始字节, 扩展名)，扩展名如 jpg, png
  Future<void> saveContentImages(
    String comicId,
    List<(Uint8List bytes, String extension)> images,
  ) async {
    final dir = await getContentCacheDir(comicId);
    try {
      for (var i = 0; i < images.length; i++) {
        final index = (i + 1).toString().padLeft(5, '0');
        final ext = images[i].$2.startsWith('.')
            ? images[i].$2
            : '.${images[i].$2}';
        final filePath = p.join(dir, 'page_$index$ext');
        await File(filePath).writeAsBytes(images[i].$1);
      }
    } catch (e, st) {
      _log.handle(e, st, '保存内容缓存失败: comicId=$comicId');
      rethrow;
    }
  }

  /// 获取缓存目录占用的磁盘空间（字节）
  Future<int> getCacheDiskUsage() async {
    final root = await getCacheRoot();
    if (!await root.exists()) return 0;

    int total = 0;
    try {
      await for (final entity in root.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          total += await entity.length();
        }
      }
      return total;
    } catch (e, st) {
      _log.handle(e, st, '统计缓存占用空间失败');
      return total;
    }
  }

  /// 清理指定漫画的缓存（封面 + 内容）
  Future<void> clearComicCache(String comicId) async {
    final root = await getCacheRoot();
    try {
      final coverDir = Directory(p.join(root.path, _coversSubdir, comicId));
      final contentDir = Directory(p.join(root.path, _contentSubdir, comicId));
      if (await coverDir.exists()) await coverDir.delete(recursive: true);
      if (await contentDir.exists()) await contentDir.delete(recursive: true);
    } catch (e, st) {
      _log.handle(e, st, '清理漫画缓存失败: comicId=$comicId');
      rethrow;
    }
  }

  Future<void> clearAllCache() async {
    final root = await getCacheRoot();
    try {
      if (await root.exists()) {
        await root.delete(recursive: true);
        _log.info('已清理全部漫画缓存');
      }
      _cacheRoot = null;
    } catch (e, st) {
      _log.handle(e, st, '清理全部漫画缓存失败');
      rethrow;
    }
  }
}
