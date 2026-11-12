import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/lab/lab_library_catalog.dart';
import 'package:hentai_library/shared/ui/shell/desktop_shell_metrics.dart';
import 'package:hentai_library/shared/ui/shell/desktop_shell_pane.dart';
import 'package:hentai_library/shared/ui/shell/shell_library_picker_sheet.dart';
import 'package:hentai_library/shared/ui/shell/shell_library_secondary_column.dart';
import 'package:hentai_library/shared/ui/shell/shell_library_secondary_layout.dart';
import 'package:hentai_library/shared/ui/shell/shell_navigation.dart';
import 'package:hentai_library/shared/ui/shell/shell_rail_library_hover_metrics.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_library_dashboard_models.dart';
import 'package:hentai_library/shared/ui/widgets/desktop/desktop_title_bar.dart';
import 'package:hentai_library/shared/ui/widgets/desktop/navigation_bar.dart';
import 'package:hentai_library/shared/ui/widgets/desktop/navigation_rail.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

export 'package:hentai_library/shared/ui/shell/desktop_shell_metrics.dart';
export 'package:hentai_library/shared/ui/shell/desktop_shell_pane.dart';
export 'package:hentai_library/shared/ui/shell/shell_navigation.dart';

/// Lab shell: navigation + content pane.
///
/// &lt; [Breakpoints.expanded]: bottom [ExpressiveNavigationBar].
/// ≥ expanded: standard rail + library flyout.
class DesktopShell extends StatefulWidget {
  DesktopShell({
    super.key,
    this.width,
    this.height = 768,
    this.fillHeight = false,
    this.initialRailExtended = false,
    this.railExtended,
    this.onRailExtendedToggle,
    this.destinations,
    this.railDestinations,
    this.paneChild,
    this.paneBuilder,
    this.surfaceRoles,
    List<HomeLibraryDashboardRow>? libraries,
    String? initialLibraryId,
    this.selectedNavId,
    this.selectedLibraryId,
    this.onNavIdSelected,
    this.onLibrarySelected,
    this.belowTitleBar = const <Widget>[],
    this.showNavigationMenu = false,
    this.onNavigationMenuPressed,
    this.compactShowsWindowControls = false,
  }) : libraries = libraries ?? LabLibraryCatalog.libraries(),
       initialLibraryId =
           initialLibraryId ?? LabLibraryCatalog.defaultLibraryId,
       assert(
         selectedNavId == null ||
             (onNavIdSelected != null &&
                 onLibrarySelected != null &&
                 selectedLibraryId != null),
         'Controlled shell requires nav/library selection callbacks and ids.',
       );

  final double? width;
  final double height;
  final bool fillHeight;
  final bool initialRailExtended;
  final bool? railExtended;
  final VoidCallback? onRailExtendedToggle;
  final List<ExpressiveNavigationRailDestination>? destinations;
  final List<ShellRailDestination>? railDestinations;
  final Widget? paneChild;

  final DesktopShellPaneBuilder? paneBuilder;
  final DesktopShellSurfaceRoles? surfaceRoles;
  final List<HomeLibraryDashboardRow> libraries;
  final String initialLibraryId;

  final String? selectedNavId;
  final String? selectedLibraryId;
  final ValueChanged<String>? onNavIdSelected;
  final ValueChanged<String>? onLibrarySelected;

  final List<Widget> belowTitleBar;
  final bool showNavigationMenu;
  final VoidCallback? onNavigationMenuPressed;

  /// 紧凑 / 中屏（< expanded）且运行在桌面窗口时，顶部改用带窗口控件的标题栏。
  final bool compactShowsWindowControls;

  @override
  State<DesktopShell> createState() => DesktopShellState();
}

/// [DesktopShell] 的状态；外部通过 [GlobalKey] 调用 [openNavigationRail]。
class DesktopShellState extends State<DesktopShell> {
  late bool _railExtended = widget.initialRailExtended;
  int _selectedIndex = ShellNavigation.homeDestinationIndex;
  late String _selectedLibraryId = widget.initialLibraryId;
  bool _librarySecondaryOpen = false;
  int? _previousCompactDestinationIndex;
  Timer? _secondaryOpenTimer;
  Timer? _secondaryCloseTimer;
  bool? _usesExpandedNavigation;

