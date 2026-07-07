import 'dart:async';
import 'dart:typed_data';

import 'package:hentai_library/core/logging/log_manager.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/src/rust/api/thumbnail.dart';
import 'package:hentai_library/ui/core/dto/comic_cover_display_data.dart';
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
  ThumbnailPriorityDto _priority = ThumbnailPriorityDto.high;

  @override
  ComicCoverState build(String comicId) {
    _comicId = comicId;
    final Uint8List? cached = ref.watch(
      comicCoverThumbnailCacheProvider(comicId),
    );
    if (cached != null && cached.isNotEmpty) {
      return ComicCoverReady(ComicCoverDisplayData.bytes(cached));
    }
    Future.microtask(() => ensureLoaded());
    return const ComicCoverLoading();
  }

  void ensureLoaded({ThumbnailPriorityDto priority = ThumbnailPriorityDto.high}) {
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
    state = ComicCoverReady(ComicCoverDisplayData.bytes(bytes));
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

    final ComicCoverDisplayData? previous = switch (state) {
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
      state = ComicCoverReady(ComicCoverDisplayData.bytes(bytes));
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
  StreamSubscription<ThumbnailEventDto>? _subscription;

  @override
  ThumbnailBackgroundProgress build() {
    ref.onDispose(() {
      unawaited(_subscription?.cancel());
      _subscription = null;
    });
    _subscription ??= watchThumbnailEventsFrb().listen(_onEvent);
    return const ThumbnailBackgroundProgress();
  }

  void _onEvent(ThumbnailEventDto event) {
    switch (event) {
      case ThumbnailEventDto_Ready(:final comicId):
        unawaited(_onThumbnailReady(comicId));
      case ThumbnailEventDto_Progress(:final done, :final total, :final failed):
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
