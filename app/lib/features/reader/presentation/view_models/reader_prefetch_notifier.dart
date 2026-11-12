import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hentai_library/features/reader/domain/reader_page_payload.dart';
import 'package:hentai_library/features/reader/domain/page_prefetch_window.dart';
import 'package:hentai_library/features/reader/presentation/view_models/read_session_page_data.dart';
import 'package:hentai_library/features/reader/presentation/image/reader_image_cache.dart';
import 'package:hentai_library/features/reader/presentation/providers/session_providers.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_page_aspect_ratios.dart';
import 'package:hentai_library/features/reader/presentation/view_models/read_session_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reader_prefetch_notifier.g.dart';

@Riverpod(keepAlive: true, name: 'readerPrefetchNotifierProvider')
class ReaderPrefetchNotifier extends _$ReaderPrefetchNotifier {
  final Map<String, Set<int>> _lastWarmWindows = <String, Set<int>>{};

  /// 会话内被 UI/预热触达过的页（1-based）；含 PageView 预建邻页。
  final Map<String, Set<int>> _touchedPages = <String, Set<int>>{};

  @override
  Map<String, int> build() => <String, int>{};

  int bumpGeneration(String comicId) {
    final int next = (state[comicId] ?? 0) + 1;
    state = <String, int>{...state, comicId: next};
    return next;
  }

  /// PageView / 视口触达某页时登记，供窗口外失效覆盖「从未进过 warm window」的 keepAlive。
  void notePageTouched({required String comicId, required int pageOneBased}) {
    if (pageOneBased < 1) {
      return;
    }
    _touchedPages.putIfAbsent(comicId, () => <int>{}).add(pageOneBased);
  }

  void clearComic(String comicId) {
    // Invalidate Flutter-side prefetch generation before disk clear.
    bumpGeneration(comicId);
    _lastWarmWindows.remove(comicId);
    _touchedPages.remove(comicId);
    if (state.containsKey(comicId)) {
      state = Map<String, int>.from(state)..remove(comicId);
    }
    clearReaderImageCache();
    ref.read(readerPageAspectRatiosProvider.notifier).clearComic(comicId);
    // Fire-and-forget: async FRB must not block exit navigation (P2-4).
    unawaited(
      ref.read(openReadSessionServiceProvider).clearPageCache(comicId: comicId),
    );
    ref.invalidate(comicReaderPageProvider);
  }

  /// Returns whether the warm window changed (callers should skip neighbor
  /// precache when false — same window, already warmed).
  Future<bool> warmWindow({
    required String comicId,
    required int centerPageOneBased,
    required int totalPages,
    Iterable<int> extraPageIndexesOneBased = const <int>[],
    List<ReaderPageImageData> imageList = const <ReaderPageImageData>[],
  }) async {
    if (totalPages <= 0) {
      return false;
    }
    final Set<int> targets = computePrefetchWindow(
      centerPageOneBased: centerPageOneBased,
      totalPages: totalPages,
      neighborCount: kReaderPrefetchNeighborCount,
      extraPageIndexesOneBased: extraPageIndexesOneBased,
    );
    final Set<int> touched = _touchedPages.putIfAbsent(comicId, () => <int>{});
    touched.addAll(targets);
    final Set<int>? previous = _lastWarmWindows[comicId];
    if (!shouldBumpPrefetchGeneration(
      previousWindow: previous,
      nextWindow: targets,
    )) {
      return false;
    }
    // Drop keepAlive FilePaths + path→bytes for pages Rust will evict
    //（含 PageView 触达、却从未进入 previousWindow 的页）。
    for (final int pageOneBased in pagesToInvalidateOutsidePrefetchWindow(
      previousWindow: previous,
      nextWindow: targets,
      touchedPages: touched,
    )) {
      _forgetPathBytesForPage(
        comicId: comicId,
        pageOneBased: pageOneBased,
        imageList: imageList,
      );
      ref.invalidate(
        comicReaderPageProvider(comicId: comicId, pageIndex: pageOneBased - 1),
      );
    }
    _lastWarmWindows[comicId] = Set<int>.of(targets);
    final int generation = bumpGeneration(comicId);
    // Kick the landing/center page before neighbor prefetch contends on the archive.
    final int centerZeroBased = centerPageOneBased.clamp(1, totalPages) - 1;
    unawaited(() async {
      try {
        await ref.read(
          comicReaderPageProvider(
            comicId: comicId,
            pageIndex: centerZeroBased,
          ).future,
        );
      } on Object {
        // 预热失败由页面自身错误态处理。
      }
    }());
    await ref
        .read(openReadSessionServiceProvider)
        .prefetchPages(
          comicId: comicId,
          archivePageIndexes: targets
              .map((int pageOneBased) => pageOneBased - 1)
              .toList(growable: false),
          generation: generation,
        );
    // Prefetch 末尾会 evict；邻页可能在 await 期间被 PageView load 后又被删盘。
    // 再扫一遍窗口外触达页的 keepAlive，避免卡在失效 FilePath。
    final Set<int> staleAfterEvict = (_touchedPages[comicId] ?? const <int>{})
        .difference(targets);
    for (final int pageOneBased in staleAfterEvict) {
      _forgetPathBytesForPage(
        comicId: comicId,
        pageOneBased: pageOneBased,
        imageList: imageList,
      );
      ref.invalidate(
        comicReaderPageProvider(comicId: comicId, pageIndex: pageOneBased - 1),
      );
    }
    return true;
  }

