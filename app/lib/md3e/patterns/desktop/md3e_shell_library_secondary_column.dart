import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/motion/md3e_motion.dart';
import 'package:hentai_library/md3e/patterns/desktop/md3e_shell_library_secondary_layout.dart';
import 'package:hentai_library/md3e/patterns/desktop/md3e_shell_library_secondary_panel.dart';
import 'package:hentai_library/md3e/patterns/desktop/md3e_shell_nav_divider.dart';
import 'package:hentai_library/md3e/patterns/desktop/md3e_shell_navigation.dart';
import 'package:motor/motor.dart';

/// Floating library secondary pane (M3E drawer-style spatial reveal).
abstract final class Md3eShellLibrarySecondaryPanelMetrics {
  static const double cornerRadius = 16;

  /// Elevation for overlay flyout (M3 nav secondary pane).
  static const double elevation = 3;
}

/// Library secondary flyout beside the navigation rail.
class Md3eShellLibrarySecondaryColumn extends StatefulWidget {
  const Md3eShellLibrarySecondaryColumn({
    super.key,
    required this.open,
    required this.height,
    required this.backgroundColor,
    required this.libraryDisplayNames,
    required this.selectedDisplayName,
    required this.onLibrarySelected,
    this.dividerColor,
    this.onPointerEnter,
    this.onPointerExit,
  });

  final bool open;
  final double height;
  final Color backgroundColor;
  final List<String> libraryDisplayNames;
  final String selectedDisplayName;
  final ValueChanged<String> onLibrarySelected;
  final Color? dividerColor;
  final VoidCallback? onPointerEnter;
  final VoidCallback? onPointerExit;

  @override
  State<Md3eShellLibrarySecondaryColumn> createState() =>
      _Md3eShellLibrarySecondaryColumnState();
}

class _Md3eShellLibrarySecondaryColumnState
    extends State<Md3eShellLibrarySecondaryColumn>
    with SingleTickerProviderStateMixin {
  late final SingleMotionController _reveal = SingleMotionController(
    motion: Md3eMotion.shellLibrarySecondaryReveal,
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    _reveal.value = widget.open ? 1.0 : 0.0;
  }

  @override
  void didUpdateWidget(covariant Md3eShellLibrarySecondaryColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.open == widget.open) {
      return;
    }
    if (Md3eMotion.reduceMotionOf(context)) {
      _reveal.value = widget.open ? 1.0 : 0.0;
      return;
    }
    _reveal.motion = Md3eMotion.shellLibrarySecondaryReveal;
    _reveal.animateTo(widget.open ? 1.0 : 0.0);
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _reveal,
      builder: (BuildContext context, Widget? child) {
        final double reveal = _reveal.value.clamp(0.0, 1.0);
        if (reveal <= 0.001) {
          return SizedBox(height: widget.height);
        }

        const double panelWidth =
            Md3eShellNavigation.librarySecondaryPanelWidth;

        final BorderRadius flyoutRadius = BorderRadiusDirectional.only(
          topEnd: Radius.circular(
            Md3eShellLibrarySecondaryPanelMetrics.cornerRadius,
          ),
          bottomEnd: Radius.circular(
            Md3eShellLibrarySecondaryPanelMetrics.cornerRadius,
          ),
        ).resolve(Directionality.of(context));

        final Widget panelChrome = Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Md3eShellNavVerticalDivider(
              color: widget.dividerColor,
              height: widget.height,
            ),
            Expanded(
              child: Md3eShellLibrarySecondaryPanel(
                libraryDisplayNames: widget.libraryDisplayNames,
                selectedDisplayName: widget.selectedDisplayName,
                onLibrarySelected: widget.onLibrarySelected,
                backgroundColor: widget.backgroundColor,
              ),
            ),
          ],
        );

        final Widget flyout = Material(
          elevation: Md3eShellLibrarySecondaryPanelMetrics.elevation,
          color: widget.backgroundColor,
          shadowColor: Colors.black26,
          borderRadius: flyoutRadius,
          clipBehavior: Clip.antiAlias,
          child: panelChrome,
        );

        final Widget interactivePane = MouseRegion(
          cursor: Md3eShellNavigationCursor.interactive,
          onEnter: (_) => widget.onPointerEnter?.call(),
          onExit: (_) => widget.onPointerExit?.call(),
          child: flyout,
        );

        return ClipRect(
          child: SizedBox(
            width: panelWidth * reveal,
            height: widget.height,
            child: OverflowBox(
              alignment: AlignmentDirectional.centerStart,
              minWidth: panelWidth,
              maxWidth: panelWidth,
              minHeight: widget.height,
              maxHeight: widget.height,
              child: interactivePane,
            ),
          ),
        );
      },
    );
  }
}
