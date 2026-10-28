import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/pages/md3e_series_metadata_edit_page.dart';
import 'package:hentai_library/md3e/patterns/dialog/md3e_lab_dialog_presenter.dart';
import 'package:hentai_library/md3e/patterns/metadata_edit/md3e_metadata_edit_surface.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 打开系列元数据编辑。
Future<Md3eSeriesMetadataEditDraft?> showMd3eSeriesMetadataEdit({
  required BuildContext context,
  Md3eSeriesMetadataEditDraft? initialDraft,
}) {
  final GlobalKey pageKey = GlobalKey();
  final AppLocalizations l10n = context.l10n;

  if (Md3eLabDialogPresenter.usesFullScreenPresentation(context)) {
    return Md3eLabDialogPresenter.showFullScreen<Md3eSeriesMetadataEditDraft>(
      context,
      title: l10n.dialogEditSeriesTitle,
      body: Md3eSeriesMetadataEditPage(
        key: pageKey,
        initialDraft: initialDraft,
        presentation: Md3eMetadataEditPresentation.labFormBody,
      ),
      confirmLabel: l10n.commonSave,
      onConfirm: () {
        final dynamic state = pageKey.currentState;
        if (state != null) {
          state.saveAndPop();
        }
      },
      bottomActions: <Widget>[
        M3EButton(
          onPressed: () => Navigator.of(context).pop(),
          style: M3EButtonStyle.text,
          label: Text(l10n.commonCancel),
        ),
      ],
    );
  }

  return Md3eLabDialogPresenter.showBasic<Md3eSeriesMetadataEditDraft>(
    context,
    dialog: Md3eSeriesMetadataEditPage(
      initialDraft: initialDraft,
      presentation: Md3eMetadataEditPresentation.modal,
      onCancel: () => Navigator.of(context).pop(),
      onSaved: (Md3eSeriesMetadataEditDraft draft) {
        Navigator.of(context).pop(draft);
      },
    ),
  );
}
