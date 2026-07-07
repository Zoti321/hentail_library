import 'dart:async';
import 'dart:typed_data';

import 'package:hentai_library/core/logging/log_manager.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/thumbnail/thumbnail_event.dart';
import 'package:hentai_library/ui/core/dto/comic_cover_image.dart';
import 'package:hentai_library/ui/core/dto/comic_cover_state.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comic_cover_providers.g.dart';

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

@Riverpod(keepAlive: true)
class ComicCoverThumbnailCache extends _$ComicCoverThumbnailCache {
  @override
  Uint8List? build(String comicId) => null;

  void set(Uint8List bytes) {
    state = bytes;
  }

  void clear() {
    state = null;
  }
}

@Riverpod()
class ComicCover extends _$ComicCover {
  String? _comicId;
  bool _loadInFlight = false;
  ThumbnailPriority _priority = ThumbnailPriority.high;

  @override
  ComicCoverState build(String comicId) {
    _comicId = comicId;
    final Uint8List? cached = ref.watch(
      comicCoverThumbnailCacheProvider(comicId),
    );
    if (cached != null && cached.isNotEmpty) {
      return ComicCoverReady(ComicCoverImage.bytes(cached));
    }
    Future.microtask(() => ensureLoaded());
    return const ComicCoverLoading();
  }

  void ensureLoaded({ThumbnailPriority priority = ThumbnailPriority.high}) {
    if (priority.index < _priority.index) {
      _priority = priority;
    }
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
    state = ComicCoverReady(ComicCoverImage.bytes(bytes));
  }

  void markDecodeError() {
    final String? comicId = _comicId;
    if (comicId == null) {
      return;
    }
    ref.read(comicCoverThumbnailCacheProvider(comicId).notifier).clear();
    state = const ComicCoverError();
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

    final ComicCoverImage? previous = switch (state) {
      ComicCoverLoading(:final previous) => previous,
      ComicCoverReady(:final data) => data,
      _ => null,
    };
    state = ComicCoverLoading(previous: previous);
    _loadInFlight = true;
    try {
      final Comic? comic = await ref.read(comicRepoProvider).findById(comicId);
      if (!ref.mounted) {
        return;
      }
      if (comic == null) {
        state = const ComicCoverNoCover();
        return;
      }

      final repo = ref.read(comicThumbnailRepoProvider);
      Uint8List? bytes = (await repo.findByComicId(comicId))?.thumbnail;
      if (!ref.mounted) {
        return;
      }
      if (bytes == null || bytes.isEmpty) {
        final ensured = await repo.ensureByComicId(
          comicId: comicId,
          priority: _priority,
        );
        bytes = ensured?.thumbnail;
      }
      if (!ref.mounted) {
        return;
      }
      if (bytes == null || bytes.isEmpty) {
        state = const ComicCoverNoCover();
        return;
      }
      ref.read(comicCoverThumbnailCacheProvider(comicId).notifier).set(bytes);
      state = ComicCoverReady(ComicCoverImage.bytes(bytes));
    } on Object catch (error, stackTrace) {
      LogManager.instance.handle(
        error,
        stackTrace,
        '加载漫画封面失败: comicId=$comicId',
      );
      if (ref.mounted) {
        state = ComicCoverError(cause: error);
      }
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
      case ThumbnailReady(:final String comicId):
        unawaited(_onThumbnailReady(comicId));
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

  Future<void> _onThumbnailReady(String comicId) async {
    try {
      final record = await ref
          .read(comicThumbnailRepoProvider)
          .findByComicId(comicId);
      final Uint8List? bytes = record?.thumbnail;
      if (bytes == null || bytes.isEmpty || !ref.mounted) {
        return;
      }
      ref.read(comicCoverThumbnailCacheProvider(comicId).notifier).set(bytes);
      ref.read(comicCoverProvider(comicId).notifier).setReady(bytes);
    } on Object catch (error, stackTrace) {
      LogManager.instance.handle(
        error,
        stackTrace,
        '缩略图就绪后刷新封面失败: comicId=$comicId',
      );
    }
  }
}
