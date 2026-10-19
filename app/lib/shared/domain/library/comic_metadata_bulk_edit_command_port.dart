import 'package:hentai_library/shared/domain/library/comic_metadata_bulk_patch_types.dart';

/// 批量元数据编辑的命令端口（#261c）。
///
/// 保留 library_admin 控制器的行为：运行状态、写入互斥守卫、自动备份与 revision 通知。
/// 实现位于 `features/library_admin/di/shared_state_ports.dart`。
abstract class ComicMetadataBulkEditCommandPort {
  Future<ComicMetadataBulkPatchResult> apply({
    required List<String> comicIds,
    required ComicMetadataBulkPatch patch,
  });
}
