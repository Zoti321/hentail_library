import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 管理页 facet 搜索：compact 近全宽；其余断点左对齐并限制最大宽度。
///
/// 有 [matchCountLabel] 时在搜索框右侧渲染过滤结果数。
///
/// **Clear 同步**：[M3ESearchBar.showClearButton] 只调用 [TextEditingController.clear]，
/// 不会走 [M3ESearchBar.onChanged]；因此本组件监听 [controller]，保证清空也会通知业务层。
///
/// **指针再聚焦**：桌面 [EditableText.selectAllOnFocus] 默认为 true；MD3E 外壳在
/// `onPointerDown` 里先 [FocusNode.requestFocus]（外部聚焦），会先全选，随后手势
/// 再把光标放到点击处/末尾。指针触发的聚焦在全选后收成末尾折叠选区，避免闪一下全选；
/// Tab 聚焦仍保留平台默认全选。
class ManagementFacetSearchBar extends StatefulWidget {
  const ManagementFacetSearchBar({
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
  State<ManagementFacetSearchBar> createState() =>
      _ManagementFacetSearchBarState();
}

class _ManagementFacetSearchBarState extends State<ManagementFacetSearchBar> {
  late String _lastEmitted;
  FocusNode? _ownedFocusNode;
  bool _pointerDown = false;
  bool _focusListenerAttached = false;

  FocusNode get _focusNode => widget.focusNode ?? _ownedFocusNode!;

  @override
  void initState() {
    super.initState();
    _lastEmitted = widget.controller.text;
    widget.controller.addListener(_handleControllerTick);
    if (widget.focusNode == null) {
      _ownedFocusNode = FocusNode(debugLabel: 'facetSearch');
    }
    // 等 [M3ESearchBar]/EditableText 注册完 focus listener 后再挂，才能在全选之后改选区。
    SchedulerBinding.instance.addPostFrameCallback((_) => _ensureFocusListener());
  }

  @override
  void didUpdateWidget(covariant ManagementFacetSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerTick);
      _lastEmitted = widget.controller.text;
      widget.controller.addListener(_handleControllerTick);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      _detachFocusListener(oldWidget.focusNode ?? _ownedFocusNode);
      if (widget.focusNode == null && _ownedFocusNode == null) {
        _ownedFocusNode = FocusNode(debugLabel: 'facetSearch');
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
      return;
    }
    if (!_pointerDown) {
      return;
    }
    _pointerDown = false;
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
      minHeight: ManagementFacetSearchBar.height,
      maxWidth: ManagementFacetSearchBar.maxWidth,
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
          final double matchReserve = showMatch ? 96 + matchGap : 0;
          final double available = constraints.maxWidth;
          final double barWidth = compact
              ? math.max(0, available - matchReserve)
              : math.min(
                  ManagementFacetSearchBar.maxWidth,
                  math.max(0, available - matchReserve),
                );
          final double height = ManagementFacetSearchBar.height;

          final Widget searchBar = Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => _pointerDown = true,
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
