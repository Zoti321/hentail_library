import 'dart:math' as math;

import 'package:hentai_library/features/comic/public.dart';

import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/shared/ui/patterns/library/library_filter_sort_metrics.dart';
import 'package:hentai_library/shared/ui/widgets/sheets/overlay_route_scope.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_age_restriction_filter.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_media_type_filter.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:hentai_library/features/library_browse/public/l10n/library_browse_l10n.dart';
import 'package:hentai_library/features/comic/public/l10n/comic_l10n.dart';

/// 筛选排序抽屉的本地状态（Widgetbook / 测试用，不绑 Riverpod）。
///
/// 字段与生产 [LibraryComicFiltersState] 的抽屉子集一致。
class LibraryFilterSortState {
  LibraryFilterSortState({
    this.ageRestriction = LibraryAgeRestrictionFilter.unrestricted,
    this.mediaTypeFilter = const LibraryMediaTypeFilterSelection(),
    this.grouping = LibraryComicGrouping.defaultValue,
    LibraryComicSortOption? sortOption,
  }) : sortOption = sortOption ?? LibraryComicSortOption();

  final LibraryAgeRestrictionFilter ageRestriction;
  final LibraryMediaTypeFilterSelection mediaTypeFilter;
  final LibraryComicGrouping grouping;
  final LibraryComicSortOption sortOption;

  static final LibraryFilterSortState defaults = LibraryFilterSortState();

  bool get isCustomized {
    final LibraryComicSortOption defaultSort = LibraryComicSortOption();
    return ageRestriction != LibraryAgeRestrictionFilter.unrestricted ||
        mediaTypeFilter.isActive ||
        grouping != LibraryComicGrouping.defaultValue ||
        sortOption.field != defaultSort.field ||
        sortOption.descending != defaultSort.descending;
  }

  LibraryFilterSortState copyWith({
    LibraryAgeRestrictionFilter? ageRestriction,
    LibraryMediaTypeFilterSelection? mediaTypeFilter,
    LibraryComicGrouping? grouping,
    LibraryComicSortOption? sortOption,
  }) {
    return LibraryFilterSortState(
      ageRestriction: ageRestriction ?? this.ageRestriction,
      mediaTypeFilter: mediaTypeFilter ?? this.mediaTypeFilter,
      grouping: grouping ?? this.grouping,
      sortOption: sortOption ?? this.sortOption,
    );
  }

  LibraryFilterSortState toggleAgeRestriction(
    LibraryAgeRestrictionFilter option,
  ) {
    return copyWith(
      ageRestriction: ageRestriction == option
          ? LibraryAgeRestrictionFilter.unrestricted
          : option,
    );
  }

  LibraryFilterSortState toggleMediaType(LibraryMediaTypeFilterOption option) {
    return copyWith(mediaTypeFilter: mediaTypeFilter.withToggled(option));
  }

  LibraryFilterSortState selectSortField(LibraryComicSortField field) {
    if (sortOption.field == field) {
      return copyWith(
        sortOption: sortOption.copyWith(descending: !sortOption.descending),
      );
    }
    return copyWith(
      sortOption: LibraryComicSortOption(field: field, descending: false),
    );
  }

  LibraryFilterSortState setGroupBySeries(bool enabled) {
    return copyWith(
      grouping: enabled
          ? LibraryComicGrouping.bySeries
          : LibraryComicGrouping.none,
    );
  }

  LibraryFilterSortState selectGrouping(LibraryComicGrouping grouping) {
    return copyWith(grouping: grouping);
  }

  LibraryFilterSortState reset() => defaults;
}

/// 漫画库筛选与排序模态面板：compact / medium 为 bottom sheet，expanded+ 为 side sheet（即时生效、无底部「应用」）。
abstract final class LibraryFilterSortSideSheet {
  LibraryFilterSortSideSheet._();

  static double widthFor(BuildContext context) {
    return libraryFilterSortSideSheetWidthForViewport(
      MediaQuery.sizeOf(context).width,
    );
  }

  static bool detachedFor(BuildContext context) {
    return libraryFilterSortSideSheetDetachedForViewport(
      MediaQuery.sizeOf(context).width,
    );
  }

