import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/shared/ui/shell/shell_library_secondary_layout.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_library_dashboard_models.dart';
import 'package:hentai_library/shared/ui/shell/shell_library_secondary_panel.dart';
import 'package:hentai_library/shared/ui/shell/shell_nav_divider.dart';
import 'package:hentai_library/shared/ui/shell/shell_navigation.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:motor/motor.dart';

/// Floating library secondary pane (M3E drawer-style spatial reveal).
abstract final class ShellLibrarySecondaryPanelMetrics {
  static const double cornerRadius = 16;

  /// M3 resting elevation for modal navigation drawer / side sheet (level 1 = 1dp).
  /// See `M3ENavigationDrawerTheme.elevation` and m3.material.io elevation tokens.
  static const double elevation = M3EElevation.level1;

  /// Space for [M3EElevation.shadows] on the trailing edge (level 1 is ~2dp blur).
  static const double trailingShadowMargin = 4;

  /// Trailing-only separation from main content (same magnitude as level 1, no rail-side cast).
  static List<BoxShadow> trailingShadows(
    Color shadow,
    TextDirection textDirection,
  ) {
    final double dx = textDirection == TextDirection.rtl ? -1.0 : 1.0;
    return <BoxShadow>[
      BoxShadow(
        color: shadow.withValues(alpha: 0.12),
        offset: Offset(dx, 0),
        blurRadius: 2,
      ),
      BoxShadow(
        color: shadow.withValues(alpha: 0.06),
        offset: Offset(dx * 2, 1),
        blurRadius: 3,
        spreadRadius: -1,
      ),
    ];
  }
}

/// Library secondary flyout beside the navigation rail.
class ShellLibrarySecondaryColumn extends StatefulWidget {
  const ShellLibrarySecondaryColumn({
    super.key,
    required this.open,
    required this.height,
    required this.backgroundColor,
    required this.libraries,
    required this.selectedLibraryId,
    required this.onLibrarySelected,
    this.dividerColor,
    this.onPointerEnter,
    this.onPointerExit,
  });

  final bool open;
  final double height;
  final Color backgroundColor;
  final List<HomeLibraryDashboardRow> libraries;
  final String selectedLibraryId;
  final ValueChanged<String> onLibrarySelected;
  final Color? dividerColor;
  final VoidCallback? onPointerEnter;
  final VoidCallback? onPointerExit;

  @override
  State<ShellLibrarySecondaryColumn> createState() =>
      _ShellLibrarySecondaryColumnState();
}

class _ShellLibrarySecondaryColumnState
    extends State<ShellLibrarySecondaryColumn>
    with SingleTickerProviderStateMixin {
  late final SingleMotionController _reveal = SingleMotionController(
    motion: LabMotion.shellLibrarySecondaryReveal,
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    _reveal.value = widget.open ? 1.0 : 0.0;
  }

  @override
  void didUpdateWidget(covariant ShellLibrarySecondaryColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.open == widget.open) {
      return;
    }
    if (LabMotion.reduceMotionOf(context)) {
      _reveal.value = widget.open ? 1.0 : 0.0;
      return;
    }
    _reveal.motion = LabMotion.shellLibrarySecondaryReveal;
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

        const double panelWidth = ShellNavigation.librarySecondaryPanelWidth;

        final TextDirection textDirection = Directionality.of(context);
        final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;

        final BorderRadius flyoutRadius = BorderRadiusDirectional.only(
          topEnd: Radius.circular(
            ShellLibrarySecondaryPanelMetrics.cornerRadius,
          ),
          bottomEnd: Radius.circular(
            ShellLibrarySecondaryPanelMetrics.cornerRadius,
          ),
        ).resolve(textDirection);

        final Widget panelChrome = Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ShellNavVerticalDivider(
              color: widget.dividerColor,
              height: widget.height,
            ),
            Expanded(
              child: ShellLibrarySecondaryPanel(
                libraries: widget.libraries,
                selectedLibraryId: widget.selectedLibraryId,
                onLibrarySelected: widget.onLibrarySelected,
                backgroundColor: widget.backgroundColor,
              ),
            ),
          ],
        );

        final Widget panelBody = DecoratedBox(
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: flyoutRadius,
            boxShadow: ShellLibrarySecondaryPanelMetrics.trailingShadows(
              scheme.shadow,
              textDirection,
            ),
          ),
          child: ClipRRect(borderRadius: flyoutRadius, child: panelChrome),
        );

        final Widget interactivePane = MouseRegion(
          cursor: ShellNavigationCursor.interactive,
          onEnter: (_) => widget.onPointerEnter?.call(),
          onExit: (_) => widget.onPointerExit?.call(),
          child: panelBody,
        );

        final double revealedWidth = panelWidth * reveal;
        final double layoutWidth =
            revealedWidth +
            ShellLibrarySecondaryPanelMetrics.trailingShadowMargin;

        return SizedBox(
          width: layoutWidth,
          height: widget.height,
          child: Stack(
            clipBehavior: Clip.none,
            textDirection: textDirection,
            children: <Widget>[
              ClipRect(
                child: SizedBox(
                  width: revealedWidth,
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
              ),
            ],
          ),
        );
      },
    );
  }
}
