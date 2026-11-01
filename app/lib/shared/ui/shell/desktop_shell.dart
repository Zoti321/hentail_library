import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/shell/desktop_shell_surfaces.dart';
import 'package:hentai_library/shared/ui/lab/lab_library_catalog.dart';
import 'package:hentai_library/shared/ui/shell/shell_compact_app_bar.dart';
import 'package:hentai_library/shared/ui/shell/shell_compact_modal_rail.dart';
import 'package:hentai_library/shared/ui/shell/shell_library_secondary_column.dart';
import 'package:hentai_library/shared/ui/shell/shell_library_secondary_layout.dart';
import 'package:hentai_library/shared/ui/shell/shell_navigation.dart';
import 'package:hentai_library/shared/ui/shell/shell_rail_library_hover_metrics.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_library_dashboard_models.dart';
import 'package:hentai_library/shared/ui/theme/app_m3e_theme.dart';
import 'package:hentai_library/shared/ui/widgets/desktop/desktop_title_bar.dart';
import 'package:hentai_library/shared/ui/widgets/desktop/navigation_rail.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

export 'package:hentai_library/shared/ui/shell/shell_navigation.dart';

/// Shell layout metrics for the desktop content card.
abstract final class Md3eDesktopShellMetrics {
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
/// &lt; [Md3eBreakpoints.expanded]: compact app bar + modal navigation (compact/medium:
/// chevron + drill-in library secondary). ≥ expanded: standard rail + library flyout.
class Md3eDesktopShell extends StatefulWidget {
  Md3eDesktopShell({
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
    List<Md3eHomeLibraryDashboardRow>? libraries,
    String? initialLibraryId,
    this.selectedNavId,
    this.selectedLibraryId,
    this.onNavIdSelected,
    this.onLibrarySelected,
    this.belowTitleBar = const <Widget>[],
    this.showNavigationMenu = false,
    this.onNavigationMenuPressed,
    this.compactShowsWindowControls = false,
  }) : libraries = libraries ?? Md3eLabLibraryCatalog.libraries(),
       initialLibraryId =
           initialLibraryId ?? Md3eLabLibraryCatalog.defaultLibraryId,
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
  final List<Md3eNavigationRailDestination>? destinations;
  final List<Md3eShellRailDestination>? railDestinations;
  final Widget? paneChild;

  final Md3eDesktopShellPaneBuilder? paneBuilder;
  final Md3eDesktopShellSurfaceRoles? surfaceRoles;
  final List<Md3eHomeLibraryDashboardRow> libraries;
  final String initialLibraryId;

  final String? selectedNavId;
  final String? selectedLibraryId;
  final ValueChanged<String>? onNavIdSelected;
  final ValueChanged<String>? onLibrarySelected;

  final List<Widget> belowTitleBar;
  final bool showNavigationMenu;
  final VoidCallback? onNavigationMenuPressed;

  /// 紧凑 / 中屏（< expanded）且运行在桌面窗口时，顶部改用带窗口控件的标题栏（☰ 打开 modal 导航）。
  final bool compactShowsWindowControls;

  @override
  State<Md3eDesktopShell> createState() => Md3eDesktopShellState();
}

/// [Md3eDesktopShell] 的状态；外部通过 [GlobalKey] 调用 [openNavigationRail]。
class Md3eDesktopShellState extends State<Md3eDesktopShell> {
  late bool _railExtended = widget.initialRailExtended;
  int _selectedIndex = Md3eShellNavigation.homeDestinationIndex;
  late String _selectedLibraryId = widget.initialLibraryId;
  bool _librarySecondaryOpen = false;
  bool _compactModalRailOpen = false;
  int? _previousCompactDestinationIndex;
  bool _compactModalLibrarySecondaryOpen = false;
  Timer? _secondaryOpenTimer;
  Timer? _secondaryCloseTimer;
  bool? _usesExpandedNavigation;

  bool get _isControlled => widget.selectedNavId != null;

  bool get _effectiveRailExtended => widget.railExtended ?? _railExtended;

  List<Md3eShellRailDestination> _railSpecs(BuildContext context) {
    return widget.railDestinations ??
        md3eLabDefaultShellRailDestinations(context.l10n);
  }

  List<Md3eNavigationRailDestination> _presentationDestinations(
    BuildContext context,
    List<Md3eShellRailDestination> specs,
  ) {
    return widget.destinations ?? md3eNavigationDestinationsFromShell(specs);
  }

