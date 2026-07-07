import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_state.dart';
import 'package:hentai_library/ui/features/library/view_models/library_comics_catalog_controller.dart';
import 'package:hentai_library/ui/features/library/view_models/library_series_catalog_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_catalog_prefetch_notifier.g.dart';

/// 当前 Tab 显示时预取另一 Tab 数据，减少切换等待。
@Riverpod(keepAlive: true)
class LibraryCatalogPrefetch extends _$LibraryCatalogPrefetch {
  ProviderSubscription<AsyncValue<LibraryComicsCatalogState>>? _comicsSub;
  ProviderSubscription<AsyncValue<LibrarySeriesCatalogState>>? _seriesSub;
  bool _inactivePrefetched = false;

  @override
  void build() {
    ref.onDispose(() {
      _comicsSub?.close();
      _seriesSub?.close();
    });

    final LibraryDisplayTarget target = ref.watch(libraryDisplayTargetProvider);
    _bindActiveUntilPrefetch(target);

    ref.listen(libraryDisplayTargetProvider, (
      LibraryDisplayTarget? previous,
      LibraryDisplayTarget next,
    ) {
      if (previous == null || previous == next) {
        return;
      }
      _inactivePrefetched = false;
      _bindActiveUntilPrefetch(next);
      _ensureTargetTabSubscribed(next);
    });
  }

  void _bindActiveUntilPrefetch(LibraryDisplayTarget target) {
    _comicsSub?.close();
    _seriesSub?.close();

    if (target == LibraryDisplayTarget.comics) {
      _comicsSub = ref.listen(libraryComicsCatalogControllerProvider, (
        AsyncValue<LibraryComicsCatalogState>? previous,
        AsyncValue<LibraryComicsCatalogState> next,
      ) {
        if (!_inactivePrefetched && next.hasValue) {
          _inactivePrefetched = true;
          _subscribeSeries();
        }
      }, fireImmediately: true);
      return;
    }

    _seriesSub = ref.listen(librarySeriesCatalogControllerProvider, (
      AsyncValue<LibrarySeriesCatalogState>? previous,
      AsyncValue<LibrarySeriesCatalogState> next,
    ) {
      if (!_inactivePrefetched && next.hasValue) {
        _inactivePrefetched = true;
        _subscribeComics();
      }
    }, fireImmediately: true);
  }

  void _ensureTargetTabSubscribed(LibraryDisplayTarget target) {
    final AsyncValue<Object?> catalogAsync = switch (target) {
      LibraryDisplayTarget.comics => ref.read(
        libraryComicsCatalogControllerProvider,
      ),
      LibraryDisplayTarget.series => ref.read(
        librarySeriesCatalogControllerProvider,
      ),
    };
    if (catalogAsync.hasValue) {
      return;
    }
    switch (target) {
      case LibraryDisplayTarget.comics:
        _subscribeComics();
      case LibraryDisplayTarget.series:
        _subscribeSeries();
    }
  }

  void _subscribeComics() {
    _comicsSub?.close();
    _comicsSub = ref.listen(libraryComicsCatalogControllerProvider, (_, _) {});
  }

  void _subscribeSeries() {
    _seriesSub?.close();
    _seriesSub = ref.listen(librarySeriesCatalogControllerProvider, (_, _) {});
  }
}
