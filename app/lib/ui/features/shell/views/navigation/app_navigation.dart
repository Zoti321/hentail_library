import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/ui/core/dto/nav_item_data.dart';
import 'package:hentai_library/ui/features/shell/views/navigation/libraries_routes.dart';
import 'package:hentai_library/ui/features/shell/views/navigation/library_management_actions.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

abstract final class AppNavigation {
  static const String navIdHome = 'home';
  static const String navIdLibrary = 'library';
  static const String navIdMetadata = 'metadata';
  static const String navIdHistory = 'history';
  static const String navIdSettings = 'settings';

  /// Flat main items (Libraries section is rendered separately after Home).
  static List<NavItemData> desktopMainNavItems(AppLocalizations l10n) =>
      <NavItemData>[
        (id: navIdHome, label: l10n.navHome, icon: LucideIcons.house),
        (id: navIdMetadata, label: l10n.navMetadata, icon: LucideIcons.layers),
        (id: navIdHistory, label: l10n.navHistory, icon: LucideIcons.history),
      ];

  static List<NavItemData> desktopSystemNavItems(
    AppLocalizations l10n,
  ) => <NavItemData>[
    (id: navIdSettings, label: l10n.navSettings, icon: LucideIcons.settings),
  ];

  /// 与 [DesktopSidebar] 扁平菜单 id 对应；Libraries 分区用
  /// [librariesSidebarSelection]，不经此函数。
  static String activeNavIdForPath(String path) {
    if (LibrariesRoutes.isAllLibrariesPath(path) ||
        LibrariesRoutes.libraryIdFromPath(path) != null) {
      return '';
    }
    switch (path) {
      case '/home':
        return navIdHome;
      case '/local':
        return '';
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
        if (path.startsWith('/comic/') || path.startsWith('/series/')) {
          return '';
        }
        return navIdHome;
    }
  }

  static void goToNavId(BuildContext context, String id, {WidgetRef? ref}) {
    switch (id) {
      case navIdHome:
        context.go('/home');
        break;
      case navIdLibrary:
        if (ref != null) {
          LibraryManagementActions.goCurrentLibraryBrowse(ref, context);
        } else {
          context.go(LibrariesRoutes.all);
        }
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
