import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/motion/md3e_spring_size.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_library_filter_sort_metrics.dart';
import 'package:hentai_library/md3e/widgets/sheets/md3e_overlay_route_scope.dart';
import 'package:hentai_library/shared/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/shared/domain/library/library_comic_sort_option.dart';
import 'package:hentai_library/shared/domain/library/library_media_type_filter.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 筛选排序抽屉的本地状态（Widgetbook / 测试用，不绑 Riverpod）。
///
/// 字段与生产 [LibraryComicFiltersState] 的抽屉子集一致。
class Md3eLibraryFilterSortState {
  Md3eLibraryFilterSortState({
    this.ageRestriction = LibraryAgeRestrictionFilter.unrestricted,
    this.mediaTypeFilter = const LibraryMediaTypeFilterSelection(),
    LibraryComicSortOption? sortOption,
  }) : sortOption = sortOption ?? LibraryComicSortOption();

  final LibraryAgeRestrictionFilter ageRestriction;
  final LibraryMediaTypeFilterSelection mediaTypeFilter;
  final LibraryComicSortOption sortOption;

  static final Md3eLibraryFilterSortState defaults =
      Md3eLibraryFilterSortState();

  bool get isCustomized {
    final LibraryComicSortOption defaultSort = LibraryComicSortOption();
    return ageRestriction != LibraryAgeRestrictionFilter.unrestricted ||
        mediaTypeFilter.isActive ||
        sortOption.field != defaultSort.field ||
        sortOption.descending != defaultSort.descending;
  }

  Md3eLibraryFilterSortState copyWith({
    LibraryAgeRestrictionFilter? ageRestriction,
    LibraryMediaTypeFilterSelection? mediaTypeFilter,
    LibraryComicSortOption? sortOption,
  }) {
    return Md3eLibraryFilterSortState(
      ageRestriction: ageRestriction ?? this.ageRestriction,
      mediaTypeFilter: mediaTypeFilter ?? this.mediaTypeFilter,
      sortOption: sortOption ?? this.sortOption,
    );
  }

  Md3eLibraryFilterSortState toggleAgeRestriction(
    LibraryAgeRestrictionFilter option,
  ) {
    return copyWith(
      ageRestriction: ageRestriction == option
          ? LibraryAgeRestrictionFilter.unrestricted
          : option,
    );
  }

  Md3eLibraryFilterSortState toggleMediaType(
    LibraryMediaTypeFilterOption option,
  ) {
    return copyWith(mediaTypeFilter: mediaTypeFilter.withToggled(option));
  }

  Md3eLibraryFilterSortState selectSortField(LibraryComicSortField field) {
    if (sortOption.field == field) {
      return copyWith(
        sortOption: sortOption.copyWith(descending: !sortOption.descending),
      );
    }
    return copyWith(
      sortOption: LibraryComicSortOption(field: field, descending: false),
    );
  }

  Md3eLibraryFilterSortState reset() => defaults;
}

/// 漫画库筛选与排序模态 side sheet（[M3ESideSheet]、即时生效、无底部「应用」）。
abstract final class Md3eLibraryFilterSortSideSheet {
  Md3eLibraryFilterSortSideSheet._();

  static double widthFor(BuildContext context) {
    return md3eLibraryFilterSortSideSheetWidthForViewport(
      MediaQuery.sizeOf(context).width,
    );
  }

  static M3ESideSheetTheme _sheetTheme(BuildContext context) {
    final M3EThemeData m3e = M3ETheme.of(context);
    return m3e.sideSheetTheme.copyWith(
      horizontalPadding: 16,
      topElementsGap: 8,
    );
  }

  static bool detachedFor(BuildContext context) {
    return md3eLibraryFilterSortSideSheetDetachedForViewport(
      MediaQuery.sizeOf(context).width,
    );
  }

  /// 以模态 [M3ESideSheet] 呈现；宽度随视口，expanded+ 为 detached。
  static Future<void> show(
    BuildContext context, {
    required Md3eLibraryFilterSortState state,
    required ValueChanged<Md3eLibraryFilterSortState> onStateChanged,
    bool useRootNavigator = true,
  }) {
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final Md3eOverlayRouteScopeSnapshot scope =
        Md3eOverlayRouteScopeSnapshot.capture(context);
    return M3ESideSheet.show<void>(
      context,
      title: AppLocalizations.of(context).libraryFilterSortTooltip,
      width: md3eLibraryFilterSortSideSheetWidthForViewport(viewportWidth),
      detached: md3eLibraryFilterSortSideSheetDetachedForViewport(
        viewportWidth,
      ),
      theme: _sheetTheme(context),
      scrollable: true,
      useRootNavigator: useRootNavigator,
      body: md3eOverlayRouteScope(
        scope: scope,
        child: _Md3eLibraryFilterSortSideSheetModalBody(
          initialState: state,
          onStateChanged: onStateChanged,
        ),
      ),
    );
  }
}

