import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/patterns/dialog/confirm_dialog.dart';

/// Library 相关的 MD3E 确认对话框（委托共享 [showConfirmDialog]）。
Future<bool> showLibraryConfirmDialog(
  BuildContext context, {
  required String title,
  required Widget content,
  required String confirmLabel,
  bool destructive = false,
}) {
  return showConfirmDialog(
    context,
    title: title,
    content: content,
    confirmLabel: confirmLabel,
    destructive: destructive,
  );
}
