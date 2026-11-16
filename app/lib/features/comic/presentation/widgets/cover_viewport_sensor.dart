import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hentai_library/features/comic/presentation/providers/cover_viewport.dart';

/// Reports [index] visibility into [coverViewportProvider] for [scope].
class CoverViewportSensor extends ConsumerStatefulWidget {
  const CoverViewportSensor({
    super.key,
    required this.scope,
    required this.index,
    required this.child,
  });

  final String scope;
  final int index;
  final Widget child;

  @override
  ConsumerState<CoverViewportSensor> createState() =>
      _CoverViewportSensorState();
}

class _CoverViewportSensorState extends ConsumerState<CoverViewportSensor> {
  ScrollPosition? _position;
  bool? _lastVisible;
  bool _checkScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ScrollPosition? next = Scrollable.maybeOf(context)?.position;
    if (!identical(next, _position)) {
      _position?.isScrollingNotifier.removeListener(_scheduleCheck);
      _position?.removeListener(_scheduleCheck);
      _position = next;
      _position?.addListener(_scheduleCheck);
      _position?.isScrollingNotifier.addListener(_scheduleCheck);
    }
    _scheduleCheck();
  }

  @override
  void didUpdateWidget(covariant CoverViewportSensor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scope != widget.scope || oldWidget.index != widget.index) {
      if (_lastVisible == true) {
        ref
            .read(coverViewportProvider(oldWidget.scope).notifier)
            .report(oldWidget.index, false);
      }
      _lastVisible = null;
      _scheduleCheck();
    }
  }

  @override
  void deactivate() {
    if (_lastVisible == true) {
      ref
          .read(coverViewportProvider(widget.scope).notifier)
          .report(widget.index, false);
      _lastVisible = false;
    }
    super.deactivate();
  }

  @override
  void dispose() {
    _position?.isScrollingNotifier.removeListener(_scheduleCheck);
    _position?.removeListener(_scheduleCheck);
    super.dispose();
  }

  void _scheduleCheck() {
    if (_checkScheduled) {
      return;
    }
    _checkScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScheduled = false;
      if (!mounted) {
        return;
      }
      _publishVisibility(_computeVisible());
    });
  }

  void _publishVisibility(bool visible) {
    if (_lastVisible == visible) {
      return;
    }
    _lastVisible = visible;
    ref
        .read(coverViewportProvider(widget.scope).notifier)
        .report(widget.index, visible);
  }

  bool _computeVisible() {
    final RenderObject? renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return false;
    }
    final ScrollableState? scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) {
      return true;
    }
    final RenderObject? viewportRender = scrollable.context.findRenderObject();
    if (viewportRender is! RenderBox || !viewportRender.hasSize) {
      return true;
    }
    final Offset topLeft = renderObject.localToGlobal(
      Offset.zero,
      ancestor: viewportRender,
    );
    final Rect childRect = topLeft & renderObject.size;
    final Rect viewportRect = Offset.zero & viewportRender.size;
    return childRect.overlaps(viewportRect);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
