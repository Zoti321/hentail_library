import 'package:flutter/material.dart';
import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/domain/library/comic_metadata_bulk_patch_types.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/features/library/view_models/catalog_selection_notifier.dart';
import 'package:hentai_library/ui/features/library/views/widgets/bulk_edit_metadata_dialog.dart';
import 'package:hentai_library/ui/features/library/views/widgets/edit_metadata_dialog.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:hentai_library/ui/features/shell/view_models/comic_metadata_bulk_patch_controller.dart';
import 'package:hentai_library/ui/features/shell/view_models/comic_metadata_bulk_patch_toasts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Future<void> openCatalogSelectionMetadataEditor(
  BuildContext context,
  WidgetRef ref,
) async {
  final CatalogSelectionState selection = ref.read(catalogSelectionProvider);
  if (selection.count == 0) {
    return;
  }
  final List<String> ids = selection.selectedIds.toList(growable: false);
  if (ids.length == 1) {
    final Comic? comic = await ref.read(comicRepoProvider).findById(ids.first);
    if (!context.mounted || comic == null) {
      return;
    }
    await showEditMetadataDialog(context: context, comic: comic);
    if (context.mounted) {
      ref.read(catalogSelectionProvider.notifier).exit();
    }
    return;
  }

  final ComicMetadataBulkPatch? patch = await showBulkEditMetadataDialog(
    context: context,
    comicIds: ids,
  );
  if (!context.mounted || patch == null) {
    return;
  }

  try {
    final ComicMetadataBulkPatchResult result = await ref
        .read(comicMetadataBulkPatchControllerProvider.notifier)
        .apply(comicIds: ids, patch: patch);
    if (!context.mounted) {
      return;
    }
    showComicMetadataBulkPatchToast(context, result);
    ref.read(catalogSelectionProvider.notifier).exit();
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