  /// 模态呈现：compact / medium 用 [M3EBottomSheet]（全屏展开），expanded+ 用 [M3ESideSheet]（detached）。
  static Future<void> show(
    BuildContext context, {
    required LibraryFilterSortState state,
    required ValueChanged<LibraryFilterSortState> onStateChanged,
    bool useRootNavigator = true,
  }) {
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData m3e = M3ETheme.of(context);
    final String title = l10n.libraryFilterSortTooltip;
    final OverlayRouteScopeSnapshot scope = OverlayRouteScopeSnapshot.capture(
      context,
    );
    final Widget modalBody = overlayRouteScope(
      scope: scope,
      child: _LibraryFilterSortSideSheetModalBody(
        initialState: state,
        onStateChanged: onStateChanged,
      ),
    );

    if (libraryFilterSortPrefersBottomSheetForViewport(viewportWidth)) {
      return M3EBottomSheet.show<void>(
        context,
        useRootNavigator: useRootNavigator,
        expandToFullScreen: true,
        // 全屏头（含标题）仅在 fullScreen detent 可见；直接以全屏打开。
        initialValue: M3EBottomSheetValue.fullScreen,
        fullScreenTitle: title,
        theme: m3e.bottomSheetTheme,
        builder: (BuildContext sheetContext) {
          return PrimaryScrollController.none(
            child: SingleChildScrollView(child: modalBody),
          );
        },
      );
    }

    return M3ESideSheet.show<void>(
      context,
      title: title,
      width: libraryFilterSortSideSheetWidthForViewport(viewportWidth),
      detached: libraryFilterSortSideSheetDetachedForViewport(viewportWidth),
      theme: libraryFilterSortSideSheetTheme(m3e),
      scrollable: true,
      useRootNavigator: useRootNavigator,
      body: modalBody,
    );
  }
}

/// 由 [LibraryFilterSortDrawerHost] 注入；[body] 子树内用 [LibraryFilterSortDrawerHost.openDrawer]。
class _LibraryFilterSortHostScope extends InheritedWidget {
  const _LibraryFilterSortHostScope({
    required this.openSideSheet,
    required super.child,
  });

  final VoidCallback openSideSheet;

  static _LibraryFilterSortHostScope? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<_LibraryFilterSortHostScope>();
  }

  @override
  bool updateShouldNotify(_LibraryFilterSortHostScope oldWidget) => false;
}

/// 模态内自持状态，便于在 sheet 打开期间即时更新筛选。
class _LibraryFilterSortSideSheetModalBody extends StatefulWidget {
  const _LibraryFilterSortSideSheetModalBody({
    required this.initialState,
    required this.onStateChanged,
  });

  final LibraryFilterSortState initialState;
  final ValueChanged<LibraryFilterSortState> onStateChanged;

  @override
  State<_LibraryFilterSortSideSheetModalBody> createState() =>
      _LibraryFilterSortSideSheetModalBodyState();
}

class _LibraryFilterSortSideSheetModalBodyState
    extends State<_LibraryFilterSortSideSheetModalBody> {
  late LibraryFilterSortState _state = widget.initialState;

  @override
  void didUpdateWidget(covariant _LibraryFilterSortSideSheetModalBody old) {
    super.didUpdateWidget(old);
    if (old.initialState != widget.initialState) {
      _state = widget.initialState;
    }
  }

  void _apply(LibraryFilterSortState next) {
    setState(() => _state = next);
    widget.onStateChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return LibraryFilterSortSideSheetContent(
      state: _state,
      onStateChanged: _apply,
    );
  }
}

/// 筛选排序面板正文（供 [M3ESideSheet.body] 与测试嵌入）。
class LibraryFilterSortSideSheetContent extends StatelessWidget {
  const LibraryFilterSortSideSheetContent({
    super.key,
    required this.state,
    required this.onStateChanged,
  });

