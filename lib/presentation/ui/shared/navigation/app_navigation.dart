import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/presentation/dto/nav_item_data.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

abstract final class AppNavigation {
  static const String navIdHome = 'home';
  static const String navIdLibrary = 'library';
  static const String navIdManage = 'manage';
  static const String navIdMetadata = 'metadata';
  static const String navIdHistory = 'history';
  static const String navIdSettings = 'settings';
  static const String navIdMore = 'more';

  static List<NavItemData> get desktopMainNavItems => <NavItemData>[
    const (id: navIdHome, label: '首页', icon: LucideIcons.house),
    const (id: navIdLibrary, label: '漫画库', icon: LucideIcons.library),
    const (id: navIdMetadata, label: '资料', icon: LucideIcons.layers),
    const (id: navIdHistory, label: '历史', icon: LucideIcons.history),
  ];

  static List<NavItemData> get desktopSystemNavItems => <NavItemData>[
    const (id: navIdSettings, label: '设置', icon: LucideIcons.settings),
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
      case '/series':
        return navIdMetadata;
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

  /// 底栏用：标签 / 系列管理 / 选中路径 归入「更多」高亮。
  static String mobileBarNavIdForPath(String path) {
    if (path == '/local') {
      return navIdLibrary;
    }
    if (path == '/history') {
      return navIdHistory;
    }
    if (path == '/settings') {
      return navIdSettings;
    }
    if (path == '/manage' ||
        path == '/paths' ||
        path == '/metadata' ||
        path == '/tags' ||
        path == '/authors' ||
        path == '/series' ||
        path.startsWith('/series/')) {
      return navIdManage;
    }
    if (path.startsWith('/comic/')) {
      return navIdLibrary;
    }
    return navIdLibrary;
  }

  static void goToNavId(BuildContext context, String id) {
    switch (id) {
      case navIdHome:
        context.go('/home');
        break;
      case navIdLibrary:
        context.go('/local');
        break;
      case navIdManage:
        context.go('/manage');
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
      case navIdMore:
        break;
      default:
        break;
    }
  }
}
