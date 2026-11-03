import 'package:hentai_library/features/library_admin/application/sync_library_use_case.dart';
import 'package:hentai_library/features/library_admin/data/adapters/sync_library_frb_adapter.dart';
import 'package:hentai_library/features/library_admin/data/local_library_root_access.dart';
import 'package:hentai_library/features/library_admin/domain/sync_library_port.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/library_revision_notifier.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_sync.g.dart';

@Riverpod(keepAlive: true)
SyncLibraryFrbAdapter syncLibraryFrbAdapter(Ref ref) {
  return SyncLibraryFrbAdapter(
    libraryRepository: ref.read(libraryRepoProvider),
  );
}

/// FRB 适配器之上的 Library sync 接缝；测试可 override。
@Riverpod(keepAlive: true)
SyncLibraryPort syncLibraryPort(Ref ref) {
  return ref.watch(syncLibraryFrbAdapterProvider);
}

@Riverpod(keepAlive: true)
SyncLibraryUseCase syncLibraryUseCase(Ref ref) {
  return SyncLibraryUseCase(
    port: ref.watch(syncLibraryPortProvider),
    ensureLocalFilesystemAccess: ensureLocalFilesystemAccess,
    onCatalogRevision: () {
      ref.read(libraryRevisionProvider.notifier).notifyExternalChange();
    },
  );
}
