import 'dart:io';

import 'package:hentai_library/core/logging/log_manager.dart';
import 'package:hentai_library/domain/entity/comic/comic.dart';
import 'package:hentai_library/domain/entity/reading_history.dart' as entity;
import 'package:hentai_library/presentation/providers/deps/deps.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'reader_page_notifier.freezed.dart';
part 'reader_page_notifier.g.dart';

enum ReaderTapZone { left, center, right }

@freezed
abstract class ReaderViewState with _$ReaderViewState {
  factory ReaderViewState({
    required Comic comic,
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

  void handleTapZone(ReaderTapZone zone) {
    final current = state.asData?.value;
    if (current == null) return;
    if (current.showControls) {
      toggleShowControls();
      return;
    }
    if (current.isVertical) {
      _handleVerticalTap();
    } else {
      _handleHorizontalTap(zone);
    }
  }

  void _handleVerticalTap() {
    toggleShowControls();
  }

  void _handleHorizontalTap(ReaderTapZone zone) {
    if (zone == ReaderTapZone.left) {
      prevPage();
    } else if (zone == ReaderTapZone.right) {
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

  final service = ref.read(comicResourceGettingServiceProvider);
  try {
    return await service.getComicContent(v2Comic.path, v2Comic.resourceType);
  } catch (e, st) {
    LogManager.instance.handle(
      e,
      st,
      '加载漫画图片失败: comicId=$comicId, path=${v2Comic.path}, type=${v2Comic.resourceType}',
    );
    return [];
  }
}

@Riverpod()
Future<String?> comicCoverPath(Ref ref, {required String comicId}) async {
  final v2Comic = await ref.read(libraryComicRepoProvider).findById(comicId);
  if (v2Comic == null) return null;

  final service = ref.read(comicResourceGettingServiceProvider);
  try {
    final file = await service.getComicCover(
      v2Comic.path,
      v2Comic.resourceType,
    );
    return file.path;
  } catch (e, st) {
    LogManager.instance.handle(
      e,
      st,
      '加载漫画封面失败: comicId=$comicId, path=${v2Comic.path}, type=${v2Comic.resourceType}',
    );
    return null;
  }
}

@Riverpod()
Future<entity.ReadingHistory?> readingProgress(
  Ref ref, {
  required String comicId,
}) async {
  final repo = ref.watch(readingHistoryRepoProvider);
  return repo.getByComicId(comicId);
}
