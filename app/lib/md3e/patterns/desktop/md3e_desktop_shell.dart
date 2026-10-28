import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/patterns/desktop/md3e_desktop_shell_surfaces.dart';
import 'package:hentai_library/md3e/patterns/desktop/md3e_shell_compact_app_bar.dart';
import 'package:hentai_library/md3e/patterns/desktop/md3e_shell_compact_library_sheet.dart';
import 'package:hentai_library/md3e/patterns/desktop/md3e_shell_compact_modal_rail.dart';
import 'package:hentai_library/md3e/patterns/desktop/md3e_shell_library_secondary_column.dart';
import 'package:hentai_library/md3e/patterns/desktop/md3e_shell_library_secondary_layout.dart';
import 'package:hentai_library/md3e/patterns/desktop/md3e_shell_mock_libraries.dart';
import 'package:hentai_library/md3e/patterns/desktop/md3e_shell_navigation.dart';
import 'package:hentai_library/md3e/patterns/desktop/md3e_shell_rail_library_hover_metrics.dart';
import 'package:hentai_library/md3e/theme/md3e_theme.dart';
import 'package:hentai_library/md3e/widgets/desktop/md3e_desktop_title_bar.dart';
import 'package:hentai_library/md3e/widgets/desktop/md3e_navigation_rail.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

export 'package:hentai_library/md3e/patterns/desktop/md3e_shell_navigation.dart';

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

/// Lab shell: navigation + content pane.
///
/// &lt; [Md3eBreakpoints.expanded]: compact app bar + modal expanded [M3ENavigationRail]
/// (M3 Expressive; replaces navigation drawer). ≥ expanded: standard rail + library flyout.
class Md3eDesktopShell extends StatefulWidget {
  Md3eDesktopShell({
    super.key,
    this.width,
    this.height = 768,
    this.initialRailExtended = false,
    this.destinations,
    this.paneChild,
    this.paneBuilder,
    this.surfaceRoles,
    List<String>? libraryDisplayNames,
    String? initialLibraryDisplayName,
  }) : libraryDisplayNames =
           libraryDisplayNames ?? Md3eShellMockLibraries.displayNames,
       initialLibraryDisplayName = initialLibraryDisplayName ??
           Md3eShellMockLibraries.defaultDisplayName;

  final double? width;
  final double height;
  final bool initialRailExtended;
  final List<Md3eNavigationRailDestination>? destinations;
  final Widget? paneChild;

  final Md3eDesktopShellPaneBuilder? paneBuilder;
  final Md3eDesktopShellSurfaceRoles? surfaceRoles;
  final List<String> libraryDisplayNames;
  final String initialLibraryDisplayName;

  @override
  State<Md3eDesktopShell> createState() => _Md3eDesktopShellState();
}

class _Md3eDesktopShellState extends State<Md3eDesktopShell> {
  late bool _railExtended = widget.initialRailExtended;
  int _selectedIndex = Md3eShellNavigation.homeDestinationIndex;
  late String _selectedLibraryDisplayName = widget.initialLibraryDisplayName;
  bool _librarySecondaryOpen = false;
  bool _compactLibrarySheetOpen = false;
  bool _compactModalRailOpen = false;
  Timer? _secondaryOpenTimer;
  Timer? _secondaryCloseTimer;
  bool? _usesExpandedNavigation;

  static const Duration _librarySecondaryOpenDelay = Duration(milliseconds: 320);
  static const Duration _librarySecondaryCloseDelay = Duration(milliseconds: 240);

  @override
  void dispose() {
    _secondaryOpenTimer?.cancel();
    _secondaryCloseTimer?.cancel();
    super.dispose();
  }

  Md3eShellNavigationSnapshot get _navigationSnapshot {
    return Md3eShellNavigationSnapshot(
      destinationIndex: _selectedIndex,
      selectedLibraryDisplayName: _selectedLibraryDisplayName,
    );
  }

  void _syncShellLayout(double width) {
    final bool expandedNav = width >= Md3eBreakpoints.expanded;
    if (_usesExpandedNavigation == expandedNav) {
      return;
    }
    _usesExpandedNavigation = expandedNav;
    _cancelLibrarySecondaryTimers();
    _librarySecondaryOpen = false;
    _compactLibrarySheetOpen = false;
    _compactModalRailOpen = false;
  }

  void _cancelLibrarySecondaryTimers() {
    _secondaryOpenTimer?.cancel();
    _secondaryOpenTimer = null;
    _secondaryCloseTimer?.cancel();
    _secondaryCloseTimer = null;
  }

  void _onLibraryHoverEnter() {
    _secondaryCloseTimer?.cancel();
    _secondaryCloseTimer = null;
    if (_librarySecondaryOpen || _secondaryOpenTimer != null) {
      return;
    }
    _secondaryOpenTimer = Timer(_librarySecondaryOpenDelay, () {
      _secondaryOpenTimer = null;
      if (!mounted) {
        return;
      }
      setState(() => _librarySecondaryOpen = true);
    });
  }

