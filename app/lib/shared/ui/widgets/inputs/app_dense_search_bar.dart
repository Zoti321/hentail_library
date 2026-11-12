import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 管理/列表页 dense 搜索：compact 近全宽；其余断点左对齐并限制最大宽度。
///
/// 有 [matchCountLabel] 时在搜索框右侧渲染过滤结果数。
///
/// **Clear 同步**：[M3ESearchBar.showClearButton] 只调用 [TextEditingController.clear]，
/// 不会走 [M3ESearchBar.onChanged]；因此本组件监听 [controller]，保证清空也会通知业务层。
///
/// **指针再聚焦**：桌面 [EditableText.selectAllOnFocus] 默认为 true；MD3E 在
/// `onPointerDown` 里先 [FocusNode.requestFocus]（外部聚焦），会先全选。
/// 外层 [Listener] 晚于内层收到同一 pointerDown，故在外层回调里（此时往往已
/// 聚焦并全选）立刻收成末尾折叠选区，避免闪一下全选；Tab 聚焦无 pointer，保留全选。
class AppDenseSearchBar extends StatefulWidget {
  const AppDenseSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.matchCountLabel,
    this.focusNode,
  });

  /// 非 compact 最大宽度（短于 MD3E 默认 720）。
  static const double maxWidth = 360;

  /// 容器高度。过低会被 [M3ESliverSearchBar] 的 ClipRect 裁切字与 clear 按钮。
  static const double height = 48;

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String> onChanged;

  /// 过滤中时展示在搜索框右侧；为 null 时不占位。
  final String? matchCountLabel;

  @override
  State<AppDenseSearchBar> createState() => _AppDenseSearchBarState();
}

class _AppDenseSearchBarState extends State<AppDenseSearchBar> {
  late String _lastEmitted;
  FocusNode? _ownedFocusNode;
  bool _pointerDown = false;
  bool _collapseSelectAllForPointerFocus = false;
  bool _focusListenerAttached = false;

  FocusNode get _focusNode => widget.focusNode ?? _ownedFocusNode!;

  @override
  void initState() {
    super.initState();
    _lastEmitted = widget.controller.text;
    widget.controller.addListener(_handleControllerTick);
    if (widget.focusNode == null) {
      _ownedFocusNode = FocusNode(debugLabel: 'denseSearch');
    }
    // 等 [M3ESearchBar]/EditableText 注册完 focus listener 后再挂，才能在全选之后改选区。
    SchedulerBinding.instance.addPostFrameCallback(
      (_) => _ensureFocusListener(),
    );
  }

