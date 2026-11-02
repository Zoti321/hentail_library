import 'package:flutter/material.dart';
import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/features/library_browse/presentation/views/metadata_edit_md3e/metadata_edit_presenters.dart';
import 'package:hentai_library/shared/domain/library/comic_metadata_bulk_patch_types.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/features/library_browse/presentation/catalog/view_models/catalog_selection_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_page_comics_providers.dart';
import 'package:hentai_library/features/library_browse/presentation/views/bulk_edit_md3e/bulk_edit_metadata_md3e_presenter.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/comic_metadata_bulk_patch_toasts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Future<void> openCatalogSelectionMetadataEditor(
  BuildContext context,
  WidgetRef ref,
) async {
  final CatalogSelectionState selection = ref.read(catalogSelectionProvider);
  if (selection.count == 0) {
    return;
  }
  await openComicMetadataEditorForIds(
    context,
    ref,
    selection.selectedIds.toList(growable: false),
    exitSelectionOnDone: true,
  );
}

Future<void> openComicMetadataEditorForIds(
  BuildContext context,
  WidgetRef ref,
  List<String> ids, {
  bool exitSelectionOnDone = false,
}) async {
  if (ids.isEmpty) {
    return;
  }
  if (ids.length == 1) {
    final Comic? comic = await ref.read(
      libraryComicDetailProvider(ids.first).future,
    );
    if (!context.mounted || comic == null) {
      return;
    }
    await showComicMetadataEditMd3e(context: context, comic: comic);
    if (context.mounted && exitSelectionOnDone) {
      ref.read(catalogSelectionProvider.notifier).exit();
    }
    return;
  }

  final ComicMetadataBulkPatch? patch = await showBulkEditMetadataMd3e(
    context: context,
    comicIds: ids,
  );
  if (!context.mounted || patch == null) {
    return;
  }

  try {
    final ComicMetadataBulkPatchResult result = await ref
        .read(comicMetadataBulkEditCommandPortProvider)
        .apply(comicIds: ids, patch: patch);
    if (!context.mounted) {
      return;
    }
    showComicMetadataBulkPatchToast(context, result);
    if (exitSelectionOnDone) {
      ref.read(catalogSelectionProvider.notifier).exit();
    }
  } catch (err) {
    if (!context.mounted) {
      return;
    }
    if (err is AppException) {
      showErrorToast(context, err);
    } else {
      showErrorToast(context, AppException(err.toString()));
    }
  }
}
