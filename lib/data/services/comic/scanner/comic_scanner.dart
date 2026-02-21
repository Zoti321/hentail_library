import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:epub_image_extractor/epub_image_extractor.dart';
import 'package:path/path.dart' as p;
import 'package:hentai_library/core/logging/log_manager.dart';
import 'package:hentai_library/core/util/utils.dart';
import 'package:hentai_library/data/models/scanned_comic_model.dart';
import 'package:hentai_library/data/services/comic/comic_file_cache.dart';

// 多策略模式
// 无论来源是文件夹还是 EPUB，提取后统一处理成 .jpg 文件存入应用的缓存目录。

class ComicMetadata {
  String? title;
  List<String>? authors;
  String? description;
  int? pageCount;

  ComicMetadata({this.title, this.authors, this.description, this.pageCount});
}

class EpubFullScanResult {
  final ComicMetadata metadata;
  final Uint8List? coverBytes;
  final String? coverMediaType;
  final List<(Uint8List bytes, String mediaType)> contentImages;

  EpubFullScanResult({
    required this.metadata,
    required this.coverBytes,
    this.coverMediaType,
    required this.contentImages,
  });
}

abstract class ComicScannerStrategy {
  // 判断该路径是否符合当前策略（同步快速检查）
  bool canHandle(FileSystemEntity entity);

  // 严格验证该路径是否符合当前策略（异步详细检查）
  Future<bool> validate(FileSystemEntity entity) async {
    return canHandle(entity);
  }

  // 提取漫画元数据（标题、页面数量等）
  Future<ComicMetadata> getMetadata(FileSystemEntity entity);

  // 提取封面二进制数据
  Future<Uint8List?> getCoverBytes(FileSystemEntity entity);

  // 获取封面原始路径（仅文件夹图源有效，EPUB 等压缩格式返回 null）
  Future<String?> getCoverPath(FileSystemEntity entity) async => null;
}

class DirectoryScannerStrategy implements ComicScannerStrategy {
  static const imageExtensions = {'.jpg', '.jpeg', '.png', '.webp', '.bmp'};

  bool isImage(String path) {
    return imageExtensions.contains(p.extension(path).toLowerCase());
  }

  Future<bool> isValidDirectory(Directory dir) async {
    bool hasAtLeastOneImage = false;

    try {
      await for (final entity in dir.list(recursive: false)) {
        if (entity is Directory) return false;

        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          final fileName = p.basename(entity.path);

          // 忽略隐藏文件 (如 .DS_Store)
          if (fileName.startsWith('.')) continue;

          if (!imageExtensions.contains(ext)) return false;

          hasAtLeastOneImage = true;
        }
      }

      return hasAtLeastOneImage;
    } catch (e) {
      return false;
    }
  }

  @override
  bool canHandle(FileSystemEntity entity) {
    return entity is Directory;
  }

  @override
  Future<bool> validate(FileSystemEntity entity) async {
    if (entity is! Directory) return false;
    return await isValidDirectory(entity);
  }

  @override
  Future<ComicMetadata> getMetadata(FileSystemEntity entity) async {
    final dir = entity as Directory;
    final metadata = ComicMetadata();

    metadata.title = p.basename(dir.path);

    // 统计图片文件数量
    int pageCount = 0;
    try {
      await for (final fileEntity in dir.list(recursive: false)) {
        if (fileEntity is File) {
          final fileName = p.basename(fileEntity.path);
          // 忽略隐藏文件
          if (fileName.startsWith('.')) continue;

          if (isImage(fileEntity.path)) {
            pageCount++;
          }
        }
      }
    } catch (e) {
      // 如果统计失败，pageCount 保持为 0
    }

    metadata.pageCount = pageCount > 0 ? pageCount : null;

    return metadata;
  }

  @override
  Future<Uint8List?> getCoverBytes(FileSystemEntity entity) async {
    final dir = entity as Directory;
    final files = <File>[];

    try {
      await for (final fileEntity in dir.list(recursive: false)) {
        if (fileEntity is File) {
          final fileName = p.basename(fileEntity.path);
          // 忽略隐藏文件
          if (fileName.startsWith('.')) continue;

          if (isImage(fileEntity.path)) {
            files.add(fileEntity);
          }
        }
      }
    } catch (e) {
      return null;
    }

    // 优先选择包含 'cover' 的文件
    files.sort((a, b) {
      final aName = p.basename(a.path).toLowerCase();
      final bName = p.basename(b.path).toLowerCase();
      if (aName.contains('cover') && !bName.contains('cover')) return -1;
      if (!aName.contains('cover') && bName.contains('cover')) return 1;
      return a.path.compareTo(b.path);
    });

    if (files.isNotEmpty) {
      return await files.first.readAsBytes();
    }
    return null;
  }

  @override
  Future<String?> getCoverPath(FileSystemEntity entity) async {
    final dir = entity as Directory;
    final files = <File>[];

    try {
      await for (final fileEntity in dir.list(recursive: false)) {
        if (fileEntity is File) {
          final fileName = p.basename(fileEntity.path);
          if (fileName.startsWith('.')) continue;
          if (isImage(fileEntity.path)) files.add(fileEntity);
        }
      }
    } catch (e) {
      return null;
    }

    files.sort((a, b) {
      final aName = p.basename(a.path).toLowerCase();
      final bName = p.basename(b.path).toLowerCase();
      if (aName.contains('cover') && !bName.contains('cover')) return -1;
      if (!aName.contains('cover') && bName.contains('cover')) return 1;
      return a.path.compareTo(b.path);
    });

    return files.isNotEmpty ? files.first.path : null;
  }
}

