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
      ReadingMode.paged || ReadingMode.webtoon => totalPages,
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
    final int maxSpread = totalSpreads(mode: mode, totalPages: totalPages);
    if (spreadIndex >= maxSpread) {
      return const <int>[];
    }
    return switch (mode) {
      ReadingMode.paged || ReadingMode.webtoon => <int>[spreadIndex + 1],
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

  static int spreadIndexForPage({
    required ReadingMode mode,
    required int totalPages,
    required int pageIndex,
  }) {
    if (totalPages <= 0 || pageIndex < 1 || pageIndex > totalPages) {
      return 0;
    }
    return switch (mode) {
      ReadingMode.paged || ReadingMode.webtoon => pageIndex - 1,
      ReadingMode.dualPage => (pageIndex - 1) ~/ 2,
      ReadingMode.dualPageNoCover =>
        pageIndex == 1 ? 0 : 1 + ((pageIndex - 2) ~/ 2),
    };
  }

  /// 按 spread 前进，返回下一 spread 的主页码；无法前进时返回 null。
  static int? nextPrimaryPage({
    required ReadingMode mode,
    required int totalPages,
    required int currentPageIndex,
  }) {
    if (totalPages <= 0 || currentPageIndex < 1) {
      return null;
    }
    if (!mode.usesSpreadNavigation) {
      final int next = currentPageIndex + 1;
      return next <= totalPages ? next : null;
    }
    final int spread = spreadIndexForPage(
      mode: mode,
      totalPages: totalPages,
      pageIndex: currentPageIndex,
    );
    final int totalSpreadsCount = totalSpreads(
      mode: mode,
      totalPages: totalPages,
    );
    if (spread + 1 >= totalSpreadsCount) {
      return null;
    }
    return primaryPageForSpread(
      mode: mode,
      totalPages: totalPages,
      spreadIndex: spread + 1,
    );
  }

  /// 按 spread 后退，返回上一 spread 的主页码；无法后退时返回 null。
  static int? previousPrimaryPage({
    required ReadingMode mode,
    required int totalPages,
    required int currentPageIndex,
  }) {
    if (totalPages <= 0 || currentPageIndex < 1) {
      return null;
    }
    if (!mode.usesSpreadNavigation) {
      final int prev = currentPageIndex - 1;
      return prev >= 1 ? prev : null;
    }
    final int spread = spreadIndexForPage(
      mode: mode,
      totalPages: totalPages,
      pageIndex: currentPageIndex,
    );
    if (spread <= 0) {
      return null;
    }
    return primaryPageForSpread(
      mode: mode,
      totalPages: totalPages,
      spreadIndex: spread - 1,
    );
  }

  static bool isOnLastSpread({
    required ReadingMode mode,
    required int totalPages,
    required int currentPageIndex,
  }) {
    if (totalPages <= 0 || currentPageIndex < 1) {
      return true;
    }
    if (!mode.usesSpreadNavigation) {
      return currentPageIndex >= totalPages;
    }
    final int spread = spreadIndexForPage(
      mode: mode,
      totalPages: totalPages,
      pageIndex: currentPageIndex,
    );
    return spread >= totalSpreads(mode: mode, totalPages: totalPages) - 1;
  }

  /// 阅读器会话内切换模式时，将当前页码映射到新模式的页码。
  static int remapPageForModeSwitch({
    required ReadingMode fromMode,
    required ReadingMode toMode,
    required int currentPageIndex,
    required int totalPages,
  }) {
    if (totalPages <= 0) {
      return 1;
    }
    final int clamped = currentPageIndex.clamp(1, totalPages);
    if (fromMode.isDualPageMode && !toMode.isDualPageMode) {
      final int spread = spreadIndexForPage(
        mode: fromMode,
        totalPages: totalPages,
        pageIndex: clamped,
      );
      final List<int> pages = pagesInSpread(
        mode: fromMode,
        totalPages: totalPages,
        spreadIndex: spread,
      );
      if (pages.isEmpty) {
        return clamped;
      }
      return pages.last;
    }
    return clamped;
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
