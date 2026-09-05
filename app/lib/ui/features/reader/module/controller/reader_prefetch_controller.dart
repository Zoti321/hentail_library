import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hentai_library/domain/reading/reader_page_payload.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_image_cache.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_prefetch_logic.dart';
import 'package:hentai_library/ui/features/reader/module/session/reader_session_bindings.dart';
import 'package:hentai_library/ui/features/reader/view_models/read_session_page_data.dart';
import 'package:hentai_library/ui/features/reader/view_models/read_session_providers.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reader_prefetch_controller.g.dart';

@Riverpod(keepAlive: true)
class ReaderPrefetchController extends _$ReaderPrefetchController {
  final Map<String, Set<int>> _lastWarmWindows = <String, Set<int>>{};

  @override
  Map<String, int> build() => <String, int>{};

  int bumpGeneration(String comicId) {
    final int next = (state[comicId] ?? 0) + 1;
    state = <String, int>{...state, comicId: next};
    return next;
  }

  void clearComic(String comicId) {
    // Invalidate Flutter-side prefetch generation before disk clear.
    bumpGeneration(comicId);
    _lastWarmWindows.remove(comicId);
    if (state.containsKey(comicId)) {
      state = Map<String, int>.from(state)..remove(comicId);
    }
    clearReaderImageCache();
    // Fire-and-forget: async FRB must not block exit navigation (P2-4).
    unawaited(
      ref.read(readerSessionServiceProvider).clearPageCache(comicId: comicId),
    );
    ref.invalidate(comicReaderPageProvider);
  }

  Future<void> warmWindow({
    required String comicId,
    required int centerPageOneBased,
    required int totalPages,
    Iterable<int> extraPageIndexesOneBased = const <int>[],
  }) async {
    if (totalPages <= 0) {
      return;
    }
    final Set<int> targets = computePrefetchWindow(
      centerPageOneBased: centerPageOneBased,
      totalPages: totalPages,
      neighborCount: kReaderPrefetchNeighborCount,
      extraPageIndexesOneBased: extraPageIndexesOneBased,
    );
    final Set<int>? previous = _lastWarmWindows[comicId];
    if (!shouldBumpPrefetchGeneration(
      previousWindow: previous,
      nextWindow: targets,
    )) {
      return;
    }
    _lastWarmWindows[comicId] = Set<int>.from(targets);
    final int generation = bumpGeneration(comicId);
    unawaited(
      ref
          .read(readerSessionServiceProvider)
          .prefetchPages(
            comicId: comicId,
            archivePageIndexes: targets
                .map((int pageOneBased) => pageOneBased - 1)
                .toList(growable: false),
            generation: generation,
          ),
    );
  }

  Future<void> precacheWindow({
    required BuildContext context,
    required String comicId,
    required Set<int> pageIndexesOneBased,
    required List<ReaderPageImageData> imageList,
    int? cacheWidth,
  }) async {
    if (pageIndexesOneBased.isEmpty || imageList.isEmpty) {
      return;
    }
    final int generation = state[comicId] ?? 0;
    ensureReaderImageCacheConfigured();
    for (final int pageOneBased in pageIndexesOneBased) {
      if ((state[comicId] ?? 0) != generation || !context.mounted) {
        return;
      }
      if (pageOneBased < 1 || pageOneBased > imageList.length) {
        continue;
      }
      final ReaderPageImageData imageData = imageList[pageOneBased - 1];
      final ImageProvider<Object>? provider = await _resolveReaderImageProvider(
        imageData: imageData,
        cacheWidth: cacheWidth,
      );
      if (provider == null) {
        continue;
      }
      if ((state[comicId] ?? 0) != generation || !context.mounted) {
        return;
      }
      try {
        await precacheReaderImage(context: context, provider: provider);
      } on Object {
        // 单页预热失败不阻断窗口内其余页。
      }
    }
  }

  Future<ImageProvider<Object>?> _resolveReaderImageProvider({
    required ReaderPageImageData imageData,
    int? cacheWidth,
  }) async {
    if (imageData is ReaderDirPageImageData) {
      return buildReaderImageProvider(
        filePath: imageData.file.path,
        cacheWidth: cacheWidth,
      );
    }
    if (imageData is! ReaderArchivePageImageData) {
      return null;
    }
    final ReaderPagePayload page = await ref.read(
      comicReaderPageProvider(
        comicId: imageData.comicId,
        pageIndex: imageData.pageIndex,
      ).future,
    );
    return switch (page) {
      ReaderPageFilePath(:final String path) => buildReaderImageProvider(
        filePath: path,
        cacheWidth: cacheWidth,
      ),
      ReaderPageBytes(:final Uint8List data) => buildReaderImageProvider(
        memoryBytes: data,
        cacheWidth: cacheWidth,
      ),
    };
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
