import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/library/metadata_refresh_types.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';

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
    showInfoToast(context, message);
    return;
  }
  showSuccessToast(context, message);
}
