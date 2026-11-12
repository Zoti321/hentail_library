import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/di/app_shell_providers.dart';

/// medium- 已改用壳层底部导航，页头不再展示打开抽屉的汉堡包菜单。
bool appShellShowsPageNavigationMenu(BuildContext context) {
  return false;
}

VoidCallback? appShellPageNavigationOpener(BuildContext context) {
  if (!appShellShowsPageNavigationMenu(context)) {
    return null;
  }
  try {
    return ProviderScope.containerOf(context)
        .read(appShellOpenNavigationDrawerProvider);
  } catch (_) {
    return null;
  }
}
