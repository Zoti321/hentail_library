import 'package:flutter/material.dart';
import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

const Duration kAppSnackbarDefaultDuration = Duration(seconds: 3);

/// 统一经 [M3ESnackbar] 呈现的轻量反馈（生产路由均使用此入口，勿再使用 overlay Toast）。
void showAppSnackbar(
  BuildContext context, {
  required String message,
  Duration duration = kAppSnackbarDefaultDuration,
}) {
  if (!context.mounted) {
    return;
  }
  M3ESnackbar.show(context, message: message, duration: duration);
}

void showSuccessSnackbar(BuildContext context, String message) {
  showAppSnackbar(context, message: message);
}

void showErrorSnackbar(BuildContext context, Object error) {
  final String message = error is AppException
      ? error.message
      : error.toString();
  showAppSnackbar(context, message: message);
}

void showInfoSnackbar(BuildContext context, String message) {
  showAppSnackbar(context, message: message);
}
