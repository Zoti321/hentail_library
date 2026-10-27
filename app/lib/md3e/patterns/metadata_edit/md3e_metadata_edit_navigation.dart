import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/pages/md3e_comic_metadata_edit_page.dart';
import 'package:hentai_library/md3e/pages/md3e_series_metadata_edit_page.dart';
import 'package:hentai_library/md3e/patterns/metadata_edit/md3e_metadata_edit_surface.dart';

/// 打开漫画元数据编辑：compact 全页路由，较宽视口 Modal Dialog。
Future<Md3eComicMetadataEditDraft?> showMd3eComicMetadataEdit({
  required BuildContext context,
  Md3eComicMetadataEditDraft? initialDraft,
}) {
  final bool compact = md3eWindowSizeClassOf(context).isCompact;
  if (compact) {
    return Navigator.of(context).push<Md3eComicMetadataEditDraft>(
      MaterialPageRoute<Md3eComicMetadataEditDraft>(
        builder: (BuildContext context) => Md3eComicMetadataEditPage(
          initialDraft: initialDraft,
        ),
      ),
    );
  }
  return showDialog<Md3eComicMetadataEditDraft>(
    context: context,
    useRootNavigator: false,
    builder: (BuildContext dialogContext) {
      return Md3eComicMetadataEditPage(
        initialDraft: initialDraft,
        presentation: Md3eMetadataEditPresentation.modal,
        onCancel: () => Navigator.of(dialogContext).pop(),
        onSaved: (Md3eComicMetadataEditDraft draft) {
          Navigator.of(dialogContext).pop(draft);
        },
      );
    },
  );
}

/// 打开系列元数据编辑。
Future<Md3eSeriesMetadataEditDraft?> showMd3eSeriesMetadataEdit({
  required BuildContext context,
  Md3eSeriesMetadataEditDraft? initialDraft,
}) {
  final bool compact = md3eWindowSizeClassOf(context).isCompact;
  if (compact) {
    return Navigator.of(context).push<Md3eSeriesMetadataEditDraft>(
      MaterialPageRoute<Md3eSeriesMetadataEditDraft>(
        builder: (BuildContext context) => Md3eSeriesMetadataEditPage(
          initialDraft: initialDraft,
        ),
      ),
    );
  }
  return showDialog<Md3eSeriesMetadataEditDraft>(
    context: context,
    useRootNavigator: false,
    builder: (BuildContext dialogContext) {
      return Md3eSeriesMetadataEditPage(
        initialDraft: initialDraft,
        presentation: Md3eMetadataEditPresentation.modal,
        onCancel: () => Navigator.of(dialogContext).pop(),
        onSaved: (Md3eSeriesMetadataEditDraft draft) {
          Navigator.of(dialogContext).pop(draft);
        },
      );
    },
  );
}