  int _libraryAnchorIndex(List<Md3eShellRailDestination> specs) {
    final int index = md3eShellLibraryAnchorIndex(specs);
    assert(index >= 0, 'Shell rail must include a library flyout anchor.');
    return index;
  }

  int _effectiveSelectedIndex(BuildContext context) {
    if (_isControlled) {
      return md3eShellDestinationIndexForNavId(
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
    for (final Md3eHomeLibraryDashboardRow row in widget.libraries) {
      if (row.libraryId == libraryId) {
        return row.displayName;
      }
    }
    return Md3eLabLibraryCatalog.displayNameForId(libraryId);
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

  Md3eShellNavigationSnapshot _navigationSnapshot(BuildContext context) {
    return Md3eShellNavigationSnapshot(
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
    final bool expandedNav = width >= Md3eBreakpoints.expanded;
    if (_usesExpandedNavigation == expandedNav) {
      return;
    }
    _usesExpandedNavigation = expandedNav;
    _cancelLibrarySecondaryTimers();
    _librarySecondaryOpen = false;
    _compactModalRailOpen = false;
    _compactModalLibrarySecondaryOpen = false;
  }

  /// Compact + medium (&lt; expanded): modal drill-in for library secondary.
  static bool _modalLibraryDrillInEnabledForWidth(double width) {
    return width < Md3eBreakpoints.expanded;
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
    List<Md3eShellRailDestination> specs,
    int index,
  ) {
    final int libraryIndex = _libraryAnchorIndex(specs);
    if (index == libraryIndex) {
      return;
    }
    if (_isControlled) {
      widget.onNavIdSelected!(md3eShellNavIdForDestinationIndex(specs, index));
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
      setState(() {
        _librarySecondaryOpen = false;
        _compactModalRailOpen = false;
        _compactModalLibrarySecondaryOpen = false;
      });
      _cancelLibrarySecondaryTimers();
      return;
    }
    setState(() {
      _selectedLibraryId = libraryId;
      _selectedIndex = Md3eShellNavigation.libraryDestinationIndex;
      _librarySecondaryOpen = false;
      _compactModalRailOpen = false;
      _compactModalLibrarySecondaryOpen = false;
    });
    _cancelLibrarySecondaryTimers();
  }

  void _onCompactRailDestinationSelected(
    BuildContext context,
    List<Md3eShellRailDestination> specs,
    int index,
  ) {
    final int libraryIndex = _libraryAnchorIndex(specs);
    if (index == libraryIndex) {
      setState(() => _compactModalLibrarySecondaryOpen = true);
      return;
    }
    if (_isControlled) {
      widget.onNavIdSelected!(md3eShellNavIdForDestinationIndex(specs, index));
      setState(() {
        _compactModalRailOpen = false;
        _compactModalLibrarySecondaryOpen = false;
      });
      return;
    }
    setState(() {
      if (index != _selectedIndex) {
        _previousCompactDestinationIndex = _selectedIndex;
      }
      _selectedIndex = index;
      _compactModalRailOpen = false;
      _compactModalLibrarySecondaryOpen = false;
    });
  }

  void _toggleRailExtended() {
    if (widget.onRailExtendedToggle != null) {
      widget.onRailExtendedToggle!();
      return;
    }
    setState(() => _railExtended = !_railExtended);
  }

  void _onCompactLibrarySecondaryBack() {
    setState(() => _compactModalLibrarySecondaryOpen = false);
  }

  void _dismissCompactModalRail() {
    setState(() {
      _compactModalRailOpen = false;
      _compactModalLibrarySecondaryOpen = false;
    });
  }

  void _openCompactModalRail() {
    setState(() {
      _compactModalRailOpen = true;
      _compactModalLibrarySecondaryOpen = false;
    });
  }

  /// 壳层外部（页头菜单等）打开紧凑 modal 导航；展开态下无操作。
  void openNavigationRail() {
    if (!mounted || (_usesExpandedNavigation ?? false)) {
      return;
    }
    _openCompactModalRail();
  }

  Widget _buildCompactContentColumn({
    required BuildContext context,
    required List<Md3eShellRailDestination> specs,
    required Md3eDesktopShellSurfaceRoles surfaces,
    required Widget pane,
  }) {
    final int settingsIndex = md3eShellSettingsDestinationIndex(specs);
    final bool isSettings = _effectiveSelectedIndex(context) == settingsIndex;
    final Widget paneWithChrome = Md3eDesktopShellPane(
      showDecoration: false,
      child: pane,
    );
    // 桌面窗口需要窗口控件（关闭 / 最小化）；移动端保持纯菜单栏。
    // 设置页自带返回/标题工具栏，不再显示壳层左上角菜单按钮。
    final Widget? topBar = widget.compactShowsWindowControls
        ? Md3eDesktopTitleBar(
            showWindowControls: true,
            backgroundColor: Colors.transparent,
            showNavigationMenu: !isSettings,
            onNavigationMenuPressed: _openCompactModalRail,
          )
        : (isSettings
              ? null
              : Md3eShellCompactAppBar(onMenuPressed: _openCompactModalRail));
    return ColoredBox(
      color: surfaces.contentPaneBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ?topBar,
          ...widget.belowTitleBar,
          Expanded(
            child: isSettings
                ? SafeArea(bottom: false, child: paneWithChrome)
                : paneWithChrome,
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
              backgroundColor: Colors.transparent,
              showNavigationMenu: widget.showNavigationMenu,
              onNavigationMenuPressed: widget.onNavigationMenuPressed,
            ),
            ...widget.belowTitleBar,
            Expanded(
              child: Md3eDesktopShellPane(showDecoration: false, child: pane),
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
    required List<Md3eShellRailDestination> specs,
    required M3EThemeData railTheme,
    required List<Md3eNavigationRailDestination> destinations,
    required M3ENavigationRailTheme navTheme,
    required double shellHeight,
  }) {
    final int libraryIndex = _libraryAnchorIndex(specs);
    final double libraryTop = Md3eShellRailLibraryHoverMetrics.destinationTop(
      theme: navTheme,
      railExtended: _effectiveRailExtended,
      destinationIndex: libraryIndex,
    );
    final double libraryHeight =
        Md3eShellRailLibraryHoverMetrics.destinationHeight(
          theme: navTheme,
          railExtended: _effectiveRailExtended,
        );

    return MouseRegion(
      cursor: Md3eShellNavigationCursor.chrome,
      child: SizedBox(
        height: shellHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            M3ETheme(
              data: railTheme,
              child: Md3eNavigationRail(
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
    required double shellHeight,
  }) {
    return Md3eShellLibrarySecondaryColumn(
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
    required List<Md3eShellRailDestination> specs,
    required M3EThemeData railTheme,
    required Md3eDesktopShellSurfaceRoles surfaces,
    required List<Md3eNavigationRailDestination> destinations,
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
    Md3eDesktopShellSurfaceRoles surfaces,
    List<Md3eShellRailDestination> specs,
    List<Md3eNavigationRailDestination> destinations,
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
    final double cornerRadius = Md3eDesktopShellMetrics.paneCornerRadius;
    // 页面视口：内容区真实宽度（已扣除侧栏），页面内 Md3ePageLayoutSpec.of 据此解析。
    final Widget pane = Md3ePageViewport(child: _buildPane(context));

    final Widget contentColumn = usesExpandedNav
        ? _buildDesktopContentColumn(
            surfaces: surfaces,
            pane: pane,
            cornerRadius: cornerRadius,
          )
        : _buildCompactContentColumn(
            context: context,
            specs: specs,
            surfaces: surfaces,
            pane: pane,
          );

    final Widget chrome = ColoredBox(
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

    return Stack(
      children: <Widget>[
        chrome,
        if (!usesExpandedNav) ...<Widget>[
          Md3eShellCompactModalRailOverlay(
            open: _compactModalRailOpen,
            height: shellHeight,
            m3eTheme: m3e,
            surfaceBackground: surfaces.navigationRailBackground,
            destinations: destinations,
            selectedIndex: _effectiveSelectedIndex(context),
            onDismiss: _dismissCompactModalRail,
            onDestinationSelected: (int index) =>
                _onCompactRailDestinationSelected(context, specs, index),
            libraryDrillInEnabled: _modalLibraryDrillInEnabledForWidth(
              shellWidth,
            ),
            librarySecondaryOpen: _compactModalLibrarySecondaryOpen,
            libraries: widget.libraries,
            selectedLibraryId: _effectiveSelectedLibraryId,
            onLibrarySecondaryBack: _onCompactLibrarySecondaryBack,
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
    final List<Md3eShellRailDestination> specs = _railSpecs(context);
    final List<Md3eNavigationRailDestination> destinations =
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
      style: const TextStyle(fontFamily: kMd3eAppFontFamily),
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
    final Color fill = backgroundColor ?? scheme.surfaceContainerLowest;
    final BorderRadius radius =
        borderRadius ??
        BorderRadius.circular(Md3eDesktopShellMetrics.paneCornerRadius);

    return DecoratedBox(
      decoration: BoxDecoration(color: fill, borderRadius: radius),
      child: content,
    );
  }
}
