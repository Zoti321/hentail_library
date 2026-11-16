import 'dart:async';

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
