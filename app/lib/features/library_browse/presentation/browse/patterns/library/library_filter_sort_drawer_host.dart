import 'package:flutter/widgets.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/patterns/library/library_filter_sort_side_sheet.dart';

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