  bool get _isControlled => widget.selectedNavId != null;

  bool get _effectiveRailExtended => widget.railExtended ?? _railExtended;

  List<ShellRailDestination> _railSpecs(BuildContext context) {
    return widget.railDestinations ??
        labDefaultShellRailDestinations(context.l10n);
  }

  List<ExpressiveNavigationRailDestination> _presentationDestinations(
    BuildContext context,
    List<ShellRailDestination> specs,
  ) {
    return widget.destinations ?? navigationDestinationsFromShell(specs);
  }

  int _libraryAnchorIndex(List<ShellRailDestination> specs) {
    final int index = shellLibraryAnchorIndex(specs);
    assert(index >= 0, 'Shell rail must include a library flyout anchor.');
    return index;
  }

  int _effectiveSelectedIndex(BuildContext context) {
    if (_isControlled) {
      return shellDestinationIndexForNavId(
        _railSpecs(context),
        widget.selectedNavId!,
      );
    }
    return _selectedIndex;
  }

  String get _effectiveSelectedLibraryId {
    if (_isControlled && widget.selectedLibraryId != null) {
      return widget.selectedLibraryId!;
    }
    return _selectedLibraryId;
  }

  String _libraryDisplayNameForId(String libraryId) {
    for (final HomeLibraryDashboardRow row in widget.libraries) {
      if (row.libraryId == libraryId) {
        return row.displayName;
      }
    }
    return LabLibraryCatalog.displayNameForId(libraryId);
  }

  String get _selectedLibraryDisplayName =>
      _libraryDisplayNameForId(_effectiveSelectedLibraryId);

  static const Duration _librarySecondaryOpenDelay = Duration(
    milliseconds: 320,
  );
  static const Duration _librarySecondaryCloseDelay = Duration(
    milliseconds: 240,
  );

  @override
  void dispose() {
    _secondaryOpenTimer?.cancel();
    _secondaryCloseTimer?.cancel();
    super.dispose();
  }

  ShellNavigationSnapshot _navigationSnapshot(BuildContext context) {
    return ShellNavigationSnapshot(
      destinationIndex: _effectiveSelectedIndex(context),
      selectedLibraryId: _effectiveSelectedLibraryId,
      selectedLibraryDisplayName: _selectedLibraryDisplayName,
      onBackToPreviousDestination: _canBackToPreviousCompactDestination
          ? _onBackToPreviousCompactDestination
          : null,
    );
  }

  bool get _canBackToPreviousCompactDestination {
    return !(_usesExpandedNavigation ?? false) &&
        _previousCompactDestinationIndex != null;
  }

  void _onBackToPreviousCompactDestination() {
    final int? previous = _previousCompactDestinationIndex;
    if (previous == null) {
      return;
    }
    setState(() {
      _selectedIndex = previous;
      _previousCompactDestinationIndex = null;
    });
  }

  void _syncShellLayout(double width) {
    final bool expandedNav = width >= Breakpoints.expanded;
    if (_usesExpandedNavigation == expandedNav) {
      return;
    }
    _usesExpandedNavigation = expandedNav;
    _cancelLibrarySecondaryTimers();
    _librarySecondaryOpen = false;
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
    _secondaryOpenTimer = Timer(
      _librarySecondaryOpenDelay,
      _openLibrarySecondary,
    );
  }

  void _openLibrarySecondary() {
    _secondaryOpenTimer = null;
    if (!mounted) {
      return;
    }
    setState(() => _librarySecondaryOpen = true);
  }

  void _scheduleCloseLibrarySecondary() {
    _secondaryOpenTimer?.cancel();
    _secondaryOpenTimer = null;
    _secondaryCloseTimer?.cancel();
    _secondaryCloseTimer = Timer(
      _librarySecondaryCloseDelay,
      _closeLibrarySecondary,
    );
  }

  void _closeLibrarySecondary() {
    _secondaryCloseTimer = null;
    if (mounted && _librarySecondaryOpen) {
      setState(() => _librarySecondaryOpen = false);
    }
  }

