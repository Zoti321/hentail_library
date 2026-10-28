import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/pages/md3e_comic_metadata_edit_page.dart';
import 'package:hentai_library/md3e/patterns/dialog/md3e_lab_dialog_presenter.dart';
import 'package:hentai_library/md3e/patterns/metadata_edit/md3e_metadata_edit_surface.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 打开漫画元数据编辑：compact / medium M3E 全屏；expanded+ M3EDialog basic。
Future<Md3eComicMetadataEditDraft?> showMd3eComicMetadataEdit({
  required BuildContext context,
  Md3eComicMetadataEditDraft? initialDraft,
}) {
  final GlobalKey pageKey = GlobalKey();
  final AppLocalizations l10n = context.l10n;

  if (Md3eLabDialogPresenter.usesFullScreenPresentation(context)) {
    return Md3eLabDialogPresenter.showFullScreen<Md3eComicMetadataEditDraft>(
      context,
      title: l10n.dialogEditMetadataTitle,
      body: Md3eComicMetadataEditPage(
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

  return Md3eLabDialogPresenter.showBasic<Md3eComicMetadataEditDraft>(
    context,
    dialog: Md3eComicMetadataEditPage(
      initialDraft: initialDraft,
      presentation: Md3eMetadataEditPresentation.modal,
      onCancel: () => Navigator.of(context).pop(),
      onSaved: (Md3eComicMetadataEditDraft draft) {
        Navigator.of(context).pop(draft);
      },
    ),
  );
}
