import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/ui/features/library/view_models/library_comics_catalog_controller.dart';
import 'package:hentai_library/ui/features/library/view_models/library_series_catalog_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_catalog_prefetch_notifier.g.dart';

/// 对非活跃 Tab 保持 catalog 订阅，使 revision 变化时两 Tab 同步失效。
@Riverpod(keepAlive: true)
class LibraryCatalogPrefetch extends _$LibraryCatalogPrefetch {
  ProviderSubscription<Object?>? _inactiveSub;

  @override
  void build() {
    ref.onDispose(() {
      _inactiveSub?.close();
    });

    _bindInactive(ref.watch(libraryDisplayTargetProvider));

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
