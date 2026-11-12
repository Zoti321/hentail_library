import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:hentai_library/core/logging/app_log.dart';
import 'package:hentai_library/features/comic/di/comic_cover_load_gate.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/features/comic/domain/thumbnail/thumbnail_event.dart';
import 'package:hentai_library/shared/ui/models/comic_cover_source.dart';
import 'package:hentai_library/shared/ui/models/comic_cover_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hentai_library/features/comic/di/comic_repository_providers.dart';

part 'comic_cover_providers.g.dart';

/// Soft cap for keep-alive JPEG bytes retained after cover providers dispose.
const int kComicCoverThumbnailCacheMaxEntries = 160;

class ThumbnailBackgroundProgress {
  const ThumbnailBackgroundProgress({
    this.done = 0,
    this.total = 0,
    this.failed = 0,
  });

  final int done;
  final int total;
  final int failed;

  bool get isActive => total > 0 && done < total;
}

/// 漫画封面缓存管理（删除漫画后清理缓存）。
@Riverpod(keepAlive: true)
class ComicCoverCacheManager extends _$ComicCoverCacheManager {
  @override
  void build() {}

  void clearForComics(Iterable<String> comicIds) {
    for (final String comicId in comicIds) {
      ref.read(comicCoverThumbnailCacheProvider(comicId).notifier).clear();
      ref.invalidate(comicCoverProvider(comicId));
    }
  }
}

/// Touches / evicts [comicCoverThumbnailCacheProvider] entries (LRU).
@Riverpod(keepAlive: true)
class ComicCoverThumbnailLru extends _$ComicCoverThumbnailLru {
  final LinkedHashSet<String> _order = LinkedHashSet<String>();

  @override
  void build() {}

  void touch(String comicId) {
    _order.remove(comicId);
    _order.add(comicId);
    _evictOverflow();
  }

  void remove(String comicId) {
    _order.remove(comicId);
  }

  void _evictOverflow() {
    while (_order.length > kComicCoverThumbnailCacheMaxEntries) {
      final String? oldest = _order.isEmpty ? null : _order.first;
      if (oldest == null) {
        return;
      }
      _order.remove(oldest);
      // Drop keep-alive bytes only; active [comicCoverProvider] keeps Ready state.
      ref
          .read(comicCoverThumbnailCacheProvider(oldest).notifier)
          .clear(notifyLru: false);
    }
  }
}

@Riverpod(keepAlive: true)
class ComicCoverThumbnailCache extends _$ComicCoverThumbnailCache {
  @override
  Uint8List? build(String comicId) => null;

  void set(Uint8List bytes) {
    state = bytes;
    ref.read(comicCoverThumbnailLruProvider.notifier).touch(comicId);
  }

  void clear({bool notifyLru = true}) {
    state = null;
    if (notifyLru) {
      // 勿在 onDispose 里改其他 provider；仅主动 clear 时同步 LRU。
      ref.read(comicCoverThumbnailLruProvider.notifier).remove(comicId);
    }
  }
}

@Riverpod()
class ComicCover extends _$ComicCover {
  String? _comicId;
  bool _loadInFlight = false;

  /// 默认 low：同帧内 widget 可 [promotePriority] 到 high/critical 再 ensure。
  ThumbnailPriority _priority = ThumbnailPriority.low;

  @override
  ComicCoverState build(String comicId) {
    _comicId = comicId;
    // read（非 watch）：缓存逐出不会把已 Ready 的封面打回 Loading。
    final Uint8List? cached = ref.read(
      comicCoverThumbnailCacheProvider(comicId),
    );
    if (cached != null && cached.isNotEmpty) {
      return ComicCoverReady(ComicCoverSource.bytes(cached));
    }
    Future.microtask(() => ensureLoaded(priority: _priority));
    return const ComicCoverLoading();
  }

  void bumpPriority(ThumbnailPriority priority) {
    if (priority.index < _priority.index) {
      _priority = priority;
    }
  }

  /// Raises priority; re-hits ensure when a lower-priority load already ran
  /// (NoCover while queued) or is in flight, so Rust can upgrade the job.
  void promotePriority(ThumbnailPriority priority) {
    if (priority.index >= _priority.index) {
      return;
    }
    _priority = priority;
    if (state is ComicCoverReady) {
      return;
    }
    if (state is ComicCoverNoCover || _loadInFlight) {
      unawaited(_ensurePriorityUpgrade());
    }
  }

  void ensureLoaded({ThumbnailPriority priority = ThumbnailPriority.high}) {
    bumpPriority(priority);
    if (state is ComicCoverReady) {
      return;
    }
    unawaited(_load());
  }

  void setReady(Uint8List bytes) {
    final String? comicId = _comicId;
    if (comicId == null) {
      return;
    }
    ref.read(comicCoverThumbnailCacheProvider(comicId).notifier).set(bytes);
    state = ComicCoverReady(ComicCoverSource.bytes(bytes));
  }