  void _cancelCloseLibrarySecondary() {
    _secondaryCloseTimer?.cancel();
    _secondaryCloseTimer = null;
  }

  void _onRailDestinationSelected(
    BuildContext context,
    List<ShellRailDestination> specs,
    int index,
  ) {
    final int libraryIndex = _libraryAnchorIndex(specs);
    if (index == libraryIndex) {
      return;
    }
    if (_isControlled) {
      widget.onNavIdSelected!(shellNavIdForDestinationIndex(specs, index));
      setState(() => _librarySecondaryOpen = false);
      _cancelLibrarySecondaryTimers();
      return;
    }
    setState(() {
      _selectedIndex = index;
      _librarySecondaryOpen = false;
    });
    _cancelLibrarySecondaryTimers();
  }

  void _onLibrarySelected(String libraryId) {
    if (_isControlled) {
      widget.onLibrarySelected!(libraryId);
      setState(() => _librarySecondaryOpen = false);
      _cancelLibrarySecondaryTimers();
      return;
    }
    setState(() {
      _selectedLibraryId = libraryId;
      _selectedIndex = ShellNavigation.libraryDestinationIndex;
      _librarySecondaryOpen = false;
    });
    _cancelLibrarySecondaryTimers();
  }

  void _onBottomNavDestinationSelected(
    BuildContext context,
    List<ShellRailDestination> specs,
    int index,
  ) {
    final int libraryIndex = _libraryAnchorIndex(specs);
    if (index == libraryIndex) {
      _openLibraryPickerSheet(context);
      return;
    }
    if (_isControlled) {
      widget.onNavIdSelected!(shellNavIdForDestinationIndex(specs, index));
      return;
    }
    setState(() {
      if (index != _selectedIndex) {
        _previousCompactDestinationIndex = _selectedIndex;
      }
      _selectedIndex = index;
    });
  }

  void _openLibraryPickerSheet(BuildContext context) {
    ShellLibraryPickerSheet.show(
      context,
      libraries: widget.libraries,
      selectedLibraryId: _effectiveSelectedLibraryId,
      onLibrarySelected: _onLibrarySelected,
    );
  }

  void _toggleRailExtended() {
    if (widget.onRailExtendedToggle != null) {
      widget.onRailExtendedToggle!();
      return;
    }
    setState(() => _railExtended = !_railExtended);
  }

  /// 兼容旧 API：medium- 已改用底部导航，不再打开抽屉。
  void openNavigationRail() {}

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final DesktopShellSurfaceRoles surfaces =
        widget.surfaceRoles ?? DesktopShellSurfaceRoles.lab(scheme);
    final List<ShellRailDestination> specs = _railSpecs(context);
    final List<ExpressiveNavigationRailDestination> destinations =
        _presentationDestinations(context, specs);

    final Widget shell = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final BoxConstraints resolved = widget.width != null
            ? constraints.copyWith(maxWidth: widget.width!)
            : constraints;
        final double shellHeight = widget.fillHeight
            ? resolved.maxHeight
            : widget.height;
        final Widget body = _ShellBody(
          state: this,
          constraints: resolved,
          surfaces: surfaces,
          specs: specs,
          destinations: destinations,
          shellHeight: shellHeight,
        );
        if (widget.fillHeight) {
          return SizedBox(
            width: widget.width,
            height: shellHeight,
            child: body,
          );
        }
        return SizedBox(
          height: widget.height,
          width: widget.width,
          child: body,
        );
      },
    );

    final Widget wrappedShell = DefaultTextStyle.merge(
      style: TextStyle(fontFamily: appFontFamilyOf(context)),
      child: shell,
    );

    if (widget.fillHeight) {
      return wrappedShell;
    }
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

class _ShellBody extends StatelessWidget {
  const _ShellBody({
    required this.state,
    required this.constraints,
    required this.surfaces,
    required this.specs,
    required this.destinations,
    required this.shellHeight,
  });

  final DesktopShellState state;
  final BoxConstraints constraints;
  final DesktopShellSurfaceRoles surfaces;
  final List<ShellRailDestination> specs;
  final List<ExpressiveNavigationRailDestination> destinations;
  final double shellHeight;

