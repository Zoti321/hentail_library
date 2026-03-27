import 'dart:io';

import 'package:collection/collection.dart';
import 'package:hentai_library/core/logging/log_manager.dart';
import 'package:hentai_library/data/services/comic/resource_types.dart';
import 'package:hentai_library/domain/entity/comic/library_comic.dart';
import 'package:hentai_library/domain/extensions/library_comic_extensions.dart';
import 'package:hentai_library/domain/value_objects/library_tag_pick.dart';
import 'package:hentai_library/presentation/providers/comic/notifiers/comic_filter.dart';
import 'package:hentai_library/presentation/providers/comic/notifiers/comic_sort_option.dart';
import 'package:hentai_library/presentation/providers/comic/notifiers/search_query.dart';
import 'package:hentai_library/presentation/providers/providers_deps.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comics.g.dart';

// 书库 v2：原始列表（响应式流）
@Riverpod(keepAlive: true)
Stream<List<LibraryComic>> rawDataComics(Ref ref) {
  return ref.watch(libraryComicRepoProvider).watchAll();
}

/// 书库中出现的全部标签（用于筛选弹窗）。
@Riverpod(keepAlive: true)
AsyncValue<List<LibraryTagPick>> libraryTags(Ref ref) {
  final comicsAsync = ref.watch(rawDataComicsProvider);
  return comicsAsync.when(
    data: (comics) {
      final tags = <LibraryTagPick>[];
      final seen = <String>{};
      for (final c in comics) {
        for (final t in c.tags) {
          final key = t.name;
          if (seen.contains(key)) continue;
          seen.add(key);
          tags.add(LibraryTagPick(name: t.name));
        }
      }
      tags.sort((a, b) => a.name.compareTo(b.name));
      return AsyncValue.data(tags);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
}

@Riverpod()
AsyncValue<List<LibraryComic>> processLibraryComics(Ref ref) {
  final rawAsync = ref.watch(rawDataComicsProvider);
  final filter = ref.watch(comicFilterProvider);
  final sortOption = ref.watch(comicSortOptionProvider);
  return rawAsync.when(
    data: (raw) =>
        AsyncValue.data(raw.applyFilter(filter).sortedWith(sortOption)),
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
}

@Riverpod()
Future<List<LibraryComic>> filteredMergeComic(
  Ref ref, {
  required String comicId,
}) async {
  final query = ref.watch(searchMergeProvider);
  final comics = ref
      .watch(rawDataComicsProvider)
      .maybeWhen(data: (data) => data, orElse: () => <LibraryComic>[]);

  final filteredComics = comics.where((e) => e.comicId != comicId).toList();

  if (query.isEmpty) return filteredComics;

  var didDispose = false;
  ref.onDispose(() => didDispose = true);
  await Future.delayed(const Duration(milliseconds: 500));
  if (didDispose) throw Exception('Cancelled');

  return filteredComics
      .where((e) => e.title.toLowerCase().contains(query.toLowerCase()))
      .toList();
}

@Riverpod()
LibraryComic? comicById(Ref ref, {required String id}) {
  final comicsAsync = ref.watch(rawDataComicsProvider);
  return comicsAsync.maybeWhen(
    data: (data) => data.firstWhereOrNull((comic) => comic.comicId == id),
    orElse: () => null,
  );
}

@Riverpod()
Future<List<File>> comicImages(
  Ref ref, {
  required String comicId,
  String? chapterId,
}) async {
  final v2Comic = await ref.read(libraryComicRepoProvider).findById(comicId);
  if (v2Comic == null) return [];

  if (v2Comic.resourceType != ResourceType.dir) {
    return [];
  }

  final targetDir = v2Comic.path;

  try {
    final dir = Directory(targetDir);
    if (!await dir.exists()) {
      LogManager.instance.warning("目录不存在: $targetDir");
      return [];
    }

    final List<FileSystemEntity> entities = await dir
        .list(recursive: false)
        .toList();

    final imageFiles = entities.whereType<File>().where((file) {
      final ext = p.extension(file.path).toLowerCase();
      return ['.jpg', '.jpeg', '.png', '.webp', '.gif'].contains(ext);
    }).toList();

    imageFiles.sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
    return imageFiles;
  } catch (e, st) {
    LogManager.instance.handle(
      e,
      st,
      '加载漫画图片失败: comicId=$comicId, dir=$targetDir',
    );
    return [];
  }
}

/// 展示用封面路径：目录型取首张图；否则尝试封面缓存目录内首文件。
@Riverpod()
Future<String?> comicCoverPath(Ref ref, {required String comicId}) async {
  final images = await ref.watch(comicImagesProvider(comicId: comicId).future);
  if (images.isNotEmpty) return images.first.path;
  return null;
}
