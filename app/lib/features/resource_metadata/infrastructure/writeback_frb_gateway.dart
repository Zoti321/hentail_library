import 'package:hentai_library/features/resource_metadata/domain/writeback_gateway.dart';
import 'package:hentai_library/src/rust/api/resource_metadata.dart' as rust;

class WritebackFrbGateway implements WritebackGateway {
  @override
  Future<bool> isEnabled(String libraryId) =>
      rust.getResourceMetadataEnabled(libraryId: libraryId);
  @override
  Future<void> setEnabled(String libraryId, bool enabled) =>
      rust.setResourceMetadataEnabled(libraryId: libraryId, enabled: enabled);
  @override
  Future<bool> processNext() => rust.processResourceMetadataTick();
  @override
  Future<MediaOverview> overview({required bool showR18}) async {
    final summary = await rust.queryMediaOverview(showR18: showR18);
    return (
      total: summary.total.toInt(),
      disabled: summary.disabled.toInt(),
      pending: summary.pending.toInt(),
      processing: summary.processing.toInt(),
      completed: summary.completed.toInt(),
      failed: summary.failed.toInt(),
      unsupported: summary.unsupported.toInt(),
      localLibraries: summary.localLibraries.toInt(),
      enabledLibraries: summary.enabledLibraries.toInt(),
    );
  }
}
