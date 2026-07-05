import 'package:hentai_library/domain/reading/reading_mode.dart';

/// Spread 索引与页码映射（页码均为 1-based）。
class SpreadIndex {
  const SpreadIndex._();

  static int totalSpreads({
    required ReadingMode mode,
    required int totalPages,
  }) {
    if (totalPages <= 0) {
      return 0;
    }
    return switch (mode) {
      ReadingMode.paged || ReadingMode.continuousVertical => totalPages,
      ReadingMode.dualPage => (totalPages + 1) ~/ 2,
      ReadingMode.dualPageNoCover =>
        totalPages == 1 ? 1 : 1 + ((totalPages - 1 + 1) ~/ 2),
    };
  }

  /// [spreadIndex] 为 0-based spread 序号。
  static List<int> pagesInSpread({
    required ReadingMode mode,
    required int totalPages,
    required int spreadIndex,
  }) {
    if (totalPages <= 0 || spreadIndex < 0) {
      return const <int>[];
    }
    final int maxSpread = totalSpreads(
      mode: mode,
      totalPages: totalPages,
    );
    if (spreadIndex >= maxSpread) {
      return const <int>[];
    }
    return switch (mode) {
      ReadingMode.paged || ReadingMode.continuousVertical => <int>[
        spreadIndex + 1,
      ],
      ReadingMode.dualPage => _dualPageSpread(
        totalPages: totalPages,
        spreadIndex: spreadIndex,
      ),
      ReadingMode.dualPageNoCover => _dualPageNoCoverSpread(
        totalPages: totalPages,
        spreadIndex: spreadIndex,
      ),
    };
  }

  static int spreadIndexForPage({
    required ReadingMode mode,
    required int totalPages,
    required int pageIndex,
  }) {
    if (totalPages <= 0 || pageIndex < 1 || pageIndex > totalPages) {
      return 0;
    }
    return switch (mode) {
      ReadingMode.paged || ReadingMode.continuousVertical => pageIndex - 1,
      ReadingMode.dualPage => (pageIndex - 1) ~/ 2,
      ReadingMode.dualPageNoCover =>
        pageIndex == 1 ? 0 : 1 + ((pageIndex - 2) ~/ 2),
    };
  }

  static int primaryPageForSpread({
    required ReadingMode mode,
    required int totalPages,
    required int spreadIndex,
  }) {
    final List<int> pages = pagesInSpread(
      mode: mode,
      totalPages: totalPages,
      spreadIndex: spreadIndex,
    );
    if (pages.isEmpty) {
      return 1;
    }
    return pages.first;
  }

  static List<int> _dualPageSpread({
    required int totalPages,
    required int spreadIndex,
  }) {
    final int left = spreadIndex * 2 + 1;
    if (left > totalPages) {
      return const <int>[];
    }
    final int right = left + 1;
    if (right > totalPages) {
      return <int>[left];
    }
    return <int>[left, right];
  }

  static List<int> _dualPageNoCoverSpread({
    required int totalPages,
    required int spreadIndex,
  }) {
    if (spreadIndex == 0) {
      return <int>[1];
    }
    final int left = spreadIndex * 2;
    if (left > totalPages) {
      return const <int>[];
    }
    final int right = left + 1;
    if (right > totalPages) {
      return <int>[left];
    }
    return <int>[left, right];
  }
}