  void _forgetPathBytesForPage({
    required String comicId,
    required int pageOneBased,
    required List<ReaderPageImageData> imageList,
  }) {
    if (pageOneBased >= 1 && pageOneBased <= imageList.length) {
      final ReaderPageImageData imageData = imageList[pageOneBased - 1];
      if (imageData is ReaderDirPageImageData) {
        removeReaderPathBytes(imageData.file.path);
      }
    }
    final AsyncValue<ReaderPagePayload> pageAsync = ref.read(
      comicReaderPageProvider(comicId: comicId, pageIndex: pageOneBased - 1),
    );
    final ReaderPagePayload? page = pageAsync.asData?.value;
    if (page is ReaderPageFilePath) {
      removeReaderPathBytes(page.path);
    }
  }

  Future<void> precacheWindow({
    required BuildContext context,
    required String comicId,
    required Set<int> pageIndexesOneBased,
    required List<ReaderPageImageData> imageList,
    int? cacheWidth,
    int? skipPageOneBased,
  }) async {
    if (pageIndexesOneBased.isEmpty || imageList.isEmpty) {
      return;
    }
    final int generation = state[comicId] ?? 0;
    ensureReaderImageCacheConfigured();
    for (final int pageOneBased in pageIndexesOneBased) {
      if (skipPageOneBased != null && pageOneBased == skipPageOneBased) {
        // Center is already on-tree; avoid double decode via precache.
        continue;
      }
      if (!_isPrecacheStillValid(
            comicId: comicId,
            generation: generation,
            pageOneBased: pageOneBased,
          ) ||
          !context.mounted) {
        return;
      }
      if (pageOneBased < 1 || pageOneBased > imageList.length) {
        continue;
      }
      final ReaderPageImageData imageData = imageList[pageOneBased - 1];
      await _precachePage(
        context: context,
        comicId: comicId,
        generation: generation,
        imageData: imageData,
        cacheWidth: cacheWidth,
      );
    }
  }

  bool _isPrecacheStillValid({
    required String comicId,
    required int generation,
    required int pageOneBased,
  }) {
    if ((state[comicId] ?? 0) != generation) {
      return false;
    }
    final Set<int>? window = _lastWarmWindows[comicId];
    return window != null && window.contains(pageOneBased);
  }

  Future<void> _precachePage({
    required BuildContext context,
    required String comicId,
    required int generation,
    required ReaderPageImageData imageData,
    int? cacheWidth,
  }) async {
    if (imageData is ReaderDirPageImageData) {
      await precacheReaderFilePath(
        context: context,
        filePath: imageData.file.path,
        cacheWidth: cacheWidth,
      );
      return;
    }
    if (imageData is! ReaderArchivePageImageData) {
      return;
    }
    final ReaderPagePayload page = await ref.read(
      comicReaderPageProvider(
        comicId: imageData.comicId,
        pageIndex: imageData.pageIndex,
      ).future,
    );
    if (!_isPrecacheStillValid(
          comicId: comicId,
          generation: generation,
          pageOneBased: imageData.pageIndex + 1,
        ) ||
        !context.mounted) {
      return;
    }
    switch (page) {
      case ReaderPageFilePath(:final String path):
        await precacheReaderFilePath(
          context: context,
          filePath: path,
          cacheWidth: cacheWidth,
        );
      case ReaderPageBytes(:final Uint8List data):
        final ImageProvider<Object>? provider = buildReaderImageProvider(
          memoryBytes: data,
          cacheWidth: cacheWidth,
        );
        if (provider == null) {
          return;
        }
        try {
          await precacheReaderImage(context: context, provider: provider);
        } on Object {
          // 单页预热失败不阻断窗口内其余页。
        }
    }
  }

  Future<void> warmOpenComic({
    required String comicId,
    int? resumePageOneBased,
  }) async {
    final snapshot = await ref.read(
      readerSessionOpenProvider(comicId: comicId).future,
    );
    final int center = resumePageOneBased ?? snapshot.resumePageIndex;
    await ref.read(comicImagesProvider(comicId: comicId).future);
    await warmWindow(
      comicId: comicId,
      centerPageOneBased: center,
      totalPages: snapshot.totalPages,
    );
  }
}
