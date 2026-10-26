import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/widgets/md3e_desktop_title_bar.dart';
import 'package:hentai_library/md3e/widgets/md3e_desktop_title_bar_metrics.dart';
import 'package:hentai_library/md3e/widgets/md3e_navigation_rail.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Shell layout metrics (MASTER §5.1 pane seam).
abstract final class Md3eDesktopShellMetrics {
  static const double paneCornerRadius = 20;
}

/// Desktop window shell: full-height [Md3eNavigationRail] + title row + main pane.
///
/// The rail menu sits in the top [Md3eDesktopTitleBarMetrics.height] band beside
/// the search field; pane content starts below the title bar with search and pane
/// sharing the same leading edge.
class Md3eDesktopShell extends StatefulWidget {
  const Md3eDesktopShell({
    super.key,
    this.width,
    this.height = 768,
    this.initialRailExtended = false,
    this.destinations,
    this.paneChild,
  });

  final double? width;
  final double height;
  final bool initialRailExtended;
  final List<Md3eNavigationRailDestination>? destinations;
  final Widget? paneChild;

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
    final double paneGutter = m3e.spacing.lg;
    final List<Md3eNavigationRailDestination> destinations =
        widget.destinations ?? md3eDefaultNavigationRailDestinations();

    final Widget shell = ColoredBox(
      color: scheme.surfaceContainerLow,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            height: widget.height,
            child: Md3eNavigationRail(
              destinations: destinations,
              selectedIndex: _selectedIndex,
              extended: _railExtended,
              onMenuPressed: () => setState(() => _railExtended = !_railExtended),
              onDestinationSelected: (int index) =>
                  setState(() => _selectedIndex = index),
            ),
          ),
          SizedBox(width: paneGutter),
          Expanded(
            child: SizedBox(
              height: widget.height,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Md3eDesktopTitleBar(
                    searchLeadingInset: 0,
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: paneGutter,
                        bottom: paneGutter,
                      ),
                      child: Md3eDesktopShellPane(
                        child: widget.paneChild,
                      ),
                    ),
                  ),
                ],
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

/// Main pane surface (`surfaceContainerLowest`, r=20) for shell previews.
class Md3eDesktopShellPane extends StatelessWidget {
  const Md3eDesktopShellPane({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(
          Md3eDesktopShellMetrics.paneCornerRadius,
        ),
      ),
      child: child ?? const SizedBox.expand(),
    );
  }
}
