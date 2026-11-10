import 'package:hentai_library/features/library_admin/data/adapters/comic_metadata_bulk_patch_frb_adapter.dart';
import 'package:hentai_library/features/library_admin/application/comic_metadata_bulk_patch_coordinator.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/shared/di/domain_event_bus_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comic_metadata_bulk_patch.g.dart';

@Riverpod(keepAlive: true)
ComicMetadataBulkPatchFrbAdapter comicMetadataBulkPatchFrbAdapter(Ref ref) {
  return ComicMetadataBulkPatchFrbAdapter(
    libraryRepository: ref.read(libraryRepoProvider),
  );
}

@Riverpod(keepAlive: true)
ComicMetadataBulkPatchCoordinator comicMetadataBulkPatchCoordinator(Ref ref) {
  return ComicMetadataBulkPatchCoordinator(
    adapter: ref.read(comicMetadataBulkPatchFrbAdapterProvider),
    events: ref.read(domainEventBusProvider),
  );
}
