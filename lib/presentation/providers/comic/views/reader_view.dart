import 'package:flutter/material.dart';
import 'package:hentai_library/domain/entity/comic/library_comic.dart';
import 'package:hentai_library/presentation/providers/comic/comics.dart';
import 'package:hentai_library/presentation/providers/reading_history/reading_history_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'reader_view.g.dart';
part 'reader_view.freezed.dart';

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

  /// 阅读页实际展示的页数；由 [comicImagesProvider] 结果决定。
  int get totalPages => totalPagesOverride ?? 0;
}

@riverpod
class ReaderViewNotifier extends _$ReaderViewNotifier {
  @override
  Future<ReaderViewState> build(String id) async {
    final comic = ref.read(comicByIdProvider(id: id));
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