  @override
  Widget build(BuildContext context) {
    state._syncShellLayout(constraints.maxWidth);
    final bool usesExpandedNav = state._usesExpandedNavigation ?? false;
    final M3EThemeData m3e = M3ETheme.of(context);
    final M3EColorScheme scheme = m3e.colorScheme;
    final M3ENavigationRailTheme navTheme = m3e.navigationRailTheme;
    final M3EThemeData railTheme = m3e.copyWith(
      navigationRailTheme: navTheme.copyWith(
        containerColor: surfaces.navigationRailBackground,
      ),
    );
    final double cornerRadius = DesktopShellMetrics.paneCornerRadius;
    // 页面视口：内容区真实宽度（已扣除侧栏），页面内 PageLayoutSpec.of 据此解析。
    final Widget pane = PageViewport(child: _PaneBody(state: state));

    final Widget contentColumn = usesExpandedNav
        ? _DesktopContentColumn(
            state: state,
            surfaces: surfaces,
            pane: pane,
            cornerRadius: cornerRadius,
          )
        : _CompactContentColumn(
            state: state,
            specs: specs,
            destinations: destinations,
            surfaces: surfaces,
            pane: pane,
          );

    return ColoredBox(
      color: surfaces.shellBackground,
      child: usesExpandedNav
          ? _ExpandedNavigation(
              state: state,
              specs: specs,
              railTheme: railTheme,
              surfaces: surfaces,
              destinations: destinations,
              navTheme: navTheme,
              scheme: scheme,
              contentColumn: contentColumn,
              shellHeight: shellHeight,
            )
          : contentColumn,
    );
  }
}

class _PaneBody extends StatelessWidget {
  const _PaneBody({required this.state});

  final DesktopShellState state;

  @override
  Widget build(BuildContext context) {
    final DesktopShellPaneBuilder? paneBuilder = state.widget.paneBuilder;
    if (paneBuilder != null) {
      return paneBuilder(context, state._navigationSnapshot(context));
    }
    return state.widget.paneChild ?? const SizedBox.expand();
  }
}

class _CompactContentColumn extends StatelessWidget {
  const _CompactContentColumn({
    required this.state,
    required this.specs,
    required this.destinations,
    required this.surfaces,
    required this.pane,
  });

  final DesktopShellState state;
  final List<ShellRailDestination> specs;
  final List<ExpressiveNavigationRailDestination> destinations;
  final DesktopShellSurfaceRoles surfaces;
  final Widget pane;

  @override
  Widget build(BuildContext context) {
    final Widget paneWithChrome = DesktopShellPane(
      showDecoration: false,
      child: pane,
    );
    // 桌面窗口需要窗口控件（关闭 / 最小化）；主导航改由底部栏承担。
    final Widget? topBar = state.widget.compactShowsWindowControls
        ? const DesktopTitleBar(
            showWindowControls: true,
            backgroundColor: Colors.transparent,
          )
        : null;
    return ColoredBox(
      color: surfaces.contentPaneBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ?topBar,
          ...state.widget.belowTitleBar,
          Expanded(child: paneWithChrome),
          ExpressiveNavigationBar(
            destinations: destinations,
            selectedIndex: state._effectiveSelectedIndex(context),
            onDestinationSelected: (int index) =>
                state._onBottomNavDestinationSelected(context, specs, index),
            backgroundColor: surfaces.navigationRailBackground,
          ),
        ],
      ),
    );
  }
}

class _DesktopContentColumn extends StatelessWidget {
  const _DesktopContentColumn({
    required this.state,
    required this.surfaces,
    required this.pane,
    required this.cornerRadius,
  });

