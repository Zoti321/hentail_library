import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 管理页 facet 搜索：compact 近全宽；其余断点左对齐并限制最大宽度。
///
/// 有 [matchCountLabel] 时在搜索框右侧渲染过滤结果数。
///
/// **Clear 同步**：[M3ESearchBar.showClearButton] 只调用 [TextEditingController.clear]，
/// 不会走 [M3ESearchBar.onChanged]；因此本组件监听 [controller]，保证清空也会通知业务层。
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

  @override
  void initState() {
    super.initState();
    _lastEmitted = widget.controller.text;
    widget.controller.addListener(_handleControllerTick);
  }

  @override
  void didUpdateWidget(covariant ManagementFacetSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerTick);
      _lastEmitted = widget.controller.text;
      widget.controller.addListener(_handleControllerTick);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerTick);
    super.dispose();
  }

  void _handleControllerTick() {
    final String text = widget.controller.text;
    if (text == _lastEmitted) {
      return;
    }
    _lastEmitted = text;
    widget.onChanged(text);
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

          final Widget searchBar = SizedBox(
            width: compact ? null : barWidth,
            height: height,
            child: M3ESearchBar(
              controller: widget.controller,
              focusNode: widget.focusNode,
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
              // 输入与 clear 均经 controller listener → [widget.onChanged]。
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
