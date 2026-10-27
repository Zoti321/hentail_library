import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_library_filter_sort_metrics.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

const String _kMd3eLibraryFilterSortSideSheetTitle = '筛选与排序';

/// Lab 用年龄限制筛选项（对齐生产 `LibraryAgeRestrictionFilter` 可选项语义）。
enum Md3eLibraryAgeRestrictionOption {
  allAges,
  r18Only,
}

extension Md3eLibraryAgeRestrictionOptionX on Md3eLibraryAgeRestrictionOption {
  String get label => switch (this) {
    Md3eLibraryAgeRestrictionOption.allAges => '全年龄',
    Md3eLibraryAgeRestrictionOption.r18Only => 'R18',
  };
}

/// Lab 用媒体类型筛选项。
enum Md3eLibraryMediaTypeOption {
  pdf,
  epub,
  archive,
}

extension Md3eLibraryMediaTypeOptionX on Md3eLibraryMediaTypeOption {
  String get label => switch (this) {
    Md3eLibraryMediaTypeOption.pdf => 'PDF',
    Md3eLibraryMediaTypeOption.epub => 'EPUB',
    Md3eLibraryMediaTypeOption.archive => '压缩包',
  };

  static const List<Md3eLibraryMediaTypeOption> selectable =
      Md3eLibraryMediaTypeOption.values;
}

/// Lab 用漫画排序字段（对齐生产 `LibraryComicSortField` 展示集）。
enum Md3eLibraryComicSortField {
  title,
  createdAt,
  lastUpdatedAt,
  publishedAt,
  readAt,
  fileSize,
  pageCount,
}

extension Md3eLibraryComicSortFieldX on Md3eLibraryComicSortField {
  String get label => switch (this) {
    Md3eLibraryComicSortField.title => '标题',
    Md3eLibraryComicSortField.createdAt => '添加时间',
    Md3eLibraryComicSortField.lastUpdatedAt => '更新时间',
    Md3eLibraryComicSortField.publishedAt => '发布日期',
    Md3eLibraryComicSortField.readAt => '阅读时间',
    Md3eLibraryComicSortField.fileSize => '文件大小',
    Md3eLibraryComicSortField.pageCount => '页数',
  };

  static const List<Md3eLibraryComicSortField> drawerOrder =
      Md3eLibraryComicSortField.values;
}

/// 筛选排序抽屉的本地状态（Widgetbook / 测试用，不绑 Riverpod）。
class Md3eLibraryFilterSortState {
  const Md3eLibraryFilterSortState({
    this.ageOptions = const <Md3eLibraryAgeRestrictionOption>{},
    this.mediaTypes = const <Md3eLibraryMediaTypeOption>{},
    this.sortField = Md3eLibraryComicSortField.title,
    this.sortDescending = false,
  });

  final Set<Md3eLibraryAgeRestrictionOption> ageOptions;
  final Set<Md3eLibraryMediaTypeOption> mediaTypes;
  final Md3eLibraryComicSortField sortField;
  final bool sortDescending;

  static const Md3eLibraryFilterSortState defaults =
      Md3eLibraryFilterSortState();

  bool get isCustomized =>
      ageOptions.isNotEmpty ||
      mediaTypes.isNotEmpty ||
      sortField != Md3eLibraryComicSortField.title ||
      sortDescending;

  Md3eLibraryFilterSortState copyWith({
    Set<Md3eLibraryAgeRestrictionOption>? ageOptions,
    Set<Md3eLibraryMediaTypeOption>? mediaTypes,
    Md3eLibraryComicSortField? sortField,
    bool? sortDescending,
  }) {
    return Md3eLibraryFilterSortState(
      ageOptions: ageOptions ?? this.ageOptions,
      mediaTypes: mediaTypes ?? this.mediaTypes,
      sortField: sortField ?? this.sortField,
      sortDescending: sortDescending ?? this.sortDescending,
    );
  }

  Md3eLibraryFilterSortState toggleAgeOption(
    Md3eLibraryAgeRestrictionOption option,
  ) {
    final Set<Md3eLibraryAgeRestrictionOption> next =
        Set<Md3eLibraryAgeRestrictionOption>.from(ageOptions);
    if (next.contains(option)) {
      next.remove(option);
    } else {
      next.add(option);
    }
    return copyWith(ageOptions: next);
  }

