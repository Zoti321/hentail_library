import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/library_admin/application/sync_library_use_case.dart';
import 'package:hentai_library/features/library_admin/domain/sync_library_port.dart';
import 'package:hentai_library/shared/presentation/providers/domain_event_bus_providers.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';

final Provider<SyncLibraryPort> syncLibraryPortProvider = requiredProvider(
  'syncLibraryPortProvider',
);
final Provider<Future<void> Function()> localFilesystemAccessProvider =
    requiredProvider('localFilesystemAccessProvider');
final Provider<Future<bool> Function(String)> localLibraryRootReadableProvider =
    requiredProvider('localLibraryRootReadableProvider');
final syncLibraryUseCaseProvider = Provider<SyncLibraryUseCase>(
  (ref) => SyncLibraryUseCase(
    port: ref.watch(syncLibraryPortProvider),
    ensureLocalFilesystemAccess: () =>
        ref.read(localFilesystemAccessProvider)(),
    events: ref.read(domainEventBusProvider),
  ),
);
