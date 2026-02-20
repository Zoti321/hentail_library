import 'package:flutter/material.dart';
import 'package:hentai_library/core/errors/app_exception.dart';

/// 桌面端 SnackBar 最大宽度，避免占满整屏。
const double _kSnackBarMaxWidth = 380;

/// 右下角与屏幕边缘的间距。
const double _kSnackBarInset = 24;

/// 计算右下角定位的 margin（左侧留白使条贴右）。
EdgeInsets _snackBarMargin(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  return EdgeInsets.only(
    left: w > _kSnackBarMaxWidth + _kSnackBarInset * 2
        ? w - _kSnackBarMaxWidth - _kSnackBarInset
        : _kSnackBarInset,
    bottom: _kSnackBarInset,
    right: _kSnackBarInset,
  );
}

/// 显示成功类 SnackBar，使用主题色，符合项目 Fluent 风格。
/// 桌面端：宽度受限、位于右下角。
void showSuccessSnackBar(BuildContext context, String message) {
  if (!context.mounted) return;
  final theme = Theme.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: theme.colorScheme.primary,
      behavior: SnackBarBehavior.floating,
      margin: _snackBarMargin(context),
    ),
  );
}

/// 显示错误类 SnackBar。若 [error] 为 [AppException] 则使用其 [message]。
/// 桌面端：宽度受限、位于右下角。
void showErrorSnackBar(BuildContext context, Object error) {
  if (!context.mounted) return;
  final message = error is AppException ? error.message : error.toString();
  final theme = Theme.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: theme.colorScheme.error,
      behavior: SnackBarBehavior.floating,
      margin: _snackBarMargin(context),
    ),
  );
}
