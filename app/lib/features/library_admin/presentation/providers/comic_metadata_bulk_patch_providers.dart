import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/library_admin/domain/comic_metadata_bulk_patch_port.dart';
import 'package:hentai_library/features/library_admin/application/comic_metadata_bulk_patch_coordinator.dart';
import 'package:hentai_library/shared/presentation/providers/domain_event_bus_providers.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';

final Provider<ComicMetadataBulkPatchPort> comicMetadataBulkPatchPortProvider =
    requiredProvider('comicMetadataBulkPatchPortProvider');
final comicMetadataBulkPatchCoordinatorProvider =
    Provider<ComicMetadataBulkPatchCoordinator>(
      (ref) => ComicMetadataBulkPatchCoordinator(
        adapter: ref.read(comicMetadataBulkPatchPortProvider),
        events: ref.read(domainEventBusProvider),
      ),
    );
