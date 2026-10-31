import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_browse/presentation/views/metadata_edit_md3e/comic_metadata_edit_md3e_page.dart';
import 'package:hentai_library/features/library_browse/presentation/views/metadata_edit_md3e/series_metadata_edit_md3e_page.dart';
import 'package:hentai_library/md3e/patterns/dialog/md3e_lab_dialog_presenter.dart';
import 'package:hentai_library/md3e/patterns/metadata_edit/md3e_metadata_edit_surface.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/series.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 打开漫画元数据编辑：compact / medium 全屏，expanded+ 为 M3E 浮层（与 Lab 一致）。
Future<void> showComicMetadataEditMd3e({
  required BuildContext context,
  required Comic comic,
}) {
  final GlobalKey<ComicMetadataEditMd3eViewState> formKey = GlobalKey();
  final AppLocalizations l10n = context.l10n;

  if (Md3eLabDialogPresenter.usesFullScreenPresentation(context)) {
    return Md3eLabDialogPresenter.showFullScreen<void>(
      context,
      title: l10n.dialogEditMetadataTitle,
      body: ComicMetadataEditMd3eView(
        key: formKey,
        comic: comic,
        presentation: Md3eMetadataEditPresentation.labFormBody,
      ),
      confirmLabel: l10n.commonSave,
      onConfirm: () => formKey.currentState?.save(),
      bottomActions: <Widget>[
        M3EButton(
          onPressed: () => Navigator.of(context).pop(),
          style: M3EButtonStyle.text,
          label: Text(l10n.commonCancel),
        ),
      ],
    );
  }

  return Md3eLabDialogPresenter.showBasic<void>(
    context,
    dialog: ComicMetadataEditMd3eView(comic: comic),
  );
}

/// 打开系列元数据编辑：compact / medium 全屏，expanded+ 为 M3E 浮层（与 Lab 一致）。
Future<void> showSeriesMetadataEditMd3e({
  required BuildContext context,
  required Series series,
}) {
  final GlobalKey<SeriesMetadataEditMd3eViewState> formKey = GlobalKey();
  final AppLocalizations l10n = context.l10n;

  if (Md3eLabDialogPresenter.usesFullScreenPresentation(context)) {
    return Md3eLabDialogPresenter.showFullScreen<void>(
      context,
      title: l10n.dialogEditSeriesTitle,
      body: SeriesMetadataEditMd3eView(
        key: formKey,
        series: series,
        presentation: Md3eMetadataEditPresentation.labFormBody,
      ),
      confirmLabel: l10n.commonSave,
      onConfirm: () => formKey.currentState?.save(),
      bottomActions: <Widget>[
        M3EButton(
          onPressed: () => Navigator.of(context).pop(),
          style: M3EButtonStyle.text,
          label: Text(l10n.commonCancel),
        ),
      ],
    );
  }

  return Md3eLabDialogPresenter.showBasic<void>(
    context,
    dialog: SeriesMetadataEditMd3eView(series: series),
  );
}
