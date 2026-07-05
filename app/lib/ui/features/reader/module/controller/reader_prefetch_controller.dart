import 'dart:typed_data';

import 'package:hentai_library/core/image/image_quality_policy.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_prefetch_logic.dart';
import 'package:hentai_library/ui/features/reader/module/session/reader_session_bindings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reader_prefetch_controller.g.dart';

@Riverpod(keepAlive: true)
class ReaderPrefetchController extends _$ReaderPrefetchController {
  @override
  Map<String, Uint8List> build() => <String, Uint8List>{};

  Uint8List? cachedBytes({
    required String comicId,
    required int archivePageIndex,
  }) {
    return state[readerPrefetchCacheKey(comicId, archivePageIndex)];
  }

  void clearComic(String comicId) {
    if (state.keys.every((String key) => !key.startsWith('$comicId:'))) {
      return;
    }
    state = Map<String, Uint8List>.fromEntries(
      state.entries.where(
        (MapEntry<String, Uint8List> entry) => !entry.key.startsWith('$comicId:'),
      ),
    );
  }

  Future<void> warmWindow({
    required String comicId,
    required int centerPageOneBased,
    required int totalPages,
    Iterable<int> extraPageIndexesOneBased = const <int>[],
    int? neighborCount,
  }) async {
    if (totalPages <= 0) {
      return;
    }
    final int windowSize =
        neighborCount ?? ImageQualityPolicy.current.readerPrecacheNeighborCount;
    final Set<int> targets = computePrefetchWindow(
      centerPageOneBased: centerPageOneBased,
      totalPages: totalPages,
      neighborCount: windowSize,
      extraPageIndexesOneBased: extraPageIndexesOneBased,
    );
    final Map<String, Uint8List> updates = <String, Uint8List>{};
    await Future.wait(
      targets.map((int pageOneBased) async {
        final int archiveIndex = pageOneBased - 1;
        final String key = readerPrefetchCacheKey(comicId, archiveIndex);
        if (state.containsKey(key)) {
          return;
        }
        final Uint8List? bytes = await ref.read(
          comicReaderPageBytesProvider(
            comicId: comicId,
            pageIndex: archiveIndex,
          ).future,
        );
        if (bytes != null && bytes.isNotEmpty) {
          updates[key] = bytes;
        }
      }),
    );
    if (updates.isEmpty &&
        !state.keys.any((String key) => key.startsWith('$comicId:'))) {
      return;
    }
    final Map<String, Uint8List> merged = <String, Uint8List>{...state, ...updates};
    state = evictPrefetchOutsideWindow(
      cache: merged,
      comicId: comicId,
      keepPagesOneBased: targets,
      maxEntriesPerComic: windowSize * 2 + 3,
    );
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
