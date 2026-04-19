import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:hentai_library/data/services/comic/cache/archive_cover_cache.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const String _kArchiveCoverCacheSubdir = 'archive_cover_cache';

/// [ArchiveCoverCache] 的默认实现：应用缓存目录 + sidecar meta JSON。
class ArchiveCoverDiskCache implements ArchiveCoverCache {
  ArchiveCoverDiskCache();

  Directory? _resolvedRoot;

  Future<Directory> _cacheRoot() async {
    if (_resolvedRoot != null) {
      return _resolvedRoot!;
    }
    final Directory cache = await getApplicationCacheDirectory();
    final Directory dir = Directory(
      p.join(cache.path, _kArchiveCoverCacheSubdir),
    );
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _resolvedRoot = dir;
    return dir;
  }

  static String safeFileBaseForComicId(String comicId) {
    return comicId.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  @override
  Future<String?> tryReadValidPath({
    required String comicId,
    required String sourcePathNormalized,
  }) async {
    final String norm = normalizeArchiveCoverSourcePath(sourcePathNormalized);
    final String safeId = safeFileBaseForComicId(comicId);
    final Directory root = await _cacheRoot();
    final File metaFile = File(p.join(root.path, '$safeId.meta.json'));
    if (!await metaFile.exists()) {
      return null;
    }
    try {
      final String jsonStr = await metaFile.readAsString();
      final Map<String, dynamic> map =
          jsonDecode(jsonStr) as Map<String, dynamic>;
      final String? metaPath = map['sourcePath'] as String?;
      final int? metaMs = map['sourceModifiedMs'] as int?;
      final int? metaSize = map['sourceSize'] as int?;
      final String? metaExt = map['coverFileExtension'] as String?;
      if (metaPath == null || metaMs == null || metaSize == null) {
        await _deleteComicFiles(root, safeId);
        return null;
      }
      if (metaPath != norm) {
        await _deleteComicFiles(root, safeId);
        return null;
      }
      final File source = File(norm);
      if (!await source.exists()) {
        await _deleteComicFiles(root, safeId);
        return null;
      }
      final FileStat st = await source.stat();
      if (st.modified.millisecondsSinceEpoch != metaMs ||
          st.size != metaSize) {
        await _deleteComicFiles(root, safeId);
        return null;
      }
      final String dotExt =
          metaExt != null && metaExt.isNotEmpty
              ? (metaExt.startsWith('.') ? metaExt.toLowerCase() : '.${metaExt.toLowerCase()}')
              : '.bin';
      final File imageFile = File(p.join(root.path, '$safeId$dotExt'));
      if (!await imageFile.exists()) {
        await _deleteComicFiles(root, safeId);
        return null;
      }
      return imageFile.path;
    } catch (_) {
      await _deleteComicFiles(root, safeId);
      return null;
    }
  }

  @override
  Future<String?> write({
    required String comicId,
    required String sourcePathNormalized,
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final String norm = normalizeArchiveCoverSourcePath(sourcePathNormalized);
    final File source = File(norm);
    if (!await source.exists()) {
      return null;
    }
    final FileStat st = await source.stat();
    final String safeId = safeFileBaseForComicId(comicId);
    final Directory root = await _cacheRoot();
    await _deleteComicFiles(root, safeId);
    String dotExt = fileExtension.trim().toLowerCase();
    if (dotExt.isEmpty) {
      dotExt = '.bin';
    }
    if (!dotExt.startsWith('.')) {
      dotExt = '.$dotExt';
    }
    final String imageName = '$safeId$dotExt';
    final String tempName =
        '.$safeId.${DateTime.now().microsecondsSinceEpoch}.tmp';
    final File tempFile = File(p.join(root.path, tempName));
    final File imageFile = File(p.join(root.path, imageName));
    try {
      await tempFile.writeAsBytes(bytes, flush: true);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
      await tempFile.rename(imageFile.path);
    } catch (_) {
      try {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}
      return null;
    }
    final Map<String, dynamic> metaMap = <String, dynamic>{
      'sourcePath': norm,
      'sourceModifiedMs': st.modified.millisecondsSinceEpoch,
      'sourceSize': st.size,
      'coverFileExtension': dotExt,
    };
    final File metaOut = File(p.join(root.path, '$safeId.meta.json'));
    try {
      await metaOut.writeAsString(
        const JsonEncoder.withIndent('  ').convert(metaMap),
        flush: true,
      );
    } catch (_) {
      try {
        await imageFile.delete();
      } catch (_) {}
      try {
        if (await metaOut.exists()) {
          await metaOut.delete();
        }
      } catch (_) {}
      return null;
    }
    return imageFile.path;
  }

  @override
  Future<void> clearForComic(String comicId) async {
    final Directory root = await _cacheRoot();
    final String safeId = safeFileBaseForComicId(comicId);
    await _deleteComicFiles(root, safeId);
  }

  @override
  Future<void> clearAll() async {
    final Directory root = await _cacheRoot();
    if (!await root.exists()) {
      return;
    }
    await for (final FileSystemEntity e in root.list()) {
      try {
        if (e is File) {
          await e.delete();
        }
      } catch (_) {}
    }
  }

  @override
  Future<int> totalBytesInCache() async {
    final Directory root = await _cacheRoot();
    if (!await root.exists()) {
      return 0;
    }
    int total = 0;
    await for (final FileSystemEntity e in root.list()) {
      if (e is! File) {
        continue;
      }
      try {
        total += await e.length();
      } catch (_) {}
    }
    return total;
  }

  Future<void> _deleteComicFiles(Directory root, String safeId) async {
    if (!await root.exists()) {
      return;
    }
    await for (final FileSystemEntity e in root.list()) {
      if (e is! File) {
        continue;
      }
      final String b = p.basename(e.path);
      if (b == '$safeId.meta.json') {
        try {
          await e.delete();
        } catch (_) {}
        continue;
      }
      if (b.startsWith('$safeId.') && !b.endsWith('.meta.json')) {
        try {
          await e.delete();
        } catch (_) {}
      }
    }
  }
}
