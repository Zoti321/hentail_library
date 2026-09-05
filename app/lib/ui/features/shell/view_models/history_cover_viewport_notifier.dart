import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// History 网格中应使用 high 优先级加载封面的索引集合（对齐 catalog 视口分级）。
final historyCoverViewportProvider =
    NotifierProvider<HistoryCoverViewport, Set<int>>(HistoryCoverViewport.new);

class HistoryCoverViewport extends Notifier<Set<int>> {
  @override
  Set<int> build() => const <int>{};

  void updateRange({required int startIndex, required int endIndex}) {
    if (endIndex < startIndex) {
      if (state.isEmpty) {
        return;
      }
      state = const <int>{};
      return;
    }
    final Set<int> next = <int>{for (int i = startIndex; i <= endIndex; i++) i};
    if (setEquals(next, state)) {
      return;
    }
    state = next;
  }

  void clear() {
    if (state.isEmpty) {
      return;
    }
    state = const <int>{};
  }
}