  final DesktopShellState state;
  final DesktopShellSurfaceRoles surfaces;
  final Widget pane;
  final double cornerRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: DesktopShellMetrics.contentCardLeadingRadius(cornerRadius),
      child: ColoredBox(
        color: surfaces.contentPaneBackground,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            DesktopTitleBar(
              showWindowControls: true,
              backgroundColor: Colors.transparent,
              showNavigationMenu: state.widget.showNavigationMenu,
              onNavigationMenuPressed: state.widget.onNavigationMenuPressed,
            ),
            ...state.widget.belowTitleBar,
            Expanded(
              child: DesktopShellPane(showDecoration: false, child: pane),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailColumn extends StatelessWidget {
  const _RailColumn({
    required this.state,
    required this.specs,
    required this.railTheme,
    required this.destinations,
    required this.navTheme,
    required this.shellHeight,
  });

  final DesktopShellState state;
  final List<ShellRailDestination> specs;
  final M3EThemeData railTheme;
  final List<ExpressiveNavigationRailDestination> destinations;
  final M3ENavigationRailTheme navTheme;
  final double shellHeight;

  @override
  Widget build(BuildContext context) {
    final int libraryIndex = state._libraryAnchorIndex(specs);
    final double libraryTop = ShellRailLibraryHoverMetrics.destinationTop(
      theme: navTheme,
      railExtended: state._effectiveRailExtended,
      destinationIndex: libraryIndex,
    );
    final double libraryHeight = ShellRailLibraryHoverMetrics.destinationHeight(
      theme: navTheme,
      railExtended: state._effectiveRailExtended,
    );

    return MouseRegion(
      cursor: ShellNavigationCursor.chrome,
      child: SizedBox(
        height: shellHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            M3ETheme(
              data: railTheme,
              child: ExpressiveNavigationRail(
                destinations: destinations,
                selectedIndex: state._effectiveSelectedIndex(context),
                extended: state._effectiveRailExtended,
                onMenuPressed: state._toggleRailExtended,
                onDestinationSelected: (int index) =>
                    state._onRailDestinationSelected(context, specs, index),
              ),
            ),
            Positioned(
              top: libraryTop,
              left: 0,
              right: 0,
              height: libraryHeight,
              child: MouseRegion(
                hitTestBehavior: HitTestBehavior.translucent,
                cursor: ShellNavigationCursor.interactive,
                onEnter: (_) => state._onLibraryHoverEnter(),
                onExit: (_) => state._scheduleCloseLibrarySecondary(),
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryFlyout extends StatelessWidget {
  const _LibraryFlyout({
    required this.state,
    required this.surfaces,
    required this.scheme,
    required this.shellHeight,
  });

  final DesktopShellState state;
  final DesktopShellSurfaceRoles surfaces;
  final M3EColorScheme scheme;
  final double shellHeight;

  @override
  Widget build(BuildContext context) {
    return ShellLibrarySecondaryColumn(
      open: state._librarySecondaryOpen,
      height: shellHeight,
      backgroundColor: surfaces.navigationRailBackground,
      dividerColor: scheme.outlineVariant,
      libraries: state.widget.libraries,
      selectedLibraryId: state._effectiveSelectedLibraryId,
      onLibrarySelected: state._onLibrarySelected,
      onPointerEnter: state._cancelCloseLibrarySecondary,
      onPointerExit: state._scheduleCloseLibrarySecondary,
    );
  }
}

class _ExpandedNavigation extends StatelessWidget {
  const _ExpandedNavigation({
    required this.state,
    required this.specs,
    required this.railTheme,
    required this.surfaces,
    required this.destinations,
    required this.navTheme,
    required this.scheme,
    required this.contentColumn,
    required this.shellHeight,
  });

  final DesktopShellState state;
  final List<ShellRailDestination> specs;
  final M3EThemeData railTheme;
  final DesktopShellSurfaceRoles surfaces;
  final List<ExpressiveNavigationRailDestination> destinations;
  final M3ENavigationRailTheme navTheme;
  final M3EColorScheme scheme;
  final Widget contentColumn;
  final double shellHeight;

  @override
  Widget build(BuildContext context) {
    final Widget rail = _RailColumn(
      state: state,
      specs: specs,
      railTheme: railTheme,
      destinations: destinations,
      navTheme: navTheme,
      shellHeight: shellHeight,
    );

    final Widget flyout = _LibraryFlyout(
      state: state,
      surfaces: surfaces,
      scheme: scheme,
      shellHeight: shellHeight,
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
              Positioned(left: 0, top: 0, child: flyout),
            ],
          ),
        ),
      ],
    );
  }
}
