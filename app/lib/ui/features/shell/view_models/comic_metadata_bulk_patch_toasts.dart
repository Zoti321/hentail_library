import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/library/comic_metadata_bulk_patch_types.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';

String comicMetadataBulkPatchMessage(
  AppLocalizations l10n,
  ComicMetadataBulkPatchResult result,
) {
  if (result.cancelled) {
    return l10n.bulkEditMetadataBatchCancelled(
      result.succeeded,
      result.failed,
      result.unchanged,
    );
  }
  return l10n.bulkEditMetadataBatchDone(
    result.succeeded,
    result.failed,
    result.unchanged,
  );
}

void showComicMetadataBulkPatchToast(
  BuildContext context,
  ComicMetadataBulkPatchResult result,
) {
  final String message = comicMetadataBulkPatchMessage(context.l10n, result);
  if (result.cancelled || result.failed > 0) {
    showInfoToast(context, message);
    return;
  }
  if (result.succeeded == 0 && result.unchanged > 0) {
    showInfoToast(context, message);
    return;
  }
  showSuccessToast(context, message);
}
