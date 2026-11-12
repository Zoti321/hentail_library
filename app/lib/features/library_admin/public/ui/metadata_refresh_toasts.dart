import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_admin/domain/metadata_refresh_types.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/app_snackbar.dart';

String metadataRefreshBatchMessage(
  AppLocalizations l10n,
  MetadataRefreshBatchResult result,
) {
  if (result.skipped) {
    return result.skipMessage ?? l10n.refreshMetadataComicFailed;
  }
  if (result.cancelled) {
    return l10n.refreshMetadataBatchCancelled(result.succeeded, result.failed);
  }
  return l10n.refreshMetadataBatchDone(result.succeeded, result.failed);
}

void showMetadataRefreshBatchToast(
  BuildContext context,
  MetadataRefreshBatchResult result,
) {
  final String message = metadataRefreshBatchMessage(context.l10n, result);
  if (result.skipped || result.cancelled || result.failed > 0) {
    showInfoSnackbar(context, message);
    return;
  }
  showSuccessSnackbar(context, message);
}
