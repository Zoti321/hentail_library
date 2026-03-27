import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:epub_image_extractor/epub_image_extractor.dart';
import 'package:hentai_library/core/util/comic_file_types.dart';
import 'package:hentai_library/data/services/comic/scanner/directory_scan_helper.dart';
import 'package:hentai_library/data/services/comic/v2/resource_types.dart';
import 'package:path/path.dart' as p;

/// 解析器：按 ResourceType 校验并提取 ComicMeta。
class ResourceParser {
  Future<ParsedResource?> parse(ResourceCandidate candidate) async {
    return switch (candidate.type) {
      ResourceType.dir => _parseDir(candidate.path),
      ResourceType.epub => _parseEpub(candidate.path),
      ResourceType.zip => _parseZipLike(candidate.path),
      ResourceType.cbz => _parseZipLike(candidate.path),
      ResourceType.cbr => null, // 占位：不处理
      ResourceType.rar => null, // 占位：不处理
    };
  }

  Stream<ParsedResource> parseAll(Stream<ResourceCandidate> candidates) async* {
    await for (final c in candidates) {
      final parsed = await parse(c);
      if (parsed != null) yield parsed;
    }
  }

  Future<ParsedResource?> _parseDir(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) return null;

    final top = await scanTopLevelForManga(dir);
    if (!top.isManga) return null;

    final meta = (title: p.basename(path), authors: <String>[]);
    return (path: path, type: ResourceType.dir, meta: meta);
  }

  Future<ParsedResource?> _parseEpub(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;
    if (p.extension(path).toLowerCase() != '.epub') return null;

    try {
      final parser = EpubParser();
      final md = await parser.extractMetadata(file);

      final titleRaw = md.title.trim();
      final title = titleRaw.isEmpty
          ? p.basenameWithoutExtension(path)
          : titleRaw;
      final authors = md.creators.where((e) => e.trim().isNotEmpty).toList();

      final meta = (title: title, authors: authors);
      return (path: path, type: ResourceType.epub, meta: meta);
    } catch (_) {
      return null;
    }
  }

  Future<ParsedResource?> _parseZipLike(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;

    final ext = p.extension(path).toLowerCase();
    if (ext != '.zip' && ext != '.cbz') return null;

    final bytes = await file.readAsBytes();
    if (!_zipContainsAtLeastOneImage(bytes)) return null;

    final type = ext == '.cbz' ? ResourceType.cbz : ResourceType.zip;
    final meta = (title: p.basenameWithoutExtension(path), authors: <String>[]);
    return (path: path, type: type, meta: meta);
  }

  bool _zipContainsAtLeastOneImage(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      return archive.any((f) {
        if (!f.isFile) return false;
        final ext = p.extension(f.name).toLowerCase();
        return comicImageExtensions.contains(ext);
      });
    } catch (_) {
      return false;
    }
  }
}
