import 'package:hentai_library/features/library_admin/data/adapters/sync_library_frb_adapter.dart';
import 'package:hentai_library/features/library_admin/domain/library_sync_coordinator.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/library_revision_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_sync.g.dart';

@Riverpod(keepAlive: true)
SyncLibraryFrbAdapter syncLibraryFrbAdapter(Ref ref) {
  return SyncLibraryFrbAdapter(
    libraryRepository: ref.read(libraryRepoProvider),
  );
}

@Riverpod(keepAlive: true)
LibrarySyncCoordinator librarySyncCoordinator(Ref ref) {
  return LibrarySyncCoordinator(
    syncAdapter: ref.read(syncLibraryFrbAdapterProvider),
    onSyncSucceeded: () {
      ref.read(libraryRevisionProvider.notifier).notifyExternalChange();
    },
  );
}
