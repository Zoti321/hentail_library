import 'package:flutter/material.dart';
import 'package:material_3_expressive/foundations/foundations.dart';

/// Catalog / browse 页画布色，与 [Md3eDesktopShellSurfaceRoles.lab] 主区一致。
Color md3eLabBrowseCanvasColor(M3EColorScheme scheme) =>
    scheme.surfaceContainerLowest;

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
    required this.contentPaneBackground,
  });

  final Color shellBackground;
  final Color titleBarBackground;
  final Color navigationRailBackground;
  final Color contentPaneBackground;

  /// Lab preview: window chrome = rail; content card clipped on the leading edge.
  factory Md3eDesktopShellSurfaceRoles.lab(M3EColorScheme scheme) {
    final Color rail = scheme.surfaceContainerLow;
    final Color content = md3eLabBrowseCanvasColor(scheme);
    return Md3eDesktopShellSurfaceRoles(
      shellBackground: rail,
      titleBarBackground: content,
      navigationRailBackground: rail,
      contentPaneBackground: content,
    );
  }

  /// M3 roles-page default: surface (background) + surfaceContainer (navigation).
  factory Md3eDesktopShellSurfaceRoles.toneBased(M3EColorScheme scheme) {
    final Color rail = scheme.surfaceContainer;
    final Color content = scheme.surfaceBright;
    return Md3eDesktopShellSurfaceRoles(
      shellBackground: rail,
      titleBarBackground: content,
      navigationRailBackground: rail,
      contentPaneBackground: content,
    );
  }
}
