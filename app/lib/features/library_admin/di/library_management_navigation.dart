import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/constants/libraries_routes.dart';
import 'package:hentai_library/shared/di/library_management_providers.dart';

/// 仅持有 [BuildContext]（无 WidgetRef）的调用点：回到当前库浏览页。
void goCurrentLibraryBrowseFromContext(BuildContext context) {
  try {
    ProviderScope.containerOf(context)
        .read(libraryManagementPortProvider)
        .goCurrentLibraryBrowse(context);
  } catch (_) {
    context.go(LibrariesRoutes.all);
  }
}
