import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_query.g.dart';

// 搜索关键词
@riverpod
class SearchLibraryNotifier extends _$SearchLibraryNotifier {
  Timer? _debounceTimer;

  @override
  String build() {
    return '';
  }

  void update(String newValue) {
    _debounceTimer?.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      state = newValue;
    });
  }

  void clear() {
    state = '';
  }
}

@riverpod
class SearchMergeNotifier extends _$SearchMergeNotifier {
  Timer? _debounceTimer;

  @override
  String build() {
    return '';
  }

  void update(String newValue) {
    _debounceTimer?.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      state = newValue;
    });
  }

  void clear() {
    state = '';
  }
}