/// 由 [Md3eLibraryFilterSortDrawerHost] 注入；[body] 子树内用 [Md3eLibraryFilterSortDrawerHost.openDrawer]。
class _Md3eLibraryFilterSortHostScope extends InheritedWidget {
  const _Md3eLibraryFilterSortHostScope({
    required this.openSideSheet,
    required super.child,
  });

  final VoidCallback openSideSheet;

  static _Md3eLibraryFilterSortHostScope? maybeOf(BuildContext context) {
    return context
        .getInheritedWidgetOfExactType<_Md3eLibraryFilterSortHostScope>();
  }

  @override
  bool updateShouldNotify(_Md3eLibraryFilterSortHostScope oldWidget) => false;
}

/// 模态内自持状态，便于在 sheet 打开期间即时更新筛选。
class _Md3eLibraryFilterSortSideSheetModalBody extends StatefulWidget {
  const _Md3eLibraryFilterSortSideSheetModalBody({
    required this.initialState,
    required this.onStateChanged,
  });

  final Md3eLibraryFilterSortState initialState;
  final ValueChanged<Md3eLibraryFilterSortState> onStateChanged;

  @override
  State<_Md3eLibraryFilterSortSideSheetModalBody> createState() =>
      _Md3eLibraryFilterSortSideSheetModalBodyState();
}

class _Md3eLibraryFilterSortSideSheetModalBodyState
    extends State<_Md3eLibraryFilterSortSideSheetModalBody> {
  late Md3eLibraryFilterSortState _state = widget.initialState;

  @override
  void didUpdateWidget(covariant _Md3eLibraryFilterSortSideSheetModalBody old) {
    super.didUpdateWidget(old);
    if (old.initialState != widget.initialState) {
      _state = widget.initialState;
    }
  }

  void _apply(Md3eLibraryFilterSortState next) {
    setState(() => _state = next);
    widget.onStateChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Md3eLibraryFilterSortSideSheetContent(
      state: _state,
      onStateChanged: _apply,
    );
  }
}

/// 筛选排序面板正文（供 [M3ESideSheet.body] 与测试嵌入）。
class Md3eLibraryFilterSortSideSheetContent extends StatelessWidget {
  const Md3eLibraryFilterSortSideSheetContent({
    super.key,
    required this.state,
    required this.onStateChanged,
  });

