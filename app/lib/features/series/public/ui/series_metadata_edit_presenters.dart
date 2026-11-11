import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/series/presentation/views/metadata_edit/series_metadata_edit_page.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/series.dart';
import 'package:hentai_library/shared/ui/patterns/dialog/adaptive_form_dialog.dart';
import 'package:hentai_library/shared/ui/patterns/metadata_edit/metadata_edit_surface.dart';

/// 打开系列元数据编辑：[M3EDialog.showAdaptive]（宽 < 840 全屏，否则基础弹窗）。
Future<void> showSeriesMetadataEdit({
  required BuildContext context,
  required Series series,
}) {
  final GlobalKey<SeriesMetadataEditViewState> formKey = GlobalKey();
  final AppLocalizations l10n = context.l10n;

  return showAdaptiveFormDialog<void>(
    context,
    title: l10n.dialogEditSeriesTitle,
    form: SeriesMetadataEditFormLayout(
      key: formKey,
      series: series,
      presentation: MetadataEditPresentation.labFormBody,
    ),
    confirmLabel: l10n.commonSave,
    dismissLabel: l10n.commonCancel,
    onConfirm: () => formKey.currentState?.save(),
    basicMaxWidth: 560,
  );
}