  final LibraryFilterSortState state;
  final ValueChanged<LibraryFilterSortState> onStateChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final LibraryFilterSortRowMetrics rowMetrics =
        LibraryFilterSortRowMetrics.forViewportWidth(
          MediaQuery.sizeOf(context).width,
        );
    final TextStyle sectionTitle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: cs.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kLibraryFilterSortDrawerContentInset,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(l10n.libraryFilterSection, style: sectionTitle),
                ),
                M3EIconButton(
                  icon: const Icon(Symbols.settings_backup_restore, size: 20),
                  tooltip: l10n.libraryResetAllFilters,
                  semanticLabel: l10n.libraryResetAllFilters,
                  onPressed: state.isCustomized
                      ? () => onStateChanged(state.reset())
                      : null,
                  variant: M3EIconButtonVariant.standard,
                  size: M3EIconButtonSize.sm,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _FilterAccordionSection(
            title: l10n.libraryAgeRestrictionFilter,
            metrics: rowMetrics,
            child: Column(
              children: LibraryAgeRestrictionFilter.selectableOptions
                  .map(
                    (LibraryAgeRestrictionFilter option) => _FilterCheckboxRow(
                      label: l10n.libraryAgeRestrictionFilterLabel(option),
                      selected: state.ageRestriction == option,
                      metrics: rowMetrics,
                      onChanged: () =>
                          onStateChanged(state.toggleAgeRestriction(option)),
                    ),
                  )
                  .toList(),
            ),
          ),
          _FilterAccordionSection(
            title: l10n.libraryMediaTypeFilter,
            metrics: rowMetrics,
            child: Column(
              children: LibraryMediaTypeFilterOption.selectableOptions
                  .map(
                    (LibraryMediaTypeFilterOption option) => _FilterCheckboxRow(
                      label: l10n.libraryMediaTypeFilterLabel(option),
                      selected: state.mediaTypeFilter.selected.contains(option),
                      metrics: rowMetrics,
                      onChanged: () =>
                          onStateChanged(state.toggleMediaType(option)),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(
              left: kLibraryFilterSortDrawerContentInset,
            ),
            child: Text(l10n.libraryGroupSection, style: sectionTitle),
          ),
          const SizedBox(height: 8),
          _GroupingRadioRow(
            label: l10n.libraryGroupNone,
            selected: state.grouping == LibraryComicGrouping.none,
            metrics: rowMetrics,
            onSelected: () =>
                onStateChanged(state.selectGrouping(LibraryComicGrouping.none)),
          ),
          _GroupingRadioRow(
            label: l10n.libraryGroupBySeries,
            selected: state.grouping == LibraryComicGrouping.bySeries,
            metrics: rowMetrics,
            onSelected: () => onStateChanged(
              state.selectGrouping(LibraryComicGrouping.bySeries),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(
              left: kLibraryFilterSortDrawerContentInset,
            ),
            child: Text(l10n.librarySortSection, style: sectionTitle),
          ),
          const SizedBox(height: 8),
          ...LibraryComicSortField.values.map((LibraryComicSortField field) {
            final bool selected = state.sortOption.field == field;
            return _SortListRow(
              label: l10n.libraryComicSortFieldLabel(field),
              selected: selected,
              ascending: !state.sortOption.descending,
              metrics: rowMetrics,
              onTap: () => onStateChanged(state.selectSortField(field)),
            );
          }),
        ],
      ),
    );
  }
}

/// 持有筛选状态并调用 [LibraryFilterSortSideSheet.show]，供 Lab 预览与测试。
class LibraryFilterSortDrawerHost extends StatefulWidget {
  LibraryFilterSortDrawerHost({
    super.key,
    required this.body,
    LibraryFilterSortState? initialState,
    this.onStateChanged,
    this.openSideSheetOnMount = false,
    this.useRootNavigator = true,
  }) : initialState = initialState ?? LibraryFilterSortState.defaults;

  final Widget body;
  final LibraryFilterSortState initialState;
  final ValueChanged<LibraryFilterSortState>? onStateChanged;

  /// 首帧后自动弹出 side sheet（Widgetbook 专用场景）。
  final bool openSideSheetOnMount;

  /// 传给 [M3ESideSheet.show]；Widgetbook 预览区宜为 `false`。
  final bool useRootNavigator;

  /// [context] 须为 [body] 子树（或 Host 注入的 [InheritedWidget] 之下）。
  static void openDrawer(BuildContext context) {
    _LibraryFilterSortHostScope.maybeOf(context)?.openSideSheet();
  }

  @override
  State<LibraryFilterSortDrawerHost> createState() =>
      _LibraryFilterSortDrawerHostState();
}

