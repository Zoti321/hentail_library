import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_comics_catalog_controller.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_series_catalog_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_catalog_inactive_subscription.g.dart';

/// 对非活跃 Tab 保持 catalog 订阅，使切 Tab 时无需冷启动。
///
/// 首次 [build] 延后到 microtask，避免与活跃 Tab 首屏 fetch 抢同一帧。
@Riverpod(keepAlive: true)
class LibraryCatalogInactiveSubscription
    extends _$LibraryCatalogInactiveSubscription {
  ProviderSubscription<Object?>? _inactiveSub;
  bool _disposed = false;

  @override
  void build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _inactiveSub?.close();
      _inactiveSub = null;
    });

    final LibraryDisplayTarget active = ref.watch(libraryDisplayTargetProvider);
    scheduleMicrotask(() {
      if (_disposed) {
        return;
      }
      _bindInactive(active);
    });

    ref.listen(libraryDisplayTargetProvider, (
      LibraryDisplayTarget? previous,
      LibraryDisplayTarget next,
    ) {
      if (previous == null || previous == next) {
        return;
      }
      _bindInactive(next);
    });
  }

  void _bindInactive(LibraryDisplayTarget active) {
    _inactiveSub?.close();
    _inactiveSub = switch (active) {
      LibraryDisplayTarget.comics => ref.listen(
        librarySeriesCatalogControllerProvider,
        (_, _) {},
      ),
      LibraryDisplayTarget.series => ref.listen(
        libraryComicsCatalogControllerProvider,
        (_, _) {},
      ),
    };
  }
}
