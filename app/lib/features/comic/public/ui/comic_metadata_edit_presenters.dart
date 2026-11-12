import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/comic/di/comic_detail_providers.dart';
import 'package:hentai_library/features/comic/presentation/views/metadata_edit/comic_metadata_edit_page.dart';
import 'package:hentai_library/features/comic/domain/comic.dart';
import 'package:hentai_library/design-system/layout/metadata_edit_form_metrics.dart';
import 'package:hentai_library/shared/ui/patterns/dialog/adaptive_form_dialog.dart';
import 'package:hentai_library/shared/ui/patterns/metadata_edit/metadata_edit_surface.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/app_snackbar.dart';

/// 打开漫画元数据编辑：[M3EDialog.showAdaptive]（宽 < 840 全屏，否则基础弹窗）。
Future<void> showComicMetadataEdit({
  required BuildContext context,
  required Comic comic,
}) {
  final GlobalKey<ComicMetadataEditViewState> formKey = GlobalKey();
  final AppLocalizations l10n = context.l10n;

  return showAdaptiveFormDialog<void>(
    context,
    title: l10n.dialogEditMetadataTitle,
    form: ComicMetadataEditFormLayout(
      key: formKey,
      comic: comic,
      presentation: MetadataEditPresentation.labFormBody,
    ),
    confirmLabel: l10n.commonSave,
    dismissLabel: l10n.commonCancel,
    onConfirm: () => formKey.currentState?.save(),
    basicMaxWidth: MetadataEditFormMetrics.comicMaxWidth,
  );
}

/// 库页 Browse VO 路径：按需 [findById] 再打开编辑对话框。
Future<void> showComicMetadataEditById({
  required BuildContext context,
  required WidgetRef ref,
  required String comicId,
}) async {
  final Comic? comic = await ref.read(comicDetailProvider(comicId).future);
  if (!context.mounted) {
    return;
  }
  if (comic == null) {
    showErrorSnackbar(context, context.l10n.shellLoadFailed);
    return;
  }
  await showComicMetadataEdit(context: context, comic: comic);
}
