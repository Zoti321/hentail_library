import 'package:hentai_library/features/library_admin/application/library_write_service.dart';
import 'package:hentai_library/features/library_admin/public/di/library_admin_state_providers.dart';
import 'package:hentai_library/shared/di/domain_event_bus_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_write.g.dart';

@Riverpod(keepAlive: true)
LibraryWriteService libraryWriteService(Ref ref) => LibraryWriteService(
  repository: ref.read(libraryRepoProvider),
  events: ref.read(domainEventBusProvider),
);