  void _scheduleCloseLibrarySecondary() {
    _secondaryOpenTimer?.cancel();
    _secondaryOpenTimer = null;
    _secondaryCloseTimer?.cancel();
    _secondaryCloseTimer = Timer(_librarySecondaryCloseDelay, () {
      _secondaryCloseTimer = null;
      if (mounted && _librarySecondaryOpen) {
        setState(() => _librarySecondaryOpen = false);
      }
    });
  }

  void _cancelCloseLibrarySecondary() {
    _secondaryCloseTimer?.cancel();
    _secondaryCloseTimer = null;
  }

  void _onRailDestinationSelected(int index) {
    if (index == Md3eShellNavigation.libraryDestinationIndex) {
      return;
    }
    setState(() {
      _selectedIndex = index;
      _librarySecondaryOpen = false;
    });
    _cancelLibrarySecondaryTimers();
  }

  void _onLibrarySelected(String displayName) {
    setState(() {
      _selectedLibraryDisplayName = displayName;
      _selectedIndex = Md3eShellNavigation.libraryDestinationIndex;
      _librarySecondaryOpen = false;
      _compactLibrarySheetOpen = false;
      _compactModalRailOpen = false;
    });
    _cancelLibrarySecondaryTimers();
  }

  void _onCompactRailDestinationSelected(int index) {
    if (index == Md3eShellNavigation.libraryDestinationIndex) {
      setState(() {
        _compactModalRailOpen = false;
        _compactLibrarySheetOpen = true;
      });
      return;
    }
    setState(() {
      _selectedIndex = index;
      _compactModalRailOpen = false;
    });
  }

  void _dismissCompactModalRail() {
    setState(() => _compactModalRailOpen = false);
  }

  void _openCompactModalRail() {
    setState(() => _compactModalRailOpen = true);
  }