  final Md3eLibraryFilterSortState state;
  final ValueChanged<Md3eLibraryFilterSortState> onStateChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Md3eLibraryFilterSortRowMetrics rowMetrics =
        Md3eLibraryFilterSortRowMetrics.forViewportWidth(
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
              horizontal: kMd3eLibraryFilterSortDrawerContentInset,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(l10n.libraryFilterSection, style: sectionTitle),
                ),
                M3EIconButton(
                  icon: Icon(
                    Icons.filter_alt_off_outlined,
                    size: 20,
                    color: state.isCustomized
                        ? cs.primary
                        : cs.onSurfaceVariant.withValues(alpha: 0.38),
                  ),
                  tooltip: l10n.libraryResetAllFilters,
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
          _Md3eFilterAccordionSection(
            title: l10n.libraryAgeRestrictionFilter,
            metrics: rowMetrics,
            child: Column(
              children: LibraryAgeRestrictionFilter.selectableOptions
                  .map(
                    (LibraryAgeRestrictionFilter option) =>
                        _Md3eFilterCheckboxRow(
                          label: l10n.libraryAgeRestrictionFilterLabel(option),
                          selected: state.ageRestriction == option,
                          metrics: rowMetrics,
                          onChanged: () => onStateChanged(
                            state.toggleAgeRestriction(option),
                          ),
                        ),
                  )
                  .toList(),
            ),
          ),
          _Md3eFilterAccordionSection(
            title: l10n.libraryMediaTypeFilter,
            metrics: rowMetrics,
            child: Column(
              children: LibraryMediaTypeFilterOption.selectableOptions
                  .map(
                    (LibraryMediaTypeFilterOption option) =>
                        _Md3eFilterCheckboxRow(
                          label: l10n.libraryMediaTypeFilterLabel(option),
                          selected: state.mediaTypeFilter.selected.contains(
                            option,
                          ),
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
              left: kMd3eLibraryFilterSortDrawerContentInset,
            ),
            child: Text(l10n.librarySortSection, style: sectionTitle),
          ),
          const SizedBox(height: 8),
          ...LibraryComicSortField.values.map((LibraryComicSortField field) {
            final bool selected = state.sortOption.field == field;
            return _Md3eSortListRow(
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

/// 持有筛选状态并调用 [Md3eLibraryFilterSortSideSheet.show]，供 Lab 预览与测试。
class Md3eLibraryFilterSortDrawerHost extends StatefulWidget {
  Md3eLibraryFilterSortDrawerHost({
    super.key,
    required this.body,
    Md3eLibraryFilterSortState? initialState,
    this.onStateChanged,
    this.openSideSheetOnMount = false,
    this.useRootNavigator = true,
  }) : initialState = initialState ?? Md3eLibraryFilterSortState.defaults;

  final Widget body;
  final Md3eLibraryFilterSortState initialState;
  final ValueChanged<Md3eLibraryFilterSortState>? onStateChanged;

  /// 首帧后自动弹出 side sheet（Widgetbook 专用场景）。
  final bool openSideSheetOnMount;

  /// 传给 [M3ESideSheet.show]；Widgetbook 预览区宜为 `false`。
  final bool useRootNavigator;

  /// [context] 须为 [body] 子树（或 Host 注入的 [InheritedWidget] 之下）。
  static void openDrawer(BuildContext context) {
    _Md3eLibraryFilterSortHostScope.maybeOf(context)?.openSideSheet();
  }

  @override
  State<Md3eLibraryFilterSortDrawerHost> createState() =>
      _Md3eLibraryFilterSortDrawerHostState();
}

class _Md3eLibraryFilterSortDrawerHostState
    extends State<Md3eLibraryFilterSortDrawerHost> {
  late Md3eLibraryFilterSortState _state = widget.initialState;

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
  void didUpdateWidget(covariant Md3eLibraryFilterSortDrawerHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialState != widget.initialState) {
      _state = widget.initialState;
    }
  }

  void _setState(Md3eLibraryFilterSortState next) {
    setState(() => _state = next);
    widget.onStateChanged?.call(next);
  }

  void _openSideSheet() {
    Md3eLibraryFilterSortSideSheet.show(
      context,
      state: _state,
      onStateChanged: _setState,
      useRootNavigator: widget.useRootNavigator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _Md3eLibraryFilterSortHostScope(
      openSideSheet: _openSideSheet,
      child: widget.body,
    );
  }
}

class _Md3eFilterAccordionSection extends StatefulWidget {
  const _Md3eFilterAccordionSection({
    required this.title,
    required this.metrics,
    required this.child,
  });

  final String title;
  final Md3eLibraryFilterSortRowMetrics metrics;
  final Widget child;

  @override
  State<_Md3eFilterAccordionSection> createState() =>
      _Md3eFilterAccordionSectionState();
}

class _Md3eFilterAccordionSectionState
    extends State<_Md3eFilterAccordionSection> {
  bool _expanded = false;

  static const Duration _duration = Duration(milliseconds: 200);
  static const Curve _curve = Curves.easeOutCubic;

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
                  horizontal: kMd3eLibraryFilterSortDrawerContentInset,
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
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: _duration,
                      curve: _curve,
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: widget.metrics.sortIconSize + 4,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Md3eSpringSize(
          expanded: _expanded,
          alignment: Alignment.topCenter,
          child: widget.child,
        ),
      ],
    );
  }
}

TextStyle _md3eLibraryFilterSortOptionLabelStyle(
  ColorScheme cs,
  Md3eLibraryFilterSortRowMetrics metrics,
) {
  return TextStyle(fontSize: metrics.optionLabelFontSize, color: cs.onSurface);
}

class _Md3eFilterCheckboxRow extends StatelessWidget {
  const _Md3eFilterCheckboxRow({
    required this.label,
    required this.selected,
    required this.metrics,
    required this.onChanged,
  });

  final String label;
  final bool selected;
  final Md3eLibraryFilterSortRowMetrics metrics;
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
              horizontal: kMd3eLibraryFilterSortDrawerContentInset,
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
                    style: _md3eLibraryFilterSortOptionLabelStyle(cs, metrics),
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

class _Md3eSortListRow extends StatelessWidget {
  const _Md3eSortListRow({
    required this.label,
    required this.selected,
    required this.ascending,
    required this.metrics,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool ascending;
  final Md3eLibraryFilterSortRowMetrics metrics;
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
              horizontal: kMd3eLibraryFilterSortDrawerContentInset,
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
                    style: _md3eLibraryFilterSortOptionLabelStyle(cs, metrics),
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
