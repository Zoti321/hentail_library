import 'package:hentai_library/features/library_admin/data/adapters/sync_library_frb_adapter.dart';
import 'package:hentai_library/shared/domain/library/sync_library_port.dart';
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
