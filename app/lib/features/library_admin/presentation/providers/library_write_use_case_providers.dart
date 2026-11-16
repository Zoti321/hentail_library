import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/library_admin/application/submit_library_form_use_case.dart';
import 'package:hentai_library/features/library_admin/application/delete_library_use_case.dart';
import 'package:hentai_library/features/library_admin/public/providers/library_admin_state_providers.dart';
import 'package:hentai_library/shared/presentation/providers/domain_event_bus_providers.dart';

final submitLibraryFormUseCaseProvider = Provider<SubmitLibraryFormUseCase>(
  (ref) => SubmitLibraryFormUseCase(
    ref.read(libraryRepoProvider),
    ref.read(domainEventBusProvider),
  ),
);
final deleteLibraryUseCaseProvider = Provider<DeleteLibraryUseCase>(
  (ref) => DeleteLibraryUseCase(
    ref.read(libraryRepoProvider),
    ref.read(domainEventBusProvider),
  ),
);