  @override
  void didUpdateWidget(covariant AppDenseSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerTick);
      _lastEmitted = widget.controller.text;
      widget.controller.addListener(_handleControllerTick);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      _detachFocusListener(oldWidget.focusNode ?? _ownedFocusNode);
      if (widget.focusNode == null && _ownedFocusNode == null) {
        _ownedFocusNode = FocusNode(debugLabel: 'denseSearch');
      } else if (widget.focusNode != null && _ownedFocusNode != null) {
        _ownedFocusNode!.dispose();
        _ownedFocusNode = null;
      }
      SchedulerBinding.instance.addPostFrameCallback(
        (_) => _ensureFocusListener(),
      );
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerTick);
    _detachFocusListener(_focusNode);
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  void _ensureFocusListener() {
    if (!mounted || _focusListenerAttached) {
      return;
    }
    _focusNode.addListener(_handleFocusForPointerRefocus);
    _focusListenerAttached = true;
  }

  void _detachFocusListener(FocusNode? node) {
    if (!_focusListenerAttached || node == null) {
      return;
    }
    node.removeListener(_handleFocusForPointerRefocus);
    _focusListenerAttached = false;
  }

  void _handleControllerTick() {
    if (_collapseSelectAllForPointerFocus) {
      _collapseSelectAllIfNeeded();
    }
    final String text = widget.controller.text;
    if (text == _lastEmitted) {
      return;
    }
    _lastEmitted = text;
    widget.onChanged(text);
  }

  void _handleFocusForPointerRefocus() {
    if (!_focusNode.hasFocus) {
      _pointerDown = false;
      _collapseSelectAllForPointerFocus = false;
      return;
    }
    // 仅当外层 pointer 已先置位时处理（少见：事件序与 MD3E 相反）。
    // 常见路径见 [_handlePointerDown]：内层先聚焦全选，外层再收选区。
    if (!_pointerDown) {
      return;
    }
    _armPointerSelectAllCollapse();
  }

  /// MD3E 内层 `onPointerDown` 先于外层触发：通常已 requestFocus 并全选。
  /// 外层回调里立刻收选区，赶在本帧绘制前消除闪烁。
  void _handlePointerDown(PointerDownEvent _) {
    _pointerDown = true;
    if (_focusNode.hasFocus) {
      _armPointerSelectAllCollapse();
    }
  }

  void _armPointerSelectAllCollapse() {
    _collapseSelectAllForPointerFocus = true;
    _collapseSelectAllIfNeeded();
    scheduleMicrotask(() {
      if (!mounted) {
        return;
      }
      _collapseSelectAllIfNeeded();
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _collapseSelectAllForPointerFocus = false;
        _pointerDown = false;
      });
    });
  }

  void _collapseSelectAllIfNeeded() {
    final String text = widget.controller.text;
    if (text.isEmpty) {
      return;
    }
    final TextSelection selection = widget.controller.selection;
    final bool looksLikeSelectAll =
        selection.baseOffset == 0 && selection.extentOffset == text.length;
    if (!looksLikeSelectAll) {
      return;
    }
    widget.controller.selection = TextSelection.collapsed(offset: text.length);
  }

  @override
  Widget build(BuildContext context) {
    final bool compact = windowSizeClassOf(context).isCompact;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3ESearchBarTheme denseBarTheme = theme.searchBarTheme.copyWith(
      minHeight: AppDenseSearchBar.height,
      maxWidth: AppDenseSearchBar.maxWidth,
      tapTargetSize: 40,
      leadingSpace: 4,
      trailingSpace: 4,
    );
    final TextStyle denseLabel = theme.typeScale.bodyMedium.copyWith(
      color: theme.colorScheme.onSurface,
    );
    final TextStyle denseHint = theme.typeScale.bodyMedium.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final TextStyle matchStyle = theme.typeScale.labelLarge.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );

    return M3ETheme(
      data: theme.copyWith(searchBarTheme: denseBarTheme),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final String? matchLabel = widget.matchCountLabel;
          final bool showMatch = matchLabel != null && matchLabel.isNotEmpty;
          const double matchGap = 12;
          final double matchReserve = showMatch ? matchGap + 96 : 0;
          final double available = constraints.maxWidth;
          final double barWidth = compact
              ? math.max(0, available - matchReserve)
              : math.min(
                  AppDenseSearchBar.maxWidth,
                  math.max(0, available - matchReserve),
                );
          final double height = AppDenseSearchBar.height;

          final Widget searchBar = Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: _handlePointerDown,
            child: SizedBox(
              width: compact ? null : barWidth,
              height: height,
              child: M3ESearchBar(
                controller: widget.controller,
                focusNode: _focusNode,
                hintText: widget.hintText,
                leading: const Icon(M3EIcons.search, size: 20),
                trailing: null,
                enabled: true,
                expandOnFocus: true,
                showClearButton: true,
                margin: 0,
                focusedMargin: 0,
                textStyle: WidgetStatePropertyAll<TextStyle>(denseLabel),
                hintStyle: WidgetStatePropertyAll<TextStyle>(denseHint),
                constraints: BoxConstraints(
                  minWidth: compact ? 0 : barWidth,
                  maxWidth: compact ? double.infinity : barWidth,
                  minHeight: height,
                  maxHeight: height,
                ),
              ),
            ),
          );

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              if (compact) Expanded(child: searchBar) else searchBar,
              if (showMatch) ...<Widget>[
                const SizedBox(width: matchGap),
                Flexible(
                  child: Text(
                    matchLabel,
                    style: matchStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
