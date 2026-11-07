import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/comic/presentation/views/bulk_edit/bulk_edit_metadata_form.dart';
import 'package:hentai_library/shared/ui/patterns/dialog/adaptive_form_dialog.dart';
import 'package:hentai_library/features/library_admin/public.dart';

/// 批量编辑入口（MD3E 面板）：返回用户确认后的 patch，取消则为 `null`。
Future<ComicMetadataBulkPatch?> showBulkEditMetadata({
  required BuildContext context,
  required List<String> comicIds,
}) {
  final AppLocalizations l10n = context.l10n;
  final GlobalKey<BulkEditMetadataFormState> formKey =
      GlobalKey<BulkEditMetadataFormState>();
  return showAdaptiveFormDialog<ComicMetadataBulkPatch>(
    context,
    title: l10n.bulkEditMetadataTitle(comicIds.length),
    form: BulkEditMetadataForm(key: formKey, comicIds: comicIds),
    confirmLabel: l10n.commonSaveChanges,
    dismissLabel: l10n.commonCancel,
    onConfirm: () => formKey.currentState?.confirm(),
    basicMaxWidth: 640,
  );
}
