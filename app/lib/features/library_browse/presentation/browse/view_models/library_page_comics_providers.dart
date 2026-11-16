import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_comics_catalog_controller.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_series_catalog_controller.dart';

/// Action 门面：刷新变更通知并重置到第一页。
final Provider<VoidCallback> libraryRefreshActionProvider =
    Provider<VoidCallback>((Ref ref) {
      return () {
        ref.read(libraryComicsCatalogControllerProvider.notifier).refresh();
        ref.read(librarySeriesCatalogControllerProvider.notifier).refresh();
      };
    });
