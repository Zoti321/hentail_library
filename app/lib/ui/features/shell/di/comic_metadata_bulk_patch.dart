import 'package:hentai_library/data/adapters/comic_metadata_bulk_patch_frb_adapter.dart';
import 'package:hentai_library/domain/library/comic_metadata_bulk_patch_coordinator.dart';
import 'package:hentai_library/ui/features/library/view_models/library_include_set_filter_notifier.dart';
import 'package:hentai_library/ui/features/metadata/view_models/author_management_notifier.dart';
import 'package:hentai_library/ui/features/metadata/view_models/named_facet_dictionary_providers.dart';
import 'package:hentai_library/ui/features/metadata/view_models/tag_management_notifier.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:hentai_library/ui/features/shell/view_models/library_revision_notifier.dart';
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
          if (tagsWritten) {
            ref.invalidate(allTagsProvider);
          }
          if (authorsWritten) {
            ref.invalidate(allAuthorsProvider);
          }
          if (parodiesWritten) {
            ref.invalidate(allParodiesProvider);
            ref.invalidate(libraryDistinctParodiesProvider);
          }
          if (charactersWritten) {
            ref.invalidate(allCharactersProvider);
            ref.invalidate(libraryDistinctCharactersProvider);
          }
        },
  );
}
