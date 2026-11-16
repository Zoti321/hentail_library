import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_sync_outcome.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_library_providers.dart';
import 'package:hentai_library/features/library_admin/public.dart';

/// 当前 Image set 浏览页最近一次手动同步终态；页面离开即释放，迟到结果不写入已销毁状态。
class ImageSetSyncController extends Notifier<ImageSetSyncOutcome?> {
  @override
  ImageSetSyncOutcome? build() => null;

  Future<void> sync(String libraryId) async {
    if (ref.read(librarySyncStateProvider).running) {
      return;
    }
    final ImageSetSyncOutcome outcome = await ref.read(
      syncImageSetLibraryCommandProvider,
    )(libraryId);
    if (ref.mounted) {
      state = outcome;
    }
  }
}

final imageSetSyncControllerProvider =
    NotifierProvider.autoDispose<ImageSetSyncController, ImageSetSyncOutcome?>(
      ImageSetSyncController.new,
    );
