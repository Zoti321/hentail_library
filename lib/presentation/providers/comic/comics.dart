import 'dart:io';

import 'package:collection/collection.dart';
import 'package:hentai_library/core/logging/log_manager.dart';
import 'package:hentai_library/domain/entity/entities.dart' as entity;
import 'package:hentai_library/domain/extensions/extensions.dart';
import 'package:hentai_library/presentation/providers/comic/comic_providers.dart';
import 'package:hentai_library/presentation/providers/comic/notifiers/comic_filter.dart';
import 'package:hentai_library/presentation/providers/comic/notifiers/comic_sort_option.dart';
import 'package:hentai_library/presentation/providers/comic/notifiers/search_query.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comics.g.dart';

// 从数据库获取的原始数据（响应式流，comics/chapters/tags 变更时自动更新）
@Riverpod(keepAlive: true)
Stream<List<entity.Comic>> rawDataComics(Ref ref) {
  return ref.watch(comicRepoProvider).watchComicAggregate();
}

// library页面渲染的数据(经过 属性过滤 关键词过滤 排序等操作后的数据)
@Riverpod()
AsyncValue<List<entity.Comic>> processLibraryComics(Ref ref) {
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
Future<List<entity.Comic>> filteredMergeComic(
  Ref ref, {
  required String comicId,
}) async {
  final query = ref.watch(searchMergeProvider);
  final comics = ref
      .watch(rawDataComicsProvider)
      .maybeWhen(data: (data) => data, orElse: () => <entity.Comic>[]);

  // 排除掉自己
  final filteredComics = comics.where((e) => e.id != comicId).toList();

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
entity.Comic? comicById(Ref ref, {required String id}) {
  final comicsAsync = ref.watch(rawDataComicsProvider);
  return comicsAsync.maybeWhen(
    data: (data) => data.firstWhereOrNull((comic) => comic.id == id),
    orElse: () => null,
  );
}

@Riverpod()
Future<List<File>> comicImages(
  Ref ref, {
  required String comicId,
  String? chapterId,
}) async {
  final comic = ref.watch(comicByIdProvider(id: comicId));
  if (comic == null) return [];

  final targetChapter = chapterId != null
      ? comic.chapters.firstWhereOrNull((e) => e.id == chapterId)
      : comic.chapters.first;

  if (targetChapter == null) return [];
  final targetDir = targetChapter.imageDir;

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
