import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/comic/presentation/views/bulk_edit_md3e/bulk_edit_metadata_md3e_form.dart';
import 'package:hentai_library/shared/ui/patterns/dialog/md3e_adaptive_form_dialog.dart';
import 'package:hentai_library/features/library_admin/public.dart';

/// 批量编辑入口（MD3E 面板）：返回用户确认后的 patch，取消则为 `null`。
Future<ComicMetadataBulkPatch?> showBulkEditMetadataMd3e({
  required BuildContext context,
  required List<String> comicIds,
}) {
  final AppLocalizations l10n = context.l10n;
  final GlobalKey<BulkEditMetadataMd3eFormState> formKey =
      GlobalKey<BulkEditMetadataMd3eFormState>();
  return showMd3eAdaptiveFormDialog<ComicMetadataBulkPatch>(
    context,
    title: l10n.bulkEditMetadataTitle(comicIds.length),
    form: BulkEditMetadataMd3eForm(key: formKey, comicIds: comicIds),
    confirmLabel: l10n.commonSaveChanges,
    dismissLabel: l10n.commonCancel,
    onConfirm: () => formKey.currentState?.confirm(),
    basicMaxWidth: 640,
  );
}
