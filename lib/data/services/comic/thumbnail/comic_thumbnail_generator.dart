import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:hentai_library/core/constants/comic_thumbnail_constants.dart';
import 'package:hentai_library/core/util/comic_file_types.dart';
import 'package:hentai_library/core/util/filename_natural_compare.dart';
import 'package:hentai_library/core/util/path_normalizer.dart';
import 'package:hentai_library/data/services/comic/read_resource_get/isolate/archive_cover_loader.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

typedef ComicSourceStat = ({int modifiedMs, int size});

/// 读取漫画源文件 stat，用于缩略图失效检测。
Future<ComicSourceStat?> readComicSourceStat({
  required String path,
  required ResourceType type,
}) async {
  if (type == ResourceType.dir) {
    final Directory directory = Directory(path);
    if (!await directory.exists()) {
      return null;
    }
    final FileStat stat = await directory.stat();
    return (modifiedMs: stat.modified.millisecondsSinceEpoch, size: stat.size);
  }
  final File file = File(path);
  if (!await file.exists()) {
    return null;
  }
  final FileStat stat = await file.stat();
  return (modifiedMs: stat.modified.millisecondsSinceEpoch, size: stat.size);
}

/// 是否支持生成封面缩略图。
bool canGenerateComicThumbnail(ResourceType type) {
  return type == ResourceType.dir ||
      type == ResourceType.zip ||
      type == ResourceType.cbz ||
      type == ResourceType.epub;
}

/// 在 isolate 中加载封面源字节并编码为 JPEG 缩略图。
Future<Uint8List?> generateComicThumbnailJpegOffMainUi({
  required String path,
  required ResourceType type,
}) async {
  if (!canGenerateComicThumbnail(type)) {
    return null;
  }
  final String normalized = const PathNormalizer().normalizeForKey(path);
  return Isolate.run(() => _generateThumbnailInWorker(normalized, type));
}

Future<Uint8List?> _generateThumbnailInWorker(
  String normalizedPath,
  ResourceType type,
) async {
  final Uint8List? sourceBytes = await _loadCoverSourceBytes(
    normalizedPath,
    type,
  );
  if (sourceBytes == null || sourceBytes.isEmpty) {
    return null;
  }
  return _encodeThumbnailJpeg(sourceBytes);
}

Future<Uint8List?> _loadCoverSourceBytes(String path, ResourceType type) async {
  if (type == ResourceType.epub ||
      type == ResourceType.zip ||
      type == ResourceType.cbz) {
    final ArchiveCoverDecodeResult decoded = await decodeArchiveCoverInWorker(
      path: path,
      type: type,
    );
    return decoded.bytes;
  }
  if (type == ResourceType.dir) {
    return _loadDirCoverBytes(path);
  }
  return null;
}

Future<Uint8List?> _loadDirCoverBytes(String dirPath) async {
  final Directory directory = Directory(dirPath);
  if (!await directory.exists()) {
    return null;
  }
  final List<FileSystemEntity> entities = await directory.list().toList();
  final List<File> imageFiles = <File>[];
  for (final FileSystemEntity entity in entities) {
    if (entity is! File) {
      continue;
    }
    final String ext = p.extension(entity.path).toLowerCase();
    if (!ComicFileTypes.comicImageExtensions.contains(ext)) {
      continue;
    }
    imageFiles.add(entity);
  }
  if (imageFiles.isEmpty) {
    return null;
  }
  imageFiles.sort(
    (File a, File b) =>
        compareFilenameNatural(p.basename(a.path), p.basename(b.path)),
  );
  File chosen = imageFiles.first;
  for (final File file in imageFiles) {
    if (p.basenameWithoutExtension(file.path).toLowerCase() == 'cover') {
      chosen = file;
      break;
    }
  }
  return chosen.readAsBytes();
}

Uint8List? _encodeThumbnailJpeg(Uint8List sourceBytes) {
  final img.Image? decoded = img.decodeImage(sourceBytes);
  if (decoded == null) {
    return null;
  }
  img.Image flattened = decoded.hasAlpha
      ? _flattenAlphaOnWhite(decoded)
      : decoded;
  if (flattened.numChannels < 3) {
    flattened = flattened.convert(numChannels: flattened.hasAlpha ? 4 : 3);
  }
  final img.Image resized = _resizeToMaxLongEdge(
    flattened,
    ComicThumbnailConstants.maxLongEdge,
  );
  return Uint8List.fromList(
    img.encodeJpg(resized, quality: ComicThumbnailConstants.jpegQuality),
  );
}

img.Image _flattenAlphaOnWhite(img.Image source) {
  final img.Image canvas = img.Image(
    width: source.width,
    height: source.height,
  );
  img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
  img.compositeImage(canvas, source);
  return canvas;
}

img.Image _resizeToMaxLongEdge(img.Image image, int maxLongEdge) {
  final int width = image.width;
  final int height = image.height;
  final int longEdge = width > height ? width : height;
  if (longEdge <= maxLongEdge) {
    return image;
  }
  if (width >= height) {
    return img.copyResize(image, width: maxLongEdge);
  }
  return img.copyResize(image, height: maxLongEdge);
}
