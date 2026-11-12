import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/library_admin/application/metadata_refresh_use_case.dart';
import 'package:hentai_library/features/library_admin/domain/metadata_refresh_port.dart';
import 'package:hentai_library/shared/presentation/providers/domain_event_bus_providers.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';

final Provider<MetadataRefreshPort> metadataRefreshPortProvider =
    requiredProvider('metadataRefreshPortProvider');
final metadataRefreshUseCaseProvider = Provider<MetadataRefreshUseCase>(
  (ref) => MetadataRefreshUseCase(
    port: ref.watch(metadataRefreshPortProvider),
    events: ref.read(domainEventBusProvider),
  ),
);
