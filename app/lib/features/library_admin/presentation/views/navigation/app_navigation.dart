import 'package:hentai_library/shared/di/library_management_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/constants/app_routes.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/shared/ui/navigation/app_navigator_context.dart';
import 'package:hentai_library/shared/ui/shell/shell_nav_item.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

abstract final class AppNavigation {
  static const String navIdHome = 'home';
  static const String navIdLibrary = 'library';
  static const String navIdMetadata = 'metadata';
  static const String navIdHistory = 'history';
  static const String navIdTrash = 'trash';
  static const String navIdSettings = 'settings';

  /// Flat main items (Libraries section is rendered separately after Home).
  static List<ShellNavItem> desktopMainNavItems(AppLocalizations l10n) =>
      <ShellNavItem>[
        (id: navIdHome, label: l10n.navHome, icon: LucideIcons.house),
      ];

  static List<ShellNavItem> desktopSystemNavItems(
    AppLocalizations l10n,
  ) => <ShellNavItem>[
    (id: navIdSettings, label: l10n.navSettings, icon: LucideIcons.settings),
  ];

  /// 与 MD3E rail 导航 id 对应；库 flyout 选库不经此函数。
  static String activeNavIdForPath(String path) {
    if (AppRoutes.libraryIdFromPath(path) != null) {
      return '';
    }
    switch (path) {
      case AppRoutes.home:
        return navIdHome;
      case AppRoutes.local:
        return '';
      case AppRoutes.metadata:
      case '/tags':
      case '/authors':
      case '/parodies':
      case '/characters':
        return navIdMetadata;
      case '/series':
        return '';
      case AppRoutes.history:
        return navIdHistory;
      case AppRoutes.trash:
        return navIdTrash;
      case AppRoutes.settings:
        return navIdSettings;
      default:
        if (AppRoutes.isCatalogDetailPath(path)) {
          return '';
        }
        return navIdHome;
    }
  }

  static void goToNavId(BuildContext context, String id, {WidgetRef? ref}) {
    _clearComicDetailReturnSeries(context);
    final navigator = appNavigatorOf(context);
    switch (id) {
      case navIdHome:
        navigator.goHome();
        break;
      case navIdLibrary:
        if (ref != null) {
          ref
              .read(libraryManagementPortProvider)
              .goDefaultLibraryBrowse(context);
        } else {
          navigator.goHome();
        }
        break;
      case navIdMetadata:
        navigator.goMetadata();
        break;
      case navIdHistory:
        navigator.goHistory();
        break;
      case navIdTrash:
        navigator.goTrash();
        break;
      case navIdSettings:
        navigator.goSettings();
        break;
      default:
        break;
    }
  }
}

void _clearComicDetailReturnSeries(BuildContext context) {
  try {
    ProviderScope.containerOf(context)
        .read(comicDetailReturnSeriesPortProvider)
        .clear();
  } catch (_) {}
}