class _LibraryFilterSortDrawerHostState
    extends State<LibraryFilterSortDrawerHost> {
  late LibraryFilterSortState _state = widget.initialState;

  @override
  void initState() {
    super.initState();
    if (widget.openSideSheetOnMount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openSideSheet();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant LibraryFilterSortDrawerHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialState != widget.initialState) {
      _state = widget.initialState;
    }
  }

  void _setState(LibraryFilterSortState next) {
    setState(() => _state = next);
    widget.onStateChanged?.call(next);
  }

  void _openSideSheet() {
    LibraryFilterSortSideSheet.show(
      context,
      state: _state,
      onStateChanged: _setState,
      useRootNavigator: widget.useRootNavigator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _LibraryFilterSortHostScope(
      openSideSheet: _openSideSheet,
      child: widget.body,
    );
  }
}

class _FilterAccordionSection extends StatefulWidget {
  const _FilterAccordionSection({
    required this.title,
    required this.metrics,
    required this.child,
  });

  final String title;
  final LibraryFilterSortRowMetrics metrics;
  final Widget child;

  @override
  State<_FilterAccordionSection> createState() =>
      _FilterAccordionSectionState();
}

class _FilterAccordionSectionState extends State<_FilterAccordionSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            hoverColor: theme.hoverColor,
            splashColor: theme.splashColor,
            child: SizedBox(
              height: widget.metrics.accordionHeaderMinHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: kLibraryFilterSortDrawerContentInset,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: widget.metrics.accordionTitleFontSize,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    SpringValue(
                      value: _expanded ? 0.5 : 0,
                      motion: LabMotion.spatialReveal,
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: widget.metrics.sortIconSize + 4,
                        color: cs.onSurfaceVariant,
                      ),
                      builder:
                          (BuildContext context, double turns, Widget? child) {
                            return Transform.rotate(
                              angle: turns * 2 * math.pi,
                              child: child,
                            );
                          },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SpringSize(
          expanded: _expanded,
          alignment: Alignment.topCenter,
          child: widget.child,
        ),
      ],
    );
  }
}

TextStyle libraryFilterSortOptionLabelStyle(
  ColorScheme cs,
  LibraryFilterSortRowMetrics metrics,
) {
  return TextStyle(fontSize: metrics.optionLabelFontSize, color: cs.onSurface);
}

class _FilterCheckboxRow extends StatelessWidget {
  const _FilterCheckboxRow({
    required this.label,
    required this.selected,
    required this.metrics,
    required this.onChanged,
  });

  final String label;
  final bool selected;
  final LibraryFilterSortRowMetrics metrics;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ThemeData theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onChanged,
        hoverColor: theme.hoverColor,
        splashColor: theme.splashColor,
        child: SizedBox(
          height: metrics.rowMinHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kLibraryFilterSortDrawerContentInset,
            ),
            child: Row(
              children: <Widget>[
                M3ECheckbox(
                  value: selected,
                  onChanged: (_) => onChanged(),
                  focusable: false,
                  boxSize: metrics.checkboxBoxSize,
                  hitSize: metrics.checkboxHitSize,
                  targetSize: metrics.checkboxTargetSize,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: libraryFilterSortOptionLabelStyle(cs, metrics),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupingRadioRow extends StatelessWidget {
  const _GroupingRadioRow({
    required this.label,
    required this.selected,
    required this.metrics,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final LibraryFilterSortRowMetrics metrics;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ThemeData theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelected,
        hoverColor: theme.hoverColor,
        splashColor: theme.splashColor,
        child: SizedBox(
          height: metrics.rowMinHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kLibraryFilterSortDrawerContentInset,
            ),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Radio<bool>(
                    value: true,
                    groupValue: selected,
                    onChanged: (_) => onSelected(),
                    fillColor: WidgetStatePropertyAll<Color>(cs.primary),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: libraryFilterSortOptionLabelStyle(cs, metrics),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SortListRow extends StatelessWidget {
  const _SortListRow({
    required this.label,
    required this.selected,
    required this.ascending,
    required this.metrics,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool ascending;
  final LibraryFilterSortRowMetrics metrics;
  final VoidCallback onTap;

  static const double _iconSlotWidth = 20;
  static const double _iconLabelGap = 8;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ThemeData theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: theme.hoverColor,
        splashColor: theme.splashColor,
        child: SizedBox(
          height: metrics.rowMinHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kLibraryFilterSortDrawerContentInset,
            ),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: _iconSlotWidth,
                  child: selected
                      ? Icon(
                          ascending
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: metrics.sortIconSize,
                          color: cs.primary,
                        )
                      : null,
                ),
                const SizedBox(width: _iconLabelGap),
                Expanded(
                  child: Text(
                    label,
                    style: libraryFilterSortOptionLabelStyle(cs, metrics),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
