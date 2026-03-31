import 'dart:io';

import 'package:hentai_library/core/util/comic_file_types.dart';
import 'package:hentai_library/domain/util/enums.dart';
import 'package:path/path.dart' as p;

/// 按 [ResourceType] 从磁盘路径读取封面与正文（与 [ResourceParser] 扫描策略对称，便于按类型独立扩展）。
abstract class ComicResourceContentHandler {
  ResourceType get type;

  /// 封面：目录漫画优先 basename（不含扩展名）不区分大小写为 `cover` 的图片，否则为按名排序后的第一张。
  Future<File> getCover(String validatedPath);

  /// 正文图片列表（语义依类型而定，如目录为非递归、按 basename 排序）。
  Future<List<File>> getContent(String validatedPath);
}

/// 纯图片目录。
class DirComicResourceContentHandler implements ComicResourceContentHandler {
  @override
  ResourceType get type => ResourceType.dir;

  @override
  Future<File> getCover(String validatedPath) {
    return _getDirCover(Directory(validatedPath));
  }

  @override
  Future<List<File>> getContent(String validatedPath) {
    return _listDirComicImageFiles(Directory(validatedPath));
  }

  Future<List<File>> _listDirComicImageFiles(Directory dir) async {
    if (!await dir.exists()) {
      throw ArgumentError('目录不存在: ${dir.path}');
    }

    final entities = await dir
        .list(recursive: false, followLinks: false)
        .toList();

    final imageFiles = entities.whereType<File>().where((file) {
      final ext = p.extension(file.path).toLowerCase();
      return ComicFileTypes.comicImageExtensions.contains(ext);
    }).toList();

    imageFiles.sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
    return imageFiles;
  }

  Future<File> _getDirCover(Directory dir) async {
    final files = await _listDirComicImageFiles(dir);
    if (files.isEmpty) {
      throw StateError('目录内无漫画图片: ${dir.path}');
    }

    for (final f in files) {
      if (p.basenameWithoutExtension(f.path).toLowerCase() == 'cover') {
        return f;
      }
    }
    return files.first;
  }
}

/// 占位：尚未实现对应类型的封面/正文读取时注册此实现，避免在 [ComicResourceGettingService] 内写巨型 switch。
class UnsupportedComicResourceContentHandler
    implements ComicResourceContentHandler {
  UnsupportedComicResourceContentHandler(this.type);

  @override
  final ResourceType type;

  @override
  Future<File> getCover(String validatedPath) async {
    throw UnsupportedError('getComicCover 尚未支持 ResourceType.$type');
  }

  @override
  Future<List<File>> getContent(String validatedPath) async {
    throw UnsupportedError('getComicContent 尚未支持 ResourceType.$type');
  }
}

/// 与 [defaultComicResourceParsers] 类似：集中注册各类型处理器，便于测试与替换实现。
List<ComicResourceContentHandler> defaultComicResourceContentHandlers() => [
  DirComicResourceContentHandler(),
  for (final t in ResourceType.values)
    if (t != ResourceType.dir) UnsupportedComicResourceContentHandler(t),
];
