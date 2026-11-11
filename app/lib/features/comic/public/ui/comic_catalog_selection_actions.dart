import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/features/comic/di/comic_detail_providers.dart';
import 'package:hentai_library/features/comic/public/ui/bulk_edit_metadata_presenter.dart';
import 'package:hentai_library/features/comic/public/ui/comic_metadata_edit_presenters.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/domain/catalog/selection/catalog_selection_notifier.dart';
import 'package:hentai_library/shared/domain/library/comic_metadata_bulk_patch.dart';
import 'package:hentai_library/features/comic/domain/comic.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/app_snackbar.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/comic_metadata_bulk_patch_toasts.dart';

/// 多选批量编辑：读当前选择，逐条或批量走 owner 命令。
Future<void> openComicSelectionMetadataEditor(
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
    final Comic? comic = await ref.read(comicDetailProvider(ids.first).future);
    if (!context.mounted || comic == null) {
      return;
    }
    await showComicMetadataEdit(context: context, comic: comic);
    if (context.mounted && exitSelectionOnDone) {
      ref.read(catalogSelectionProvider.notifier).exit();
    }
    return;
  }

  final ComicMetadataBulkPatch? patch = await showBulkEditMetadata(
    context: context,
    comicIds: ids,
  );
  if (!context.mounted || patch == null) {
    return;
  }

  await applyComicMetadataBulkPatchForComicIds(
    context,
    ref,
    comicIds: ids,
    patch: patch,
    exitSelectionOnDone: exitSelectionOnDone,
  );
}

/// 批量 patch 写入与结果 toast（由 [openComicMetadataEditorForIds] 在 MD3E 面板确认后调用）。
Future<void> applyComicMetadataBulkPatchForComicIds(
  BuildContext context,
  WidgetRef ref, {
  required List<String> comicIds,
  required ComicMetadataBulkPatch patch,
  bool exitSelectionOnDone = false,
}) async {
  try {
    final ComicMetadataBulkPatchResult result = await ref
        .read(comicMetadataBulkEditCommandPortProvider)
        .apply(comicIds: comicIds, patch: patch);
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
      showErrorSnackbar(context, err);
    } else {
      showErrorSnackbar(context, AppException(err.toString()));
    }
  }
}
