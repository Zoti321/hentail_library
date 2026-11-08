import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 管理页 facet 搜索：compact 全宽；其余断点左对齐并限制最大宽度。
///
/// 外层页边距由调用方（如 [M3ESliverSearchBar.padding]）提供；本组件关闭
/// [M3ESearchBar] 默认侧向 margin，避免与页边距叠两次。
class ManagementFacetSearchBar extends StatelessWidget {
  const ManagementFacetSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.focusNode,
  });

  /// 非 compact 最大宽度（短于 MD3E 默认 720，贴近筛选条视觉比重）。
  static const double maxWidth = 360;

  /// 容器高度（低于 MD3E 默认 56）。
  static const double height = 40;

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final bool compact = windowSizeClassOf(context).isCompact;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3ESearchBarTheme denseBarTheme = theme.searchBarTheme.copyWith(
      minHeight: height,
      maxWidth: maxWidth,
      tapTargetSize: 32,
      leadingSpace: 2,
      trailingSpace: 2,
    );
    final TextStyle denseLabel = theme.typeScale.bodyMedium.copyWith(
      color: theme.colorScheme.onSurface,
    );
    final TextStyle denseHint = theme.typeScale.bodyMedium.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return M3ETheme(
      data: theme.copyWith(searchBarTheme: denseBarTheme),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double available = constraints.maxWidth;
          final double barWidth = compact
              ? available
              : math.min(maxWidth, available);
          return Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(
              width: barWidth,
              height: height,
              child: M3ESearchBar(
                controller: controller,
                focusNode: focusNode,
                hintText: hintText,
                leading: const Icon(M3EIcons.search, size: 18),
                trailing: null,
                enabled: true,
                expandOnFocus: true,
                showClearButton: true,
                margin: 0,
                focusedMargin: 0,
                textStyle: WidgetStatePropertyAll<TextStyle>(denseLabel),
                hintStyle: WidgetStatePropertyAll<TextStyle>(denseHint),
                constraints: BoxConstraints(
                  minWidth: barWidth,
                  maxWidth: barWidth,
                  minHeight: height,
                  maxHeight: height,
                ),
                onChanged: onChanged,
              ),
            ),
          );
        },
      ),
    );
  }
}
