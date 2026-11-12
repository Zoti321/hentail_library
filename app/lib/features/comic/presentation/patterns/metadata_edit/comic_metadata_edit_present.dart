import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/comic/presentation/views/metadata_edit/comic_metadata_edit_layout.dart';
import 'package:hentai_library/shared/ui/patterns/dialog/lab_dialog_presenter.dart';
import 'package:hentai_library/shared/ui/patterns/metadata_edit/metadata_edit_actions.dart';
import 'package:hentai_library/shared/ui/patterns/metadata_edit/metadata_edit_surface.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 打开漫画元数据编辑：compact / medium M3E 全屏；expanded+ M3EDialog basic。
Future<ComicMetadataEditDraft?> showComicMetadataEditLayout({
  required BuildContext context,
  required ComicMetadataEditDraft initialDraft,
}) {
  final GlobalKey pageKey = GlobalKey();
  final AppLocalizations l10n = context.l10n;

  if (LabDialogPresenter.usesFullScreenPresentation(context)) {
    return LabDialogPresenter.showFullScreen<ComicMetadataEditDraft>(
      context,
      title: l10n.dialogEditMetadataTitle,
      body: ComicMetadataEditLayout(
        key: pageKey,
        initialDraft: initialDraft,
        presentation: MetadataEditPresentation.labFormBody,
      ),
      confirmLabel: l10n.commonSave,
      onConfirm: () {
        final MetadataEditSaveActions? state =
            pageKey.currentState as MetadataEditSaveActions?;
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

  return LabDialogPresenter.showBasic<ComicMetadataEditDraft>(
    context,
    dialog: ComicMetadataEditLayout(
      initialDraft: initialDraft,
      presentation: MetadataEditPresentation.modal,
      onCancel: () => Navigator.of(context).pop(),
      onSaved: (ComicMetadataEditDraft draft) {
        Navigator.of(context).pop(draft);
      },
    ),
  );
}