  void markDecodeError() {
    final String? comicId = _comicId;
    if (comicId == null) {
      return;
    }
    ref.read(comicCoverThumbnailCacheProvider(comicId).notifier).clear();
    state = const ComicCoverError();
  }

  /// 解码失败后点按重试：清 Error 并重新 ensure。
  void retryLoad() {
    if (state is! ComicCoverError) {
      return;
    }
    state = const ComicCoverLoading();
    unawaited(_load());
  }

  Future<void> _ensurePriorityUpgrade() async {
    final String? comicId = _comicId;
    if (comicId == null || !ref.mounted) {
      return;
    }
    try {
      final record = await ref
          .read(comicThumbnailRepoProvider)
          .ensureByComicId(comicId: comicId, priority: _priority);
      if (!ref.mounted) {
        return;
      }
      final Uint8List? bytes = record?.thumbnail;
      if (bytes != null && bytes.isNotEmpty) {
        setReady(bytes);
      }
    } on Object catch (error, stackTrace) {
      logError(
        AppLog.ui('comic_cover'),
        '封面优先级升级 ensure 失败: comicId=$comicId',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _load() async {
    if (_loadInFlight) {
      return;
    }
    final String? comicId = _comicId;
    if (comicId == null) {
      return;
    }
    if (state is ComicCoverReady) {
      return;
    }

    final ComicCoverSource? previous = switch (state) {
      ComicCoverLoading(:final previous) => previous,
      ComicCoverReady(:final data) => data,
      ComicCoverNoCover() => null,
      ComicCoverError() => null,
    };
    state = ComicCoverLoading(previous: previous);
    _loadInFlight = true;
    try {
      if (!ref.mounted) {
        return;
      }
      // Capture deps before the gate wait — provider may dispose while queued.
      final thumbRepo = ref.read(comicThumbnailRepoProvider);

      await ComicCoverLoadGate.run(() async {
        if (!ref.mounted) {
          return;
        }
        // ensure 内部已 find；高/低优先级未就绪时入队并返回 null。
        final ensured = await thumbRepo.ensureByComicId(
          comicId: comicId,
          priority: _priority,
        );
        if (!ref.mounted) {
          return;
        }
        final Uint8List? bytes = ensured?.thumbnail;
        if (bytes == null || bytes.isEmpty) {
          state = const ComicCoverNoCover();
          return;
        }
        ref.read(comicCoverThumbnailCacheProvider(comicId).notifier).set(bytes);
        state = ComicCoverReady(ComicCoverSource.bytes(bytes));
      });
    } on Object catch (error, stackTrace) {
      if (!ref.mounted) {
        return;
      }
      logError(
        AppLog.ui('comic_cover'),
        '加载漫画封面失败: comicId=$comicId',
        error,
        stackTrace,
      );
      state = ComicCoverError(cause: error);
    } finally {
      _loadInFlight = false;
    }
  }
}

@Riverpod(keepAlive: true)
class ThumbnailEventCoordinator extends _$ThumbnailEventCoordinator {
  StreamSubscription<ThumbnailEvent>? _subscription;

  @override
  ThumbnailBackgroundProgress build() {
    ref.onDispose(() {
      unawaited(_subscription?.cancel());
      _subscription = null;
    });
    _subscription ??= ref
        .read(comicThumbnailRepoProvider)
        .watchEvents()
        .listen(_onEvent);
    return const ThumbnailBackgroundProgress();
  }

  void _onEvent(ThumbnailEvent event) {
    switch (event) {
      case ThumbnailReady(:final String comicId, :final Uint8List? thumbnail):
        unawaited(_onThumbnailReady(comicId, thumbnail));
      case ThumbnailProgress(
        :final int done,
        :final int total,
        :final int failed,
      ):
        state = ThumbnailBackgroundProgress(
          done: done,
          total: total,
          failed: failed,
        );
    }
  }

  Future<void> _onThumbnailReady(
    String comicId,
    Uint8List? embeddedThumbnail,
  ) async {
    try {
      Uint8List? bytes = embeddedThumbnail;
      if (bytes == null || bytes.isEmpty) {
        final record = await ref
            .read(comicThumbnailRepoProvider)
            .findByComicId(comicId);
        bytes = record?.thumbnail;
      }
      if (bytes == null || bytes.isEmpty || !ref.mounted) {
        return;
      }
      ref.read(comicCoverThumbnailCacheProvider(comicId).notifier).set(bytes);
      // 避免为后台批量 Ready 凭空创建 cover provider。
      if (ref.exists(comicCoverProvider(comicId))) {
        ref.read(comicCoverProvider(comicId).notifier).setReady(bytes);
      }
    } on Object catch (error, stackTrace) {
      logError(
        AppLog.ui('comic_cover'),
        '缩略图就绪后刷新封面失败: comicId=$comicId',
        error,
        stackTrace,
      );
    }
  }
}
