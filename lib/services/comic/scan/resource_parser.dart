import 'dart:io';

import 'package:archive/archive.dart';
import 'package:epub_image_extractor/epub_image_extractor.dart';
import 'package:hentai_library/core/util/comic_file_types.dart';
import 'package:hentai_library/services/comic/scan/comic_scan_parse_service.dart';
import 'package:hentai_library/model/enums.dart';
import 'package:path/path.dart' as p;

typedef ParseContext = ({Set<String> imageExts});

ParseContext defaultComicParseContext() =>
    (imageExts: Set<String>.from(ComicFileTypes.comicImageExtensions));

/// 与 [`ComicFileTypes.comicImageExtensions`] 对齐的默认解析器列表（文件匹配顺序：epub → cbz → zip）。
List<ResourceParser> defaultComicResourceParsers() => [
  DirResourceParser(),
  ComicEpubParser(),
  PureImageCbzParser(),
  PureImageZipParser(),
];

abstract class ResourceParser {
  ResourceType get type;

  bool supports(FileSystemEntity entity);

  /// 不符合业务规则返回 null
  Future<ParsedResource?> parse(FileSystemEntity entity, ParseContext context);
}

class DirResourceParser implements ResourceParser {
  @override
  ResourceType get type => ResourceType.dir;

  @override
  bool supports(FileSystemEntity entity) {
    return entity is Directory;
  }

  @override
  Future<ParsedResource?> parse(
    FileSystemEntity entity,
    ParseContext context,
  ) async {
    final Directory dir = entity as Directory;
    if (!await dir.exists()) return null;

    final List<File> files = <File>[];
    await for (final FileSystemEntity child in dir.list(
      recursive: false,
      followLinks: false,
    )) {
      if (child is Directory) {
        return null;
      }
      if (child is File) {
        files.add(child);
      }
    }
    if (files.isEmpty) return null;

    final bool allImages = files.every((File file) {
      final String ext = p.extension(file.path).toLowerCase();
      return context.imageExts.contains(ext);
    });
    if (!allImages) return null;

    final String title = p.basename(dir.path);
    return (
      type: type,
      path: dir.path,
      meta: (title: title, authors: <String>[], pageCount: files.length),
    );
  }
}

class PureImageZipParser implements ResourceParser {
  @override
  ResourceType get type => ResourceType.zip;

  @override
  bool supports(FileSystemEntity entity) {
    return entity is File && p.extension(entity.path).toLowerCase() == '.zip';
  }

  @override
  Future<ParsedResource?> parse(FileSystemEntity entity, ParseContext context) {
    return parsePureImageZipArchive(entity as File, type, context);
  }
}

class PureImageCbzParser implements ResourceParser {
  @override
  ResourceType get type => ResourceType.cbz;

  @override
  bool supports(FileSystemEntity entity) {
    return entity is File && p.extension(entity.path).toLowerCase() == '.cbz';
  }

  @override
  Future<ParsedResource?> parse(FileSystemEntity entity, ParseContext context) {
    return parsePureImageZipArchive(entity as File, type, context);
  }
}

class ComicEpubParser implements ResourceParser {
  @override
  ResourceType get type => ResourceType.epub;

  @override
  bool supports(FileSystemEntity entity) {
    return entity is File && p.extension(entity.path).toLowerCase() == '.epub';
  }

  @override
  Future<ParsedResource?> parse(
    FileSystemEntity entity,
    ParseContext context,
  ) async {
    final file = entity as File;

    try {
      final parser = EpubParser();
      final md = await parser.extractMetadata(file);
      final pageCount = (await parser.extract(file)).images.length;

      final titleRaw = md.title.trim();
      final title = titleRaw.isEmpty
          ? p.basenameWithoutExtension(file.path)
          : titleRaw;
      final authors = md.creators.where((e) => e.trim().isNotEmpty).toList();

      final meta = (title: title, authors: authors, pageCount: pageCount);
      return (path: file.path, type: ResourceType.epub, meta: meta);
    } catch (_) {
      return null;
    }
  }
}

Future<ParsedResource?> parsePureImageZipArchive(
  File file,
  ResourceType resourceType,
  ParseContext context,
) async {
  final bytes = await file.readAsBytes();
  Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } catch (_) {
    return null;
  }

  var hasImage = false;
  for (final f in archive.files) {
    final name = f.name.replaceAll(r'\', '/');
    if (!f.isFile || name.endsWith('/')) continue;

    final ext = p.extension(name).toLowerCase();
    if (context.imageExts.contains(ext)) {
      hasImage = true;
      break;
    }
  }

  if (!hasImage) return null;

  return (
    path: file.path,
    type: resourceType,
    meta: (
      title: p.basenameWithoutExtension(file.path),
      authors: <String>[],
      pageCount: null,
    ),
  );
}