/// ZIP/CBZ 压缩包扫描策略
class ZipArchiveStrategy implements ComicScannerStrategy {
  static const _imageExtensions = {'.jpg', '.jpeg', '.png', '.webp', '.bmp'};

  static bool _isImageEntry(String entryName) {
    final ext = p.extension(entryName).toLowerCase();
    return _imageExtensions.contains(ext);
  }

  @override
  bool canHandle(FileSystemEntity entity) {
    if (entity is! File) return false;
    final ext = p.extension(entity.path).toLowerCase();
    return ext == '.cbz' || ext == '.zip';
  }

  @override
  Future<bool> validate(FileSystemEntity entity) async {
    if (entity is! File) return false;
    try {
      final bytes = await entity.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final hasImage = archive.any((f) => f.isFile && _isImageEntry(f.name));
      return hasImage;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<ComicMetadata> getMetadata(FileSystemEntity entity) async {
    final file = entity as File;
    final metadata = ComicMetadata();
    metadata.title = p.basenameWithoutExtension(file.path);
    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final imageEntries = archive
          .where((f) => f.isFile && _isImageEntry(f.name))
          .toList();
      imageEntries.sort((a, b) => a.name.compareTo(b.name));
      metadata.pageCount = imageEntries.isNotEmpty ? imageEntries.length : null;
    } catch (_) {
      metadata.pageCount = null;
    }
    return metadata;
  }

  @override
  Future<Uint8List?> getCoverBytes(FileSystemEntity entity) async {
    final file = entity as File;
    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final imageEntries = archive
          .where((f) => f.isFile && _isImageEntry(f.name))
          .toList();
      imageEntries.sort((a, b) => a.name.compareTo(b.name));
      if (imageEntries.isEmpty) return null;
      final first = imageEntries.first;
      final content = first.content as List<int>?;
      return content != null && content.isNotEmpty
          ? Uint8List.fromList(content)
          : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> getCoverPath(FileSystemEntity entity) async => null;
}

// RAR/CBR 占位：暂不实现解析，.cbr/.rar 仍由 comic_sync_service 收集并显示为「压缩包」，但无对应策略故扫描时跳过，后续可接入实现。
// class RarArchiveStrategy implements ComicScannerStrategy { ... }

class EpubScannerStrategy implements ComicScannerStrategy {
  final EpubParser _epubParser = EpubParser();

  @override
  bool canHandle(FileSystemEntity entity) {
    return entity is File && p.extension(entity.path).toLowerCase() == '.epub';
  }

  @override
  Future<bool> validate(FileSystemEntity entity) async {
    if (entity is! File) return false;
    if (p.extension(entity.path).toLowerCase() != '.epub') return false;

    // 验证 EPUB 文件是否可以正常解析
    try {
      await _epubParser.extractMetadata(entity);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<ComicMetadata> getMetadata(FileSystemEntity entity) async {
    try {
      final metadataResult = await _epubParser.extractMetadata(entity);

      int? pageCount;

      final result = await _epubParser.extract(entity);
      pageCount = result.images.length;

      return ComicMetadata(
        title: metadataResult.title.isEmpty ? null : metadataResult.title,
        authors: metadataResult.creators.isEmpty
            ? null
            : metadataResult.creators,
        description: metadataResult.description.isEmpty
            ? null
            : metadataResult.description,
        pageCount: pageCount,
      );
    } catch (e) {
      throw Exception('解析失败: $e');
    }
  }

  @override
  Future<Uint8List?> getCoverBytes(FileSystemEntity entity) async {
    try {
      final result = await _epubParser.extract(entity);
      return _epubParser.getCoverImageData(result);
    } catch (e) {
      throw Exception('解析失败');
    }
  }

  @override
  Future<String?> getCoverPath(FileSystemEntity entity) async => null;

  /// 一次性提取 EPUB 的完整结果（元数据、封面、全部内容页），避免重复解压
  Future<EpubFullScanResult?> getFullScanResult(FileSystemEntity entity) async {
    if (entity is! File) return null;
    return Isolate.run(() => _parseEpubInBackground(entity.path));
  }
}

class ComicScannerService {
  final ComicFileCacheService _cacheService;
  final List<ComicScannerStrategy> _strategies = [
    DirectoryScannerStrategy(),
    EpubScannerStrategy(),
    ZipArchiveStrategy(),
  ];

  ComicScannerService({required ComicFileCacheService cacheService})
    : _cacheService = cacheService;

  /// 扫描路径并返回与数据库无关的 DTO（不写入数据库）
  /// 用于增量同步时收集扫描结果。失败时返回 null。
  Future<ScannedComicModel?> scanPath(String path) async {
    try {
      final entity = FileSystemEntity.isDirectorySync(path)
          ? Directory(path)
          : File(path);

      ComicScannerStrategy? strategy;
      for (final s in _strategies) {
        if (s.canHandle(entity) && await s.validate(entity)) {
          strategy = s;
          break;
        }
      }

      if (strategy == null) return null;

      if (strategy is EpubScannerStrategy) {
        return await _scanEpubToModel(entity.path);
      }
      if (strategy is ZipArchiveStrategy) {
        return await _scanZipToModel(entity.path);
      }
      return await _scanDirectoryToModel(entity.path);
    } catch (e, stackTrace) {
      LogManager.instance.handle(
        e,
        stackTrace,
        '[SCAN][ERROR] 路径扫描失败 path=$path',
      );
      return null;
    }
  }

  Future<ScannedComicModel?> _scanEpubToModel(String path) async {
    final scanResult = await Isolate.run(() => _parseEpubInBackground(path));
    if (scanResult == null ||
        scanResult.metadata.title == null ||
        scanResult.metadata.title!.isEmpty) {
      return null;
    }
    if (scanResult.coverBytes == null || scanResult.coverBytes!.isEmpty) {
      return null;
    }

    final title = scanResult.metadata.title!;
    final description = scanResult.metadata.description;
    final pageCount = scanResult.contentImages.length;

    final comicId = generateComicId(title, description: description);
    final coverExt = _mediaTypeToExt(scanResult.coverMediaType ?? 'image/jpeg');
    await _cacheService.saveCover(
      comicId,
      scanResult.coverBytes!,
      extension: coverExt,
    );
    final coverPath = await _cacheService.getCoverCacheDir(comicId);
    final coverFilePath = p.join(coverPath, 'cover.$coverExt');

    if (scanResult.contentImages.isNotEmpty) {
      final contentWithExt = scanResult.contentImages
          .map((e) => (e.$1, _mediaTypeToExt(e.$2)))
          .toList();
      await _cacheService.saveContentImages(comicId, contentWithExt);
    }
    final contentDir = await _cacheService.getContentCacheDir(comicId);
    final chapterId = generateChapterId(title, contentDir, pageCount, 1);

    final model = ScannedComicModel(
      comicId: comicId,
      title: title,
      description: description,
      coverUrl: coverFilePath,
      firstPublishedAt: null,
      lastUpdatedAt: null,
      chapterId: chapterId,
      chapterTitle: null,
      chapterCoverUrl: coverFilePath,
      pageCount: pageCount > 0 ? pageCount : null,
      imageDir: contentDir,
      sourcePath: path,
      chapterNumber: 1,
    );
    LogManager.instance.debug(
      '[SCAN][EPUB] title=$title pageCount=$pageCount cacheDir=$contentDir',
    );
    return model;
  }

  Future<ScannedComicModel?> _scanZipToModel(String path) async {
    final scanResult = await Isolate.run(() => _parseZipInBackground(path));
    if (scanResult == null ||
        scanResult.title.isEmpty ||
        scanResult.contentImages.isEmpty) {
      return null;
    }
    final title = scanResult.title;
    final pageCount = scanResult.contentImages.length;
    final comicId = generateComicId(title, description: null);
    final coverExt = scanResult.coverExt;
    if (scanResult.coverBytes != null && scanResult.coverBytes!.isNotEmpty) {
      await _cacheService.saveCover(
        comicId,
        scanResult.coverBytes!,
        extension: coverExt,
      );
    } else {
      return null;
    }
    final coverPath = await _cacheService.getCoverCacheDir(comicId);
    final coverFilePath = p.join(coverPath, 'cover.$coverExt');

    final contentWithExt = scanResult.contentImages
        .map((e) => (e.$1, e.$2.startsWith('.') ? e.$2.substring(1) : e.$2))
        .toList();
    await _cacheService.saveContentImages(comicId, contentWithExt);
    final contentDir = await _cacheService.getContentCacheDir(comicId);
    final chapterId = generateChapterId(title, contentDir, pageCount, 1);

    final model = ScannedComicModel(
      comicId: comicId,
      title: title,
      description: null,
      coverUrl: coverFilePath,
      firstPublishedAt: null,
      lastUpdatedAt: null,
      chapterId: chapterId,
      chapterTitle: null,
      chapterCoverUrl: coverFilePath,
      pageCount: pageCount > 0 ? pageCount : null,
      imageDir: contentDir,
      sourcePath: path,
      chapterNumber: 1,
    );
    LogManager.instance.debug(
      '[SCAN][ZIP] title=$title pageCount=$pageCount cacheDir=$contentDir',
    );
    return model;
  }

  Future<ScannedComicModel?> _scanDirectoryToModel(String path) async {
    final scanResult = await Isolate.run(
      () => _parseDirectoryInBackground(path),
    );
    if (scanResult == null) return null;

    final title = scanResult.title;
    final description = scanResult.description;
    final pageCount = scanResult.pageCount;
    final coverPath = scanResult.coverPath;
    final imageDir = scanResult.imageDir;

    final comicId = generateComicId(
      title,
      description: description,
      coverUrl: coverPath,
    );
    final chapterId = generateChapterId(title, imageDir, pageCount, 1);

    final now = DateTime.now();
    final model = ScannedComicModel(
      comicId: comicId,
      title: title,
      description: description,
      coverUrl: coverPath,
      firstPublishedAt: now,
      lastUpdatedAt: now,
      chapterId: chapterId,
      chapterTitle: null,
      chapterCoverUrl: coverPath,
      pageCount: pageCount > 0 ? pageCount : null,
      imageDir: imageDir,
      sourcePath: path,
      chapterNumber: 1,
    );
    LogManager.instance.debug(
      '[SCAN][DIR] title=$title pageCount=$pageCount imageDir=$imageDir',
    );
    return model;
  }
}

/// 目录扫描结果（用于 isolate 间传递）
class _DirectoryScanResult {
  final String title;
  final String? description;
  final int pageCount;
  final String coverPath;
  final String imageDir;

  _DirectoryScanResult({
    required this.title,
    this.description,
    required this.pageCount,
    required this.coverPath,
    required this.imageDir,
  });
}

/// ZIP 扫描结果（用于 isolate 间传递）
class _ZipScanResult {
  final String title;
  final Uint8List? coverBytes;
  final String coverExt;
  final List<(Uint8List bytes, String extension)> contentImages;

  _ZipScanResult({
    required this.title,
    this.coverBytes,
    required this.coverExt,
    required this.contentImages,
  });
}

/// 在后台 isolate 中解析文件夹漫画
Future<_DirectoryScanResult?> _parseDirectoryInBackground(String path) async {
  try {
    final strategy = DirectoryScannerStrategy();
    final dir = Directory(path);
    final meta = await strategy.getMetadata(dir);
    if (meta.title == null || meta.title!.isEmpty) return null;

    final coverPath = await strategy.getCoverPath(dir);
    if (coverPath == null || coverPath.isEmpty) return null;

    final coverBytes = await strategy.getCoverBytes(dir);
    if (coverBytes == null || coverBytes.isEmpty) return null;

    return _DirectoryScanResult(
      title: meta.title!,
      description: meta.description,
      pageCount: meta.pageCount ?? 0,
      coverPath: coverPath,
      imageDir: path,
    );
  } catch (_) {
    return null;
  }
}

/// 在后台 isolate 中解析 ZIP/CBZ
Future<_ZipScanResult?> _parseZipInBackground(String path) async {
  const imageExtensions = {'.jpg', '.jpeg', '.png', '.webp', '.bmp'};
  bool isImageEntry(String name) =>
      imageExtensions.contains(p.extension(name).toLowerCase());

  try {
    final file = File(path);
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final imageEntries = archive
        .where((f) => f.isFile && isImageEntry(f.name))
        .toList();
    imageEntries.sort((a, b) => a.name.compareTo(b.name));
    if (imageEntries.isEmpty) return null;

    final title = p.basenameWithoutExtension(path);
    final first = imageEntries.first;
    final firstContent = first.content as List<int>?;
    final coverBytes = firstContent != null && firstContent.isNotEmpty
        ? Uint8List.fromList(firstContent)
        : null;
    final coverExt = p.extension(first.name).toLowerCase();
    final coverExtNorm = coverExt.startsWith('.')
        ? coverExt.substring(1)
        : coverExt;

    final contentImages = <(Uint8List, String)>[];
    for (final entry in imageEntries) {
      final content = entry.content as List<int>?;
      if (content == null || content.isEmpty) continue;
      final ext = p.extension(entry.name).toLowerCase();
      final extNorm = ext.startsWith('.') ? ext.substring(1) : ext;
      contentImages.add((Uint8List.fromList(content), extNorm));
    }
    return _ZipScanResult(
      title: title,
      coverBytes: coverBytes,
      coverExt: coverExtNorm,
      contentImages: contentImages,
    );
  } catch (_) {
    return null;
  }
}

String _mediaTypeToExt(String mediaType) {
  final m = mediaType.toLowerCase();
  if (m.contains('jpeg') || m.contains('jpg')) return 'jpg';
  if (m.contains('png')) return 'png';
  if (m.contains('webp')) return 'webp';
  if (m.contains('gif')) return 'gif';
  return 'jpg';
}

/// 在后台 isolate 中解析 EPUB，避免阻塞主线程
Future<EpubFullScanResult?> _parseEpubInBackground(String path) async {
  try {
    final file = File(path);
    final parser = EpubParser();
    final result = await parser.extract(file);
    final metadata = ComicMetadata(
      title: result.metadata.title.isEmpty ? null : result.metadata.title,
      authors: result.metadata.creators.isEmpty
          ? null
          : result.metadata.creators,
      description: result.metadata.description.isEmpty
          ? null
          : result.metadata.description,
      pageCount: result.images.isEmpty ? null : result.images.length,
    );
    final coverImage = parser.getCoverImage(result);
    final coverBytes = coverImage != null
        ? parser.getImageData(result, coverImage)
        : null;
    final coverMediaType = coverImage?.mediaType;
    final contentImages = <(Uint8List, String)>[];
    for (final img in result.images) {
      final data = parser.getImageData(result, img);
      if (data != null && data.isNotEmpty) {
        contentImages.add((data, img.mediaType));
      }
    }
    return EpubFullScanResult(
      metadata: metadata,
      coverBytes: coverBytes,
      coverMediaType: coverMediaType,
      contentImages: contentImages,
    );
  } catch (_) {
    return null;
  }
}