  Widget _buildCompactContentColumn({
    required Md3eDesktopShellSurfaceRoles surfaces,
    required Widget pane,
  }) {
    return ColoredBox(
      color: surfaces.contentPaneBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Md3eShellCompactAppBar(
            onMenuPressed: _openCompactModalRail,
          ),
          Expanded(
            child: Md3eDesktopShellPane(
              showDecoration: false,
              child: pane,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopContentColumn({
    required Md3eDesktopShellSurfaceRoles surfaces,
    required Widget pane,
    required double cornerRadius,
  }) {
    return ClipRRect(
      borderRadius: Md3eDesktopShellMetrics.contentCardLeadingRadius(
        cornerRadius,
      ),
      child: ColoredBox(
        color: surfaces.contentPaneBackground,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Md3eDesktopTitleBar(
              showWindowControls: true,
              searchLeadingInset:
                  Md3eDesktopShellMetrics.titleBarContentPadding,
              backgroundColor: Colors.transparent,
            ),
            Expanded(
              child: Md3eDesktopShellPane(
                showDecoration: false,
                child: pane,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _dismissCompactLibrarySheet() {
    setState(() => _compactLibrarySheetOpen = false);
  }

  Widget _buildPane(BuildContext context) {
    if (widget.paneBuilder != null) {
      return widget.paneBuilder!(context, _navigationSnapshot);
    }
    return widget.paneChild ?? const SizedBox.expand();
  }

  Widget _buildRailColumn({
    required M3EThemeData railTheme,
    required List<Md3eNavigationRailDestination> destinations,
    required M3ENavigationRailTheme navTheme,
  }) {
    final double libraryTop = Md3eShellRailLibraryHoverMetrics.destinationTop(
      theme: navTheme,
      railExtended: _railExtended,
      destinationIndex: Md3eShellNavigation.libraryDestinationIndex,
    );
    final double libraryHeight =
        Md3eShellRailLibraryHoverMetrics.destinationHeight(
          theme: navTheme,
          railExtended: _railExtended,
        );

    return MouseRegion(
      cursor: Md3eShellNavigationCursor.chrome,
      child: SizedBox(
        height: widget.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            M3ETheme(
              data: railTheme,
              child: Md3eNavigationRail(
                destinations: destinations,
                selectedIndex: _selectedIndex,
                extended: _railExtended,
                onMenuPressed: () =>
                    setState(() => _railExtended = !_railExtended),
                onDestinationSelected: _onRailDestinationSelected,
              ),
            ),
            Positioned(
              top: libraryTop,
              left: 0,
              right: 0,
              height: libraryHeight,
              child: MouseRegion(
                hitTestBehavior: HitTestBehavior.translucent,
                cursor: Md3eShellNavigationCursor.interactive,
                onEnter: (_) => _onLibraryHoverEnter(),
                onExit: (_) => _scheduleCloseLibrarySecondary(),
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibrarySecondaryFlyout({
    required Md3eDesktopShellSurfaceRoles surfaces,
    required M3EColorScheme scheme,
  }) {
    return Md3eShellLibrarySecondaryColumn(
      open: _librarySecondaryOpen,
      height: widget.height,
      backgroundColor: surfaces.navigationRailBackground,
      dividerColor: scheme.outlineVariant,
      libraryDisplayNames: widget.libraryDisplayNames,
      selectedDisplayName: _selectedLibraryDisplayName,
      onLibrarySelected: _onLibrarySelected,
      onPointerEnter: _cancelCloseLibrarySecondary,
      onPointerExit: _scheduleCloseLibrarySecondary,
    );
  }

  Widget _buildExpandedNavigation({
    required M3EThemeData railTheme,
    required Md3eDesktopShellSurfaceRoles surfaces,
    required List<Md3eNavigationRailDestination> destinations,
    required M3ENavigationRailTheme navTheme,
    required M3EColorScheme scheme,
    required Widget contentColumn,
  }) {
    final Widget rail = _buildRailColumn(
      railTheme: railTheme,
      destinations: destinations,
      navTheme: navTheme,
    );

    final Widget flyout = _buildLibrarySecondaryFlyout(
      surfaces: surfaces,
      scheme: scheme,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        rail,
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              contentColumn,
              Positioned(
                left: 0,
                top: 0,
                child: flyout,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShellBody(
    BuildContext context,
    BoxConstraints constraints,
    Md3eDesktopShellSurfaceRoles surfaces,
    List<Md3eNavigationRailDestination> destinations,
  ) {
    _syncShellLayout(constraints.maxWidth);
    final bool usesExpandedNav = _usesExpandedNavigation ?? false;
    final M3EThemeData m3e = M3ETheme.of(context);
    final M3EColorScheme scheme = m3e.colorScheme;
    final M3ENavigationRailTheme navTheme = m3e.navigationRailTheme;
    final M3EThemeData railTheme = m3e.copyWith(
      navigationRailTheme: navTheme.copyWith(
        containerColor: surfaces.navigationRailBackground,
      ),
    );
    final double cornerRadius = Md3eDesktopShellMetrics.paneCornerRadius;
    final Widget pane = _buildPane(context);

    final Widget contentColumn = usesExpandedNav
        ? _buildDesktopContentColumn(
            surfaces: surfaces,
            pane: pane,
            cornerRadius: cornerRadius,
          )
        : _buildCompactContentColumn(surfaces: surfaces, pane: pane);

    final Widget chrome = ColoredBox(
      color: surfaces.shellBackground,
      child: usesExpandedNav
          ? _buildExpandedNavigation(
              railTheme: railTheme,
              surfaces: surfaces,
              destinations: destinations,
              navTheme: navTheme,
              scheme: scheme,
              contentColumn: contentColumn,
            )
          : contentColumn,
    );

    return Stack(
      children: <Widget>[
        chrome,
        if (!usesExpandedNav) ...<Widget>[
          Md3eShellCompactModalRailOverlay(
            open: _compactModalRailOpen,
            height: widget.height,
            m3eTheme: m3e,
            surfaceBackground: surfaces.navigationRailBackground,
            destinations: destinations,
            selectedIndex: _selectedIndex,
            onDismiss: _dismissCompactModalRail,
            onDestinationSelected: _onCompactRailDestinationSelected,
          ),
          Md3eShellCompactLibrarySheet(
            open: _compactLibrarySheetOpen,
            libraryDisplayNames: widget.libraryDisplayNames,
            selectedDisplayName: _selectedLibraryDisplayName,
            onDismiss: _dismissCompactLibrarySheet,
            onLibrarySelected: _onLibrarySelected,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final Md3eDesktopShellSurfaceRoles surfaces =
        widget.surfaceRoles ?? Md3eDesktopShellSurfaceRoles.lab(scheme);
    final List<Md3eNavigationRailDestination> destinations =
        widget.destinations ??
        md3eDefaultNavigationRailDestinations(context.l10n);

    final Widget shell = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final BoxConstraints resolved = widget.width != null
            ? constraints.copyWith(maxWidth: widget.width!)
            : constraints;
        return SizedBox(
          height: widget.height,
          width: widget.width,
          child: _buildShellBody(context, resolved, surfaces, destinations),
        );
      },
    );

    final Widget wrappedShell = DefaultTextStyle.merge(
      style: const TextStyle(fontFamily: kMd3eAppFontFamily),
      child: shell,
    );

    if (widget.width != null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: wrappedShell,
      );
    }
    return SizedBox(height: widget.height, child: wrappedShell);
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
