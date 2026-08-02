import 'package:hentai_library/data/adapters/metadata_refresh_frb_adapter.dart';
import 'package:hentai_library/domain/library/metadata_refresh_coordinator.dart';
import 'package:hentai_library/ui/features/shell/state/library_revision_notifier.dart';
import 'package:hentai_library/ui/features/shell/state/scan_library_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'metadata_refresh.g.dart';

@Riverpod(keepAlive: true)
MetadataRefreshFrbAdapter metadataRefreshFrbAdapter(Ref ref) {
  return const MetadataRefreshFrbAdapter();
}

@Riverpod(keepAlive: true)
MetadataRefreshCoordinator metadataRefreshCoordinator(Ref ref) {
  return MetadataRefreshCoordinator(
    adapter: ref.read(metadataRefreshFrbAdapterProvider),
    onSucceeded: () {
      ref.read(libraryRevisionProvider.notifier).notifyExternalChange();
    },
    isLibrarySyncRunning: () =>
        ref.read(scanLibraryControllerProvider).running,
  );
}
