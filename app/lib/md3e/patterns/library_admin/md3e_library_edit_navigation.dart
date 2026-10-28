import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/pages/md3e_library_edit_page.dart';
import 'package:hentai_library/md3e/patterns/metadata_edit/md3e_metadata_edit_surface.dart';
import 'package:hentai_library/shared/domain/models/value_objects/form/library_form.dart';

/// 打开 Library 创建/编辑：compact / medium 全屏路由，expanded+ Modal Dialog 浮层。
Future<LibraryForm?> showMd3eLibraryEdit({
  required BuildContext context,
  required Md3eLibraryEditPageIntent intent,
  LibraryForm? initialForm,
}) {
  final Md3eWindowSizeClass sizeClass = md3eWindowSizeClassOf(context);
  if (sizeClass.usesMetadataEditFullScreenRoute) {
    return Navigator.of(context).push<LibraryForm>(
      MaterialPageRoute<LibraryForm>(
        fullscreenDialog: true,
        builder: (BuildContext routeContext) => Md3eLibraryEditPage(
          intent: intent,
          initialForm: initialForm,
        ),
      ),
    );
  }

  return showDialog<LibraryForm>(
    context: context,
    useRootNavigator: false,
    builder: (BuildContext dialogContext) {
      return Md3eLibraryEditPage(
        intent: intent,
        initialForm: initialForm,
        presentation: Md3eMetadataEditPresentation.modal,
        onCancel: () => Navigator.of(dialogContext).pop(),
        onSaved: (LibraryForm form) {
          Navigator.of(dialogContext).pop(form.normalized);
        },
      );
    },
  );
}
