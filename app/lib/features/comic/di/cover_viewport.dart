import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cover_viewport.g.dart';

/// Stable scope keys for [coverViewportProvider].
abstract final class CoverViewportScopes {
  static const String library = 'library';

  static String seriesDetail(String seriesId) => 'series-detail:$seriesId';

  static const String readingHistory = 'reading-history';
}

/// Visible catalog-cover indices for a scrollable scope (grid/list).
@Riverpod(keepAlive: true)
class CoverViewport extends _$CoverViewport {
  final Set<int> _pendingAdd = <int>{};
  final Set<int> _pendingRemove = <int>{};
  bool _flushScheduled = false;

  @override
  Set<int> build(String scope) {
    ref.onDispose(() {
      _pendingAdd.clear();
      _pendingRemove.clear();
      _flushScheduled = false;
    });
    return const <int>{};
  }

  void report(int index, bool visible) {
    if (visible) {
      _pendingRemove.remove(index);
      _pendingAdd.add(index);
    } else {
      _pendingAdd.remove(index);
      _pendingRemove.add(index);
    }
    _scheduleFlush();
  }

  void clear() {
    _pendingAdd.clear();
    _pendingRemove.clear();
    if (state.isNotEmpty) {
      state = const <int>{};
    }
  }

  void _scheduleFlush() {
    if (_flushScheduled) {
      return;
    }
    _flushScheduled = true;
    scheduleMicrotask(() {
      _flushScheduled = false;
      if (!ref.mounted) {
        return;
      }
      final Set<int> next = Set<int>.of(state);
      next
        ..addAll(_pendingAdd)
        ..removeAll(_pendingRemove);
      _pendingAdd.clear();
      _pendingRemove.clear();
      if (!_sameIndices(next, state)) {
        state = next;
      }
    });
  }

  static bool _sameIndices(Set<int> a, Set<int> b) {
    if (identical(a, b) || (a.isEmpty && b.isEmpty)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    return a.containsAll(b);
  }
}

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
