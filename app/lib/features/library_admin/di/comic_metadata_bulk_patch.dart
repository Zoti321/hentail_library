import 'package:hentai_library/shared/data/adapters/comic_metadata_bulk_patch_frb_adapter.dart';
import 'package:hentai_library/features/library_admin/domain/comic_metadata_bulk_patch_coordinator.dart';
import 'package:hentai_library/shared/di/library_command_providers.dart';
import 'package:hentai_library/features/bootstrap/di/repos.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/library_revision_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comic_metadata_bulk_patch.g.dart';

@Riverpod(keepAlive: true)
ComicMetadataBulkPatchFrbAdapter comicMetadataBulkPatchFrbAdapter(Ref ref) {
  return ComicMetadataBulkPatchFrbAdapter(
    libraryRepository: ref.read(libraryRepoProvider),
  );
}

@Riverpod(keepAlive: true)
ComicMetadataBulkPatchCoordinator comicMetadataBulkPatchCoordinator(Ref ref) {
  return ComicMetadataBulkPatchCoordinator(
    adapter: ref.read(comicMetadataBulkPatchFrbAdapterProvider),
    onSucceeded: () {
      ref.read(libraryRevisionProvider.notifier).notifyExternalChange();
    },
    onDictionariesChanged:
        ({
          required bool tagsWritten,
          required bool authorsWritten,
          required bool parodiesWritten,
          required bool charactersWritten,
        }) {
          ref
              .read(dictionaryInvalidationPortProvider)
              .invalidate(
                tagsWritten: tagsWritten,
                authorsWritten: authorsWritten,
                parodiesWritten: parodiesWritten,
                charactersWritten: charactersWritten,
              );
        },
  );
}
