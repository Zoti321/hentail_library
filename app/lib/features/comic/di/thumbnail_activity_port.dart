import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/comic/public/di/comic_cover_providers.dart';
import 'package:hentai_library/shared/domain/ports/thumbnail_activity_port.dart';

/// 由 comic 的缩略图事件协调器派生「后台是否活跃」。
class _ThumbnailActivityPortAdapter implements ThumbnailActivityPort {
  _ThumbnailActivityPortAdapter(this._ref);

  final Ref _ref;

  @override
  Stream<bool> watchBackgroundActive() {
    final StreamController<bool> controller = StreamController<bool>();
    controller.add(_ref.read(thumbnailEventCoordinatorProvider).isActive);
    final ProviderSubscription<ThumbnailBackgroundProgress> subscription = _ref
        .listen<ThumbnailBackgroundProgress>(
          thumbnailEventCoordinatorProvider,
          (ThumbnailBackgroundProgress? _, ThumbnailBackgroundProgress next) {
            controller.add(next.isActive);
          },
        );
    controller.onCancel = subscription.close;
    return controller.stream;
  }
}

ThumbnailActivityPort createThumbnailActivityPort(Ref ref) =>
    _ThumbnailActivityPortAdapter(ref);
