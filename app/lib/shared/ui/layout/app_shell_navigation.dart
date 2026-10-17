import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/di/app_shell_providers.dart';
import 'package:hentai_library/shared/ui/layout/app_layout_breakpoints.dart';

bool appShellShowsPageNavigationMenu(BuildContext context) {
  return AppLayoutBreakpoints.isCompact(MediaQuery.sizeOf(context).width);
}

VoidCallback? appShellPageNavigationOpener(BuildContext context) {
  if (!appShellShowsPageNavigationMenu(context)) {
    return null;
  }
  try {
    final VoidCallback openDrawer = ProviderScope.containerOf(
      context,
    ).read(appShellOpenNavigationDrawerProvider);
    return openDrawer;
  } catch (_) {
    return null;
  }
}
