import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/motion/md3e_effects_decorated_box.dart';
import 'package:hentai_library/md3e/widgets/lists/md3e_reorder_index.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_tonal_surface.dart';
import 'package:material_3_expressive/components/lists/components/m3e_list_drag_proxy_scope.dart';
import 'package:material_3_expressive/components/lists/components/m3e_list_reorder_exclude.dart';
import 'package:material_3_expressive/components/lists/components/m3e_list_reorder_host.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

const double kMd3eSplitListInnerRadius = 4;
const double kMd3eSplitListRowGap = 4;

/// One row inside [Md3eSplitListGroup]; animates corner radius on press.
///
/// 处于 [M3EListReorderHost] 拖拽浮层中时，颜色与圆角跟随 [M3EListDragProxyScope]，
/// 与 [M3EList] 的拖拽外观一致。
class Md3eSplitListRow extends StatefulWidget {
  const Md3eSplitListRow({
    super.key,
    required this.child,
    this.topRadius = kMd3eSplitListInnerRadius,
    this.bottomRadius = kMd3eSplitListInnerRadius,
    this.pressedRadius = kMd3eTonalSurfaceRadius,
    this.onTap,
  });

  final Widget child;
  final double topRadius;
  final double bottomRadius;
  final double pressedRadius;
  final VoidCallback? onTap;

  static ValueChanged<bool>? pressReporterOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_Md3eSplitRowScope>()
        ?.onPressChanged;
  }

  @override
  State<Md3eSplitListRow> createState() => _Md3eSplitListRowState();
}

class _Md3eSplitListRowState extends State<Md3eSplitListRow> {
  bool _pressed = false;

  void _reportPress(bool pressed) => setState(() => _pressed = pressed);

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme colors = M3ETheme.of(context).colorScheme;
    final M3EListDragProxyScope? dragProxy = M3EListDragProxyScope.maybeOf(
      context,
    );
    final Widget child = widget.onTap == null
        ? widget.child
        : InkWell(
            onTap: widget.onTap,
            onHighlightChanged: _reportPress,
            child: widget.child,
          );

    final double topRadius =
        dragProxy?.radius ??
        (_pressed ? widget.pressedRadius : widget.topRadius);
    final double bottomRadius =
        dragProxy?.radius ??
        (_pressed ? widget.pressedRadius : widget.bottomRadius);

    return Md3eEffectsDecoratedBox(
      decoration: BoxDecoration(
        color: dragProxy?.color ?? colors.surfaceContainerLow,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(topRadius),
          bottom: Radius.circular(bottomRadius),
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: _Md3eSplitRowScope(onPressChanged: _reportPress, child: child),
      ),
    );
  }
}

class _Md3eSplitRowScope extends InheritedWidget {
  const _Md3eSplitRowScope({
    required this.onPressChanged,
    required super.child,
  });

  final ValueChanged<bool> onPressChanged;

  @override
  bool updateShouldNotify(_Md3eSplitRowScope oldWidget) => false;
}

/// Stacked settings rows with outer 24dp radius and 4dp gutters.
class Md3eSplitListGroup extends StatelessWidget {
  const Md3eSplitListGroup({
    super.key,
    required this.children,
    this.outerRadius = kMd3eTonalSurfaceRadius,
  });

  final List<Widget> children;
  final double outerRadius;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < children.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: kMd3eSplitListRowGap),
          Md3eSplitListRow(
            topRadius: i == 0 ? outerRadius : kMd3eSplitListInnerRadius,
            bottomRadius: i == children.length - 1
                ? outerRadius
                : kMd3eSplitListInnerRadius,
            pressedRadius: outerRadius,
            child: children[i],
          ),
        ],
      ],
    );
  }
}

/// 可拖拽排序的分段列表：长按行拖动，视觉与 [Md3eSplitListGroup] 一致。
///
/// 拖拽机制复用 [M3EListReorderHost]（与 [M3EList] 相同的长按、浮层、占位与回落动画）。
/// [itemBuilder] 只需返回行内容，分段圆角、间距与拖拽外观由本组件提供。
/// 行内的按钮、开关等交互控件应包在 [M3EListReorderExclude] 中，否则长按它们会开始拖拽。
///
/// [onReorder] 使用 Flutter [ReorderCallback] 约定（与 [ReorderableListView] 一致）。
class Md3eReorderableSplitListGroup extends StatelessWidget {
  const Md3eReorderableSplitListGroup({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.onReorder,
    this.outerRadius = kMd3eTonalSurfaceRadius,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ReorderCallback onReorder;
  final double outerRadius;

  @override
  Widget build(BuildContext context) {
    return M3EListReorderHost(
      itemCount: itemCount,
      gap: kMd3eSplitListRowGap,
      reorderState: const M3EListReorderState(showDragHandle: false),
      onReorder: (int from, int to) =>
          onReorder(from, md3eReorderTargetToFlutterNewIndex(from, to)),
      itemBuilder: (BuildContext context, int index) {
        final bool first = index == 0;
        final bool last = index == itemCount - 1;
        // 宽度拉满：M3EListReorderHost 内部的 Column 不会拉伸子项。
        return SizedBox(
          width: double.infinity,
          child: Md3eSplitListRow(
            topRadius: first ? outerRadius : kMd3eSplitListInnerRadius,
            bottomRadius: last ? outerRadius : kMd3eSplitListInnerRadius,
            pressedRadius: outerRadius,
            child: itemBuilder(context, index),
          ),
        );
      },
    );
  }
}
