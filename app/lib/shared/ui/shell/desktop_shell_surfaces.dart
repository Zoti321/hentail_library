import 'package:flutter/material.dart';
import 'package:material_3_expressive/foundations/foundations.dart';

/// 壳层统一画布色：自定义标题栏背景、内容区背景、各页 header 与 body 均使用此色。
Color md3eLabBrowseCanvasColor(M3EColorScheme scheme) =>
    scheme.surfaceContainerLow;

/// Region fills for [Md3eDesktopShell] (decoupled from MASTER product mapping).
///
/// **Tone-based preview (A)** follows the roles-page pairing cited in
/// `design-system/research/material-design-3/08-tone-based-surfaces.md` §1.1:
/// **background → [M3EColorScheme.surface]**, **navigation →
/// [M3EColorScheme.surfaceContainer]** (same mapping across breakpoints).
///
/// **Lab** keeps the MASTER-aligned product preview (chrome
/// `surfaceContainerLow`, pane `surfaceContainerLowest`).
@immutable
class Md3eDesktopShellSurfaceRoles {
  const Md3eDesktopShellSurfaceRoles({
    required this.shellBackground,
    required this.titleBarBackground,
    required this.navigationRailBackground,
    required this.librarySecondaryPanelBackground,
    required this.contentPaneBackground,
  });

  final Color shellBackground;
  final Color titleBarBackground;
  final Color navigationRailBackground;
  final Color librarySecondaryPanelBackground;
  final Color contentPaneBackground;

  /// Lab preview: window chrome = rail; content card clipped on the leading edge.
  factory Md3eDesktopShellSurfaceRoles.lab(M3EColorScheme scheme) {
    final Color rail = scheme.surfaceContainerLow;
    final Color content = md3eLabBrowseCanvasColor(scheme);
    return Md3eDesktopShellSurfaceRoles(
      shellBackground: rail,
      titleBarBackground: content,
      navigationRailBackground: rail,
      librarySecondaryPanelBackground: rail,
      contentPaneBackground: content,
    );
  }

  /// M3 roles-page default: surface (background) + surfaceContainer (navigation).
  factory Md3eDesktopShellSurfaceRoles.toneBased(M3EColorScheme scheme) {
    final Color rail = scheme.surfaceContainer;
    final Color content = md3eLabBrowseCanvasColor(scheme);
    return Md3eDesktopShellSurfaceRoles(
      shellBackground: rail,
      titleBarBackground: content,
      navigationRailBackground: rail,
      librarySecondaryPanelBackground: rail,
      contentPaneBackground: content,
    );
  }
}
