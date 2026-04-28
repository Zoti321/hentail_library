import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:epub_image_extractor/epub_image_extractor.dart';
import 'package:hentai_library/core/util/comic_file_types.dart';
import 'package:hentai_library/core/util/filename_natural_compare.dart';
import 'package:hentai_library/model/enums.dart';
import 'package:path/path.dart' as p;

/// Isolate 解码结果：封面字节与用于磁盘文件名的扩展名（带点，如 `.jpg`；未知时为 `.bin`）。
typedef ArchiveCoverDecodeResult = ({Uint8List? bytes, String fileExtension});

/// 在独立 isolate 中解码 epub/zip/cbz 封面字节，避免阻塞 UI 线程。
///
/// 目录漫画返回 bytes: null（应在主 isolate 用 [File] 路径加载）。
Future<ArchiveCoverDecodeResult> loadArchiveCoverDecodeResultOffMainUi({
  required String path,
  required ResourceType type,
}) async {
  if (type == ResourceType.dir ||
      type == ResourceType.cbr ||
      type == ResourceType.rar) {
    return (bytes: null, fileExtension: '.bin');
  }
  if (type != ResourceType.epub &&
      type != ResourceType.zip &&
      type != ResourceType.cbz) {
    return (bytes: null, fileExtension: '.bin');
  }
  final String normalized = path.trim().replaceAll('\\', '/');
  return Isolate.run(() => _decodeArchiveCoverInWorker(normalized, type));
}

/// 兼容旧调用：仅返回字节。
Future<Uint8List?> loadArchiveCoverBytesOffMainUi({
  required String path,
  required ResourceType type,
}) async {
  final ArchiveCoverDecodeResult r =
      await loadArchiveCoverDecodeResultOffMainUi(path: path, type: type);
  return r.bytes;
}

Future<ArchiveCoverDecodeResult> _decodeArchiveCoverInWorker(
  String normalizedPath,
  ResourceType type,
) async {
  switch (type) {
    case ResourceType.epub:
      return _loadEpubCoverDecodeResult(normalizedPath);
    case ResourceType.zip:
    case ResourceType.cbz:
      return _loadZipCoverDecodeResult(normalizedPath);
    default:
      return (bytes: null, fileExtension: '.bin');
  }
}

Future<ArchiveCoverDecodeResult> _loadEpubCoverDecodeResult(String path) async {
  final File file = File(path);
  if (!await file.exists()) {
    return (bytes: null, fileExtension: '.bin');
  }
  try {
    final EpubParser parser = EpubParser();
    final EpubExtractionResult result = await parser.extract(file);
    if (result.images.isEmpty) {
      return (bytes: null, fileExtension: '.bin');
    }
    ImageInfo? coverMatch;
    for (final ImageInfo info in result.images) {
      if (p.basename(info.path).toLowerCase().contains('cover')) {
        coverMatch = info;
        break;
      }
    }
    final ImageInfo chosen = coverMatch ?? result.images.first;
    final Uint8List? data = parser.getImageData(result, chosen);
    final String ext = _normalizeDotExtension(p.extension(chosen.path));
    return (bytes: data, fileExtension: ext);
  } catch (_) {
    return (bytes: null, fileExtension: '.bin');
  }
}

Future<ArchiveCoverDecodeResult> _loadZipCoverDecodeResult(String path) async {
  final File file = File(path);
  if (!await file.exists()) {
    return (bytes: null, fileExtension: '.bin');
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
      return (bytes: null, fileExtension: '.bin');
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
      return (bytes: null, fileExtension: '.bin');
    }
    final String nameNorm = chosen.name.replaceAll(r'\', '/');
    final String ext = _normalizeDotExtension(p.extension(nameNorm));
    return (bytes: Uint8List.fromList(content), fileExtension: ext);
  } catch (_) {
    return (bytes: null, fileExtension: '.bin');
  }
}

String _normalizeDotExtension(String ext) {
  final String lower = ext.toLowerCase();
  if (lower.isEmpty) {
    return '.bin';
  }
  return lower.startsWith('.') ? lower : '.$lower';
}
