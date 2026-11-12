import 'package:flutter/widgets.dart';
import 'package:hentai_library/shared/application/errors/app_exception.dart';
import 'package:hentai_library/design-system/design_system.dart';

void showErrorSnackbar(BuildContext context, Object error) {
  final String message = error is AppException
      ? error.message
      : error.toString();
  showAppSnackbar(context, message: message);
}
