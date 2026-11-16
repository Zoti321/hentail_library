import 'package:flutter/material.dart';
import 'package:material_3_expressive/foundations/foundations.dart';

/// 壳层统一画布色：自定义标题栏背景、内容区背景、各页 header 与 body 均使用此色。
///
/// 使用 [M3EColorScheme.surface]（与设置页 FadeThrough/SharedAxis 垫色一致），
/// 避免透明页透出与过渡 `fillColor` 两套底色。
Color labBrowseCanvasColor(M3EColorScheme scheme) => scheme.surface;

/// Region fills for [DesktopShell] (decoupled from MASTER product mapping).
///
/// **Tone-based preview (A)** follows the Material 3 tone-based surface pairing
/// (research notes archived in git history before 2026-11-01):
/// **content / header / body / title bar → [labBrowseCanvasColor]
/// (`surface`)**, **navigation → [M3EColorScheme.surfaceContainerHigh]**
/// (same mapping across breakpoints).
///
/// **Lab** keeps chrome on `surfaceContainerLow`, content on [labBrowseCanvasColor].
@immutable
class DesktopShellSurfaceRoles {
  const DesktopShellSurfaceRoles({
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
  factory DesktopShellSurfaceRoles.lab(M3EColorScheme scheme) {
    final Color rail = scheme.surfaceContainerLow;
    final Color content = labBrowseCanvasColor(scheme);
    return DesktopShellSurfaceRoles(
      shellBackground: rail,
      titleBarBackground: content,
      navigationRailBackground: rail,
      librarySecondaryPanelBackground: rail,
      contentPaneBackground: content,
    );
  }

  /// Tone-based: canvas (content, title bar) = surface; navigation = surfaceContainerHigh.
  factory DesktopShellSurfaceRoles.toneBased(M3EColorScheme scheme) {
    final Color rail = scheme.surfaceContainerHigh;
    final Color content = labBrowseCanvasColor(scheme);
    return DesktopShellSurfaceRoles(
      shellBackground: rail,
      titleBarBackground: content,
      navigationRailBackground: rail,
      librarySecondaryPanelBackground: rail,
      contentPaneBackground: content,
    );
  }
}
