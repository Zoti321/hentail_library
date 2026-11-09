import 'package:hentai_library/features/library_admin/domain/comic_metadata_bulk_patch_port.dart';
import 'package:hentai_library/features/library_admin/domain/comic_metadata_bulk_patch_types.dart';
import 'package:hentai_library/shared/domain/events/events.dart';

/// 批量 patch 编排：FRB bulk patch → 发布领域事件（ADR-0039）。
///
/// catalog 重读由 `ComicMetadataPersisted` 的 reducer 统一驱动，不再单独回调。
class ComicMetadataBulkPatchCoordinator {
  const ComicMetadataBulkPatchCoordinator({
    required this._adapter,
    required this._events,
  });

  final ComicMetadataBulkPatchPort _adapter;
  final DomainEventPublisher _events;

  Future<ComicMetadataBulkPatchResult> apply({
    required List<String> comicIds,
    required ComicMetadataBulkPatch patch,
  }) async {
    final ComicMetadataBulkPatchResult result = await _adapter.apply(
      comicIds: comicIds,
      patch: patch,
    );
    if (result.succeeded > 0) {
      _events.publish(
        ComicMetadataPersisted(
          tagsWritten: patch.tags != null,
          authorsWritten: patch.authors != null,
          parodiesWritten: patch.parodies != null,
          charactersWritten: patch.characters != null,
        ),
      );
    }
    return result;
  }

  void cancelActive() => _adapter.cancelActive();
}
