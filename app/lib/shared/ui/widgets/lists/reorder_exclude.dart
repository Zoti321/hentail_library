import 'package:flutter/widgets.dart';

/// 标记不应触发列表拖拽的区域（如行内「更多」按钮、开关）。
///
/// 长按该区域不会开始拖拽；点击仍由控件自身处理。
class Md3eReorderExclude extends StatelessWidget {
  const Md3eReorderExclude({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// [globalPosition] 是否落在 [context] 子树中某个 [Md3eReorderExclude] 区域内。
bool md3eIsPointerInReorderExclude(
  BuildContext context,
  Offset globalPosition,
) {
  bool hit = false;
  void visit(Element element) {
    if (hit) {
      return;
    }
    if (element.widget is Md3eReorderExclude) {
      final RenderObject? renderObject = element.renderObject;
      if (renderObject is RenderBox &&
          renderObject.hasSize &&
          renderObject.attached) {
        final Offset local = renderObject.globalToLocal(globalPosition);
        if ((Offset.zero & renderObject.size).contains(local)) {
          hit = true;
          return;
        }
      }
    }
    element.visitChildren(visit);
  }

  context.visitChildElements(visit);
  return hit;
}
