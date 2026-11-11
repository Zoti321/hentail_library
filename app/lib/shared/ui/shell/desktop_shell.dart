import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/lab/lab_library_catalog.dart';
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

export 'package:hentai_library/shared/ui/shell/shell_navigation.dart';

/// Shell layout metrics for the desktop content card.
abstract final class DesktopShellMetrics {
  static const double paneCornerRadius = 20;

  /// Content card: rounded on the leading edge only (rail side).
  static BorderRadius contentCardLeadingRadius([
    double radius = paneCornerRadius,
  ]) {
    return BorderRadius.only(
      topLeft: Radius.circular(radius),
      bottomLeft: Radius.circular(radius),
    );
  }
}

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

  Widget _buildCompactContentColumn({
    required BuildContext context,
    required List<ShellRailDestination> specs,
    required List<ExpressiveNavigationRailDestination> destinations,
    required DesktopShellSurfaceRoles surfaces,
    required Widget pane,
  }) {
    final Widget paneWithChrome = DesktopShellPane(
      showDecoration: false,
      child: pane,
    );
    // 桌面窗口需要窗口控件（关闭 / 最小化）；主导航改由底部栏承担。
    final Widget? topBar = widget.compactShowsWindowControls
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
          ...widget.belowTitleBar,
          Expanded(child: paneWithChrome),
          ExpressiveNavigationBar(
            destinations: destinations,
            selectedIndex: _effectiveSelectedIndex(context),
            onDestinationSelected: (int index) =>
                _onBottomNavDestinationSelected(context, specs, index),
            backgroundColor: surfaces.navigationRailBackground,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopContentColumn({
    required DesktopShellSurfaceRoles surfaces,
    required Widget pane,
    required double cornerRadius,
  }) {
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
              showNavigationMenu: widget.showNavigationMenu,
              onNavigationMenuPressed: widget.onNavigationMenuPressed,
            ),
            ...widget.belowTitleBar,
            Expanded(
              child: DesktopShellPane(showDecoration: false, child: pane),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPane(BuildContext context) {
    if (widget.paneBuilder != null) {
      return widget.paneBuilder!(context, _navigationSnapshot(context));
    }
    return widget.paneChild ?? const SizedBox.expand();
  }

  Widget _buildRailColumn({
    required BuildContext context,
    required List<ShellRailDestination> specs,
    required M3EThemeData railTheme,
    required List<ExpressiveNavigationRailDestination> destinations,
    required M3ENavigationRailTheme navTheme,
    required double shellHeight,
  }) {
    final int libraryIndex = _libraryAnchorIndex(specs);
    final double libraryTop = ShellRailLibraryHoverMetrics.destinationTop(
      theme: navTheme,
      railExtended: _effectiveRailExtended,
      destinationIndex: libraryIndex,
    );
    final double libraryHeight = ShellRailLibraryHoverMetrics.destinationHeight(
      theme: navTheme,
      railExtended: _effectiveRailExtended,
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
                selectedIndex: _effectiveSelectedIndex(context),
                extended: _effectiveRailExtended,
                onMenuPressed: _toggleRailExtended,
                onDestinationSelected: (int index) =>
                    _onRailDestinationSelected(context, specs, index),
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
    required DesktopShellSurfaceRoles surfaces,
    required M3EColorScheme scheme,
    required double shellHeight,
  }) {
    return ShellLibrarySecondaryColumn(
      open: _librarySecondaryOpen,
      height: shellHeight,
      backgroundColor: surfaces.navigationRailBackground,
      dividerColor: scheme.outlineVariant,
      libraries: widget.libraries,
      selectedLibraryId: _effectiveSelectedLibraryId,
      onLibrarySelected: _onLibrarySelected,
      onPointerEnter: _cancelCloseLibrarySecondary,
      onPointerExit: _scheduleCloseLibrarySecondary,
    );
  }

  Widget _buildExpandedNavigation({
    required BuildContext context,
    required List<ShellRailDestination> specs,
    required M3EThemeData railTheme,
    required DesktopShellSurfaceRoles surfaces,
    required List<ExpressiveNavigationRailDestination> destinations,
    required M3ENavigationRailTheme navTheme,
    required M3EColorScheme scheme,
    required Widget contentColumn,
    required double shellHeight,
  }) {
    final Widget rail = _buildRailColumn(
      context: context,
      specs: specs,
      railTheme: railTheme,
      destinations: destinations,
      navTheme: navTheme,
      shellHeight: shellHeight,
    );

    final Widget flyout = _buildLibrarySecondaryFlyout(
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

  Widget _buildShellBody(
    BuildContext context,
    BoxConstraints constraints,
    DesktopShellSurfaceRoles surfaces,
    List<ShellRailDestination> specs,
    List<ExpressiveNavigationRailDestination> destinations,
    double shellHeight,
  ) {
    final double shellWidth = constraints.maxWidth;
    _syncShellLayout(shellWidth);
    final bool usesExpandedNav = _usesExpandedNavigation ?? false;
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
    final Widget pane = PageViewport(child: _buildPane(context));

    final Widget contentColumn = usesExpandedNav
        ? _buildDesktopContentColumn(
            surfaces: surfaces,
            pane: pane,
            cornerRadius: cornerRadius,
          )
        : _buildCompactContentColumn(
            context: context,
            specs: specs,
            destinations: destinations,
            surfaces: surfaces,
            pane: pane,
          );

    return ColoredBox(
      color: surfaces.shellBackground,
      child: usesExpandedNav
          ? _buildExpandedNavigation(
              context: context,
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
        final Widget body = _buildShellBody(
          context,
          resolved,
          surfaces,
          specs,
          destinations,
          shellHeight,
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

/// Main pane surface (role from [DesktopShellSurfaceRoles], r=20).
class DesktopShellPane extends StatelessWidget {
  const DesktopShellPane({
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
    final Color fill = backgroundColor ?? scheme.surfaceContainerLowest;
    final BorderRadius radius =
        borderRadius ??
        BorderRadius.circular(DesktopShellMetrics.paneCornerRadius);

    return DecoratedBox(
      decoration: BoxDecoration(color: fill, borderRadius: radius),
      child: content,
    );
  }
}
