import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:epub_image_extractor/epub_image_extractor.dart';
import 'package:hentai_library/core/util/comic_file_types.dart';
import 'package:hentai_library/core/util/filename_natural_compare.dart';
import 'package:hentai_library/domain/util/enums.dart';
import 'package:path/path.dart' as p;

/// 在独立 isolate 中解码 epub/zip/cbz 封面字节，避免阻塞 UI 线程。
///
/// 目录漫画返回 null（应在主 isolate 用 [File] 路径加载）。
Future<Uint8List?> loadArchiveCoverBytesOffMainUi({
  required String path,
  required ResourceType type,
}) async {
  if (type == ResourceType.dir ||
      type == ResourceType.cbr ||
      type == ResourceType.rar) {
    return null;
  }
  if (type != ResourceType.epub &&
      type != ResourceType.zip &&
      type != ResourceType.cbz) {
    return null;
  }
  final String normalized = path.trim().replaceAll('\\', '/');
  return Isolate.run(() => _decodeArchiveCoverInWorker(normalized, type));
}

Future<Uint8List?> _decodeArchiveCoverInWorker(
  String normalizedPath,
  ResourceType type,
) async {
  switch (type) {
    case ResourceType.epub:
      return _loadEpubCoverBytes(normalizedPath);
    case ResourceType.zip:
    case ResourceType.cbz:
      return _loadZipCoverBytes(normalizedPath);
    default:
      return null;
  }
}

Future<Uint8List?> _loadEpubCoverBytes(String path) async {
  final File file = File(path);
  if (!await file.exists()) {
    return null;
  }
  try {
    final EpubParser parser = EpubParser();
    final EpubExtractionResult result = await parser.extract(file);
    if (result.images.isEmpty) {
      return null;
    }
    for (final ImageInfo info in result.images) {
      if (p.basename(info.path).toLowerCase().contains('cover')) {
        return parser.getImageData(result, info);
      }
    }
    return parser.getImageData(result, result.images.first);
  } catch (_) {
    return null;
  }
}

Future<Uint8List?> _loadZipCoverBytes(String path) async {
  final File file = File(path);
  if (!await file.exists()) {
    return null;
  }
  try {
    final Uint8List raw = await file.readAsBytes();
    final Archive archive = ZipDecoder().decodeBytes(raw);
    final Set<String> exts = ComicFileTypes.comicImageExtensions;
    final List<ArchiveFile> imageEntries = <ArchiveFile>[];
    for (final ArchiveFile f in archive.files) {
      final String name = f.name.replaceAll(r'\', '/');
      if (!f.isFile || name.endsWith('/')) {
        continue;
      }
      final String ext = p.extension(name).toLowerCase();
      if (!exts.contains(ext)) {
        continue;
      }
      imageEntries.add(f);
    }
    if (imageEntries.isEmpty) {
      return null;
    }
    imageEntries.sort((ArchiveFile a, ArchiveFile b) {
      final String nameA = a.name.replaceAll(r'\', '/');
      final String nameB = b.name.replaceAll(r'\', '/');
      return compareFilenameNatural(p.basename(nameA), p.basename(nameB));
    });
    ArchiveFile chosen = imageEntries.first;
    for (final ArchiveFile f in imageEntries) {
      final String name = f.name.replaceAll(r'\', '/');
      if (p.basenameWithoutExtension(name).toLowerCase() == 'cover') {
        chosen = f;
        break;
      }
    }
    final Object content = chosen.content;
    if (content is! List<int>) {
      return null;
    }
    return Uint8List.fromList(content);
  } catch (_) {
    return null;
  }
}
