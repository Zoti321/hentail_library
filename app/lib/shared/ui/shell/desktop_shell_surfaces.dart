import 'package:flutter/material.dart';
import 'package:material_3_expressive/foundations/foundations.dart';

/// 壳层统一画布色：自定义标题栏背景、内容区背景、各页 header 与 body 均使用此色。
Color md3eLabBrowseCanvasColor(M3EColorScheme scheme) =>
    scheme.surfaceContainerLow;

/// Region fills for [Md3eDesktopShell] (decoupled from MASTER product mapping).
///
/// **Tone-based preview (A)** follows the Material 3 tone-based surface pairing
/// (research notes archived in git history before 2026-11-01):
/// **content / header / body / title bar → [md3eLabBrowseCanvasColor]
/// (`surfaceContainerLow`)**, **navigation → [M3EColorScheme.surfaceContainerHigh]**
/// (same mapping across breakpoints).
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

  /// Tone-based: canvas (content, title bar) = surfaceContainerLow; navigation = surfaceContainerHigh.
  factory Md3eDesktopShellSurfaceRoles.toneBased(M3EColorScheme scheme) {
    final Color rail = scheme.surfaceContainerHigh;
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
