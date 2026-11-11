import 'package:hentai_library/features/library_admin/application/metadata_refresh_use_case.dart';
import 'package:hentai_library/features/library_admin/data/adapters/metadata_refresh_frb_adapter.dart';
import 'package:hentai_library/features/library_admin/domain/metadata_refresh_port.dart';
import 'package:hentai_library/features/library_admin/public/di/library_admin_state_providers.dart';
import 'package:hentai_library/shared/di/domain_event_bus_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'metadata_refresh.g.dart';

@Riverpod(keepAlive: true)
MetadataRefreshFrbAdapter metadataRefreshFrbAdapter(Ref ref) {
  return MetadataRefreshFrbAdapter(
    libraryRepository: ref.read(libraryRepoProvider),
  );
}

/// FRB 适配器之上的 Metadata refresh 接缝；测试可 override。
@Riverpod(keepAlive: true)
MetadataRefreshPort metadataRefreshPort(Ref ref) {
  return ref.watch(metadataRefreshFrbAdapterProvider);
}

@Riverpod(keepAlive: true)
MetadataRefreshUseCase metadataRefreshUseCase(Ref ref) {
  return MetadataRefreshUseCase(
    port: ref.watch(metadataRefreshPortProvider),
    events: ref.read(domainEventBusProvider),
  );
}
