import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/comic/public/shell/library_browse_shell_exports.dart';
import 'package:hentai_library/features/series/public/shell/library_browse_shell_exports.dart';
import 'package:hentai_library/shared/ui/layout/metadata_edit_form_metrics.dart';
import 'package:hentai_library/shared/ui/patterns/dialog/md3e_adaptive_form_dialog.dart';
import 'package:hentai_library/shared/ui/patterns/metadata_edit/metadata_edit_surface.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/series.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 打开漫画元数据编辑：[M3EDialog.showAdaptive]（宽 < 840 全屏，否则基础弹窗）。
Future<void> showComicMetadataEditMd3e({
  required BuildContext context,
  required Comic comic,
}) {
  final GlobalKey<ComicMetadataEditMd3eViewState> formKey = GlobalKey();
  final AppLocalizations l10n = context.l10n;

  return showMd3eAdaptiveFormDialog<void>(
    context,
    title: l10n.dialogEditMetadataTitle,
    form: ComicMetadataEditMd3eView(
      key: formKey,
      comic: comic,
      presentation: Md3eMetadataEditPresentation.labFormBody,
    ),
    confirmLabel: l10n.commonSave,
    dismissLabel: l10n.commonCancel,
    onConfirm: () => formKey.currentState?.save(),
    basicMaxWidth: Md3eMetadataEditFormMetrics.comicMaxWidth,
  );
}

/// 打开系列元数据编辑：[M3EDialog.showAdaptive]（宽 < 840 全屏，否则基础弹窗）。
Future<void> showSeriesMetadataEditMd3e({
  required BuildContext context,
  required Series series,
}) {
  final GlobalKey<SeriesMetadataEditMd3eViewState> formKey = GlobalKey();
  final AppLocalizations l10n = context.l10n;

  return showMd3eAdaptiveFormDialog<void>(
    context,
    title: l10n.dialogEditSeriesTitle,
    form: SeriesMetadataEditMd3eView(
      key: formKey,
      series: series,
      presentation: Md3eMetadataEditPresentation.labFormBody,
    ),
    confirmLabel: l10n.commonSave,
    dismissLabel: l10n.commonCancel,
    onConfirm: () => formKey.currentState?.save(),
    basicMaxWidth: 560,
  );
}
