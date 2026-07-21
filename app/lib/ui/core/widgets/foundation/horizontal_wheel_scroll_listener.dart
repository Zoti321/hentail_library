import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// 将垂直滚轮增量转为横向滚动；到达边界时不消费事件，交由外层纵向滚动。
class HorizontalWheelScrollListener extends StatelessWidget {
  const HorizontalWheelScrollListener({
    super.key,
    required this.controller,
    required this.child,
  });

  final ScrollController controller;
  final Widget child;

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) {
      return;
    }
    if (!controller.hasClients) {
      return;
    }
    final double currentOffset = controller.offset;
    final double minOffset = controller.position.minScrollExtent;
    final double maxOffset = controller.position.maxScrollExtent;
    final bool isScrollingForward = event.scrollDelta.dy > 0;
    final bool isAtLeadingEdge = currentOffset <= minOffset;
    final bool isAtTrailingEdge = currentOffset >= maxOffset;
    if ((isScrollingForward && isAtTrailingEdge) ||
        (!isScrollingForward && isAtLeadingEdge)) {
      return;
    }
    GestureBinding.instance.pointerSignalResolver.register(event, (
      PointerSignalEvent resolvedEvent,
    ) {
      final PointerScrollEvent pointerScrollEvent =
          resolvedEvent as PointerScrollEvent;
      final double nextOffset =
          (controller.offset + pointerScrollEvent.scrollDelta.dy).clamp(
            minOffset,
            maxOffset,
          );
      if (nextOffset == controller.offset) {
        return;
      }
      controller.jumpTo(nextOffset);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: _handlePointerSignal,
      child: child,
    );
  }
}
