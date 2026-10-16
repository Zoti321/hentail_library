import 'package:hentai_library/data/adapters/metadata_refresh_frb_adapter.dart';
import 'package:hentai_library/features/library_admin/domain/metadata_refresh_coordinator.dart';
import 'package:hentai_library/features/bootstrap/di/repos.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/library_revision_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'metadata_refresh.g.dart';

@Riverpod(keepAlive: true)
MetadataRefreshFrbAdapter metadataRefreshFrbAdapter(Ref ref) {
  return MetadataRefreshFrbAdapter(
    libraryRepository: ref.read(libraryRepoProvider),
  );
}

@Riverpod(keepAlive: true)
MetadataRefreshCoordinator metadataRefreshCoordinator(Ref ref) {
  return MetadataRefreshCoordinator(
    adapter: ref.read(metadataRefreshFrbAdapterProvider),
    onSucceeded: () {
      ref.read(libraryRevisionProvider.notifier).notifyExternalChange();
    },
  );
}