  Md3eLibraryFilterSortState toggleMediaType(
    Md3eLibraryMediaTypeOption option,
  ) {
    final Set<Md3eLibraryMediaTypeOption> next =
        Set<Md3eLibraryMediaTypeOption>.from(mediaTypes);
    if (next.contains(option)) {
      next.remove(option);
    } else {
      next.add(option);
    }
    return copyWith(mediaTypes: next);
  }

  Md3eLibraryFilterSortState selectSortField(Md3eLibraryComicSortField field) {
    if (sortField == field) {
      return copyWith(sortDescending: !sortDescending);
    }
    return copyWith(sortField: field, sortDescending: false);
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
    return M3ESideSheet.show<void>(
      context,
      title: _kMd3eLibraryFilterSortSideSheetTitle,
      width: md3eLibraryFilterSortSideSheetWidthForViewport(viewportWidth),
      detached: md3eLibraryFilterSortSideSheetDetachedForViewport(
        viewportWidth,
      ),
      theme: _sheetTheme(context),
      scrollable: true,
      useRootNavigator: useRootNavigator,
      body: _Md3eLibraryFilterSortSideSheetModalBody(
        initialState: state,
        onStateChanged: onStateChanged,
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
                Expanded(child: Text('筛选', style: sectionTitle)),
                M3EIconButton(
                  icon: Icon(
                    Icons.filter_alt_off_outlined,
                    size: 20,
                    color: state.isCustomized
                        ? cs.primary
                        : cs.onSurfaceVariant.withValues(alpha: 0.38),
                  ),
                  tooltip: '重置全部',
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
            title: '年龄限制',
            metrics: rowMetrics,
            child: Column(
              children: Md3eLibraryAgeRestrictionOption.values
                  .map(
                    (Md3eLibraryAgeRestrictionOption option) =>
                        _Md3eFilterCheckboxRow(
                          label: option.label,
                          selected: state.ageOptions.contains(option),
                          metrics: rowMetrics,
                          onChanged: () =>
                              onStateChanged(state.toggleAgeOption(option)),
                        ),
                  )
                  .toList(),
            ),
          ),
          _Md3eFilterAccordionSection(
            title: '媒体类型',
            metrics: rowMetrics,
            child: Column(
              children: Md3eLibraryMediaTypeOptionX.selectable
                  .map(
                    (Md3eLibraryMediaTypeOption option) =>
                        _Md3eFilterCheckboxRow(
                          label: option.label,
                          selected: state.mediaTypes.contains(option),
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
            child: Text('排序', style: sectionTitle),
          ),
          const SizedBox(height: 8),
          ...Md3eLibraryComicSortFieldX.drawerOrder.map(
            (Md3eLibraryComicSortField field) {
              final bool selected = state.sortField == field;
              return _Md3eSortListRow(
                label: field.label,
                selected: selected,
                ascending: !state.sortDescending,
                metrics: rowMetrics,
                onTap: () => onStateChanged(state.selectSortField(field)),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 持有筛选状态并调用 [Md3eLibraryFilterSortSideSheet.show]，供 Lab 预览与测试。
class Md3eLibraryFilterSortDrawerHost extends StatefulWidget {
  const Md3eLibraryFilterSortDrawerHost({
    super.key,
    required this.body,
    this.initialState = Md3eLibraryFilterSortState.defaults,
    this.onStateChanged,
    this.openSideSheetOnMount = false,
    this.useRootNavigator = true,
  });

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

class _Md3eFilterAccordionSectionState extends State<_Md3eFilterAccordionSection> {
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
        AnimatedSize(
          duration: _duration,
          curve: _curve,
          alignment: Alignment.topCenter,
          child: _expanded ? widget.child : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

TextStyle _md3eLibraryFilterSortOptionLabelStyle(
  ColorScheme cs,
  Md3eLibraryFilterSortRowMetrics metrics,
) {
  return TextStyle(
    fontSize: metrics.optionLabelFontSize,
    color: cs.onSurface,
  );
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
