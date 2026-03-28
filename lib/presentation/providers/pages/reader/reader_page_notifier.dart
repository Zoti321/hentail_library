import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hentai_library/core/logging/log_manager.dart';
import 'package:hentai_library/data/services/comic/resource_types.dart';
import 'package:hentai_library/domain/entity/comic/library_comic.dart';
import 'package:hentai_library/domain/entity/reading_history.dart' as entity;
import 'package:hentai_library/presentation/providers/deps/deps.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'reader_page_notifier.freezed.dart';
part 'reader_page_notifier.g.dart';

@freezed
abstract class ReaderViewState with _$ReaderViewState {
  factory ReaderViewState({
    required LibraryComic comic,
    @Default(false) bool isVertical,
    @Default(false) bool showControls,
    @Default(1) int currentIndex,
    int? totalPagesOverride,
  }) = _ReaderViewState;

  ReaderViewState._();

  int get totalPages => totalPagesOverride ?? 0;
}

@riverpod
class ReaderViewNotifier extends _$ReaderViewNotifier {
  @override
  Future<ReaderViewState> build(String id) async {
    final comic = await ref.read(libraryComicRepoProvider).findById(id);
    if (comic == null) {
      throw StateError('Comic not found: $id');
    }
    final progress = await ref.watch(
      readingProgressProvider(comicId: id).future,
    );
    final images = await ref.watch(comicImagesProvider(comicId: id).future);
    final totalPages = images.length;
    final oneBased = (progress?.pageIndex ?? 1).clamp(
      1,
      totalPages > 0 ? totalPages : 1,
    );
    return ReaderViewState(
      comic: comic,
      currentIndex: oneBased,
      totalPagesOverride: totalPages > 0 ? totalPages : null,
    );
  }

  void _updateDataState(ReaderViewState Function(ReaderViewState) updater) {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(updater(current));
  }

  void toggleShowControls() {
    _updateDataState((s) => s.copyWith(showControls: !s.showControls));
  }

  void setIsVertical(bool value) {
    _updateDataState((s) => s.copyWith(isVertical: value));
  }

  void nextPage() {
    _updateDataState((s) {
      if (s.currentIndex + 1 > s.totalPages) return s;
      return s.copyWith(currentIndex: s.currentIndex + 1);
    });
  }

  void prevPage() {
    _updateDataState((s) {
      if (s.currentIndex - 1 < 1) return s;
      return s.copyWith(currentIndex: s.currentIndex - 1);
    });
  }

  void setIndex(int index) {
    _updateDataState((s) {
      if (index < 1 || index > s.totalPages) return s;
      return s.copyWith(currentIndex: index);
    });
  }

  void setTotalPagesOverride(int? value) {
    _updateDataState((s) => s.copyWith(totalPagesOverride: value));
  }

  void handleTap(TapUpDetails details, BuildContext context) {
    final current = state.asData?.value;
    if (current == null) return;
    if (current.showControls) {
      toggleShowControls();
      return;
    }
    if (current.isVertical) {
      _handleVerticalTap();
    } else {
      _handleHorizontalTap(details, context);
    }
  }

  void _handleVerticalTap() {
    toggleShowControls();
  }

  void _handleHorizontalTap(TapUpDetails details, BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final x = details.globalPosition.dx;
    final isLeftZone = x < width * 0.3;
    final isRightZone = x > width * 0.7;

    if (isLeftZone) {
      prevPage();
    } else if (isRightZone) {
      nextPage();
    } else {
      toggleShowControls();
    }
  }
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

@Riverpod()
Future<String?> comicCoverPath(Ref ref, {required String comicId}) async {
  final images = await ref.watch(comicImagesProvider(comicId: comicId).future);
  if (images.isNotEmpty) return images.first.path;
  return null;
}

@Riverpod()
Future<entity.ReadingHistory?> readingProgress(
  Ref ref, {
  required String comicId,
}) async {
  final repo = ref.watch(readingHistoryRepoProvider);
  return repo.getByComicId(comicId);
}
