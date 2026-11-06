import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/shared/di/library_management_providers.dart';

/// 仅持有 [BuildContext]（无 WidgetRef）的调用点：无具体库上下文时回 Home。
void goDefaultLibraryBrowseFromContext(BuildContext context) {
  try {
    ProviderScope.containerOf(context)
        .read(libraryManagementPortProvider)
        .goDefaultLibraryBrowse(context);
  } catch (_) {
    context.go('/home');
  }
}
