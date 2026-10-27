import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/patterns/desktop/md3e_desktop_shell_surfaces.dart';
import 'package:hentai_library/md3e/widgets/desktop/md3e_desktop_title_bar.dart';
import 'package:hentai_library/md3e/widgets/desktop/md3e_desktop_title_bar_metrics.dart';
import 'package:hentai_library/md3e/widgets/desktop/md3e_navigation_rail.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Shell layout metrics for the desktop content card.
abstract final class Md3eDesktopShellMetrics {
  static const double paneCornerRadius = 20;

  /// Content card: rounded on the leading edge only (rail side).
  static BorderRadius contentCardLeadingRadius([double radius = paneCornerRadius]) {
    return BorderRadius.only(
      topLeft: Radius.circular(radius),
      bottomLeft: Radius.circular(radius),
    );
  }

  /// Horizontal inset for title-bar search beside the leading curve.
  static const double titleBarContentPadding = 24;
}

/// Desktop window shell: animated [Md3eNavigationRail] + clipped content card.
///
/// Window fill uses [Md3eDesktopShellSurfaceRoles.shellBackground] (same as rail).
/// The content column is [ClipRRect]-rounded in a [Row] so rail width animation
/// is not covered by a overlapping [Stack] layer.
class Md3eDesktopShell extends StatefulWidget {
  const Md3eDesktopShell({
    super.key,
    this.width,
    this.height = 768,
    this.initialRailExtended = false,
    this.destinations,
    this.paneChild,
    this.surfaceRoles,
  });

  final double? width;
  final double height;
  final bool initialRailExtended;
  final List<Md3eNavigationRailDestination>? destinations;
  final Widget? paneChild;

  /// When null, uses [Md3eDesktopShellSurfaceRoles.lab] (MASTER-aligned lab default).
  final Md3eDesktopShellSurfaceRoles? surfaceRoles;

  @override
  State<Md3eDesktopShell> createState() => _Md3eDesktopShellState();
}

class _Md3eDesktopShellState extends State<Md3eDesktopShell> {
  late bool _railExtended = widget.initialRailExtended;
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData m3e = M3ETheme.of(context);
    final M3EColorScheme scheme = m3e.colorScheme;
    final Md3eDesktopShellSurfaceRoles surfaces =
        widget.surfaceRoles ?? Md3eDesktopShellSurfaceRoles.lab(scheme);
    final List<Md3eNavigationRailDestination> destinations =
        widget.destinations ??
        md3eDefaultNavigationRailDestinations(context.l10n);

    final M3EThemeData railTheme = m3e.copyWith(
      navigationRailTheme: m3e.navigationRailTheme.copyWith(
        containerColor: surfaces.navigationRailBackground,
      ),
    );

    final double cornerRadius = Md3eDesktopShellMetrics.paneCornerRadius;

    final Widget shell = ColoredBox(
      color: surfaces.shellBackground,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            height: widget.height,
            child: M3ETheme(
              data: railTheme,
              child: Md3eNavigationRail(
                destinations: destinations,
                selectedIndex: _selectedIndex,
                extended: _railExtended,
                onMenuPressed: () =>
                    setState(() => _railExtended = !_railExtended),
                onDestinationSelected: (int index) =>
                    setState(() => _selectedIndex = index),
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: Md3eDesktopShellMetrics.contentCardLeadingRadius(
                cornerRadius,
              ),
              child: ColoredBox(
                color: surfaces.contentPaneBackground,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Md3eDesktopTitleBar(
                      searchLeadingInset:
                          Md3eDesktopShellMetrics.titleBarContentPadding,
                      backgroundColor: Colors.transparent,
                    ),
                    Expanded(
                      child: Md3eDesktopShellPane(
                        showDecoration: false,
                        child: widget.paneChild,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.width != null) {
      return SizedBox(width: widget.width, height: widget.height, child: shell);
    }
    return SizedBox(height: widget.height, child: shell);
  }
}

/// Main pane surface (role from [Md3eDesktopShellSurfaceRoles], r=20).
class Md3eDesktopShellPane extends StatelessWidget {
  const Md3eDesktopShellPane({
    super.key,
    this.backgroundColor,
    this.borderRadius,
    this.showDecoration = true,
    this.child,
  });

  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  /// When false, only lays out [child] (fill provided by parent shell card).
  final bool showDecoration;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final Widget content = child ?? const SizedBox.expand();
    if (!showDecoration) {
      return content;
    }

    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final Color fill =
        backgroundColor ?? scheme.surfaceContainerLowest;
    final BorderRadius radius = borderRadius ??
        BorderRadius.circular(Md3eDesktopShellMetrics.paneCornerRadius);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: radius,
      ),
      child: content,
    );
  }
}
