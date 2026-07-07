import 'package:hentai_library/data/adapters/sync_library_frb_adapter.dart';
import 'package:hentai_library/domain/library/library_sync_coordinator.dart';
import 'package:hentai_library/ui/features/shell/di/ports.dart';
import 'package:hentai_library/ui/features/shell/state/library_revision_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_sync.g.dart';

@Riverpod(keepAlive: true)
SyncLibraryFrbAdapter syncLibraryFrbAdapter(Ref ref) {
  return SyncLibraryFrbAdapter();
}

@Riverpod(keepAlive: true)
LibrarySyncCoordinator librarySyncCoordinator(Ref ref) {
  return LibrarySyncCoordinator(
    syncAdapter: ref.read(syncLibraryFrbAdapterProvider),
    readerSessionPort: ref.read(readerSessionPortProvider),
    onSyncSucceeded: () {
      ref.read(libraryRevisionProvider.notifier).notifyExternalChange();
    },
  );
}
