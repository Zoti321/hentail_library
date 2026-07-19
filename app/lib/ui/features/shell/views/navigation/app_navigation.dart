import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/ui/core/dto/nav_item_data.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

abstract final class AppNavigation {
  static const String navIdHome = 'home';
  static const String navIdLibrary = 'library';
  static const String navIdMetadata = 'metadata';
  static const String navIdHistory = 'history';
  static const String navIdSettings = 'settings';

  static List<NavItemData> desktopMainNavItems(AppLocalizations l10n) =>
      <NavItemData>[
        (id: navIdHome, label: l10n.navHome, icon: LucideIcons.house),
        (
          id: navIdLibrary,
          label: l10n.libraryTitle,
          icon: LucideIcons.library,
        ),
        (id: navIdMetadata, label: l10n.navMetadata, icon: LucideIcons.layers),
        (id: navIdHistory, label: l10n.navHistory, icon: LucideIcons.history),
      ];

  static List<NavItemData> desktopSystemNavItems(AppLocalizations l10n) =>
      <NavItemData>[
        (
          id: navIdSettings,
          label: l10n.navSettings,
          icon: LucideIcons.settings,
        ),
      ];

  /// 与 [DesktopSidebar] 菜单 id 对应；`/paths` 无对应项时用空字符串（不高亮）。
  static String activeNavIdForPath(String path) {
    switch (path) {
      case '/home':
        return navIdHome;
      case '/local':
        return navIdLibrary;
      case '/paths':
        return '';
      case '/searched':
        return '';
      case '/metadata':
      case '/tags':
      case '/authors':
        return navIdMetadata;
      case '/series':
        return '';
      case '/history':
        return navIdHistory;
      case '/settings':
        return navIdSettings;
      default:
        if (path.startsWith('/comic/')) {
          return navIdLibrary;
        }
        if (path.startsWith('/series/')) {
          return navIdLibrary;
        }
        return navIdHome;
    }
  }

  static void goToNavId(BuildContext context, String id) {
    switch (id) {
      case navIdHome:
        context.go('/home');
        break;
      case navIdLibrary:
        context.go('/local');
        break;
      case navIdMetadata:
        context.go('/metadata');
        break;
      case navIdHistory:
        context.go('/history');
        break;
      case navIdSettings:
        context.go('/settings');
        break;
      default:
        break;
    }
  }
}
