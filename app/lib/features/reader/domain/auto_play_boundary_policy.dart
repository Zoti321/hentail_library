import 'package:hentai_library/features/reader/domain/auto_play_mode.dart';

/// Decision taken after a full Auto-play interval dwell on the last spread.
sealed class AutoPlayBoundaryDecision {
  const AutoPlayBoundaryDecision();
}

/// Disable autoplay; stay on the last spread.
final class AutoPlayBoundaryStop extends AutoPlayBoundaryDecision {
  const AutoPlayBoundaryStop();
}

/// Jump to page 1 of the current Comic and keep autoplay enabled.
final class AutoPlayBoundaryJumpToFirstPage extends AutoPlayBoundaryDecision {
  const AutoPlayBoundaryJumpToFirstPage();
}

/// Switch to another Comic (Series volume) and keep autoplay enabled.
final class AutoPlayBoundarySwitchComic extends AutoPlayBoundaryDecision {
  const AutoPlayBoundarySwitchComic(this.comicId);

  final String comicId;
}

/// Auto-play 末 spread 边界策略（领域 Policy）。
///
/// [nextComicId] / [firstComicId] 来自 Series reading context；无系列或无邻卷时可为 null。
/// [currentComicId] 避免单卷时无意义切卷。
abstract final class AutoPlayBoundaryPolicy {
  static AutoPlayBoundaryDecision resolve({
    required AutoPlayMode mode,
    required String currentComicId,
    required String? nextComicId,
    required String? firstComicId,
  }) {
    switch (mode) {
      case AutoPlayMode.comicOnce:
        return const AutoPlayBoundaryStop();
      case AutoPlayMode.comicLoop:
        return const AutoPlayBoundaryJumpToFirstPage();
      case AutoPlayMode.seriesOnce:
        final String? next = nextComicId;
        if (next != null && next != currentComicId) {
          return AutoPlayBoundarySwitchComic(next);
        }
        return const AutoPlayBoundaryStop();
      case AutoPlayMode.seriesLoop:
        final String? next = nextComicId;
        if (next != null && next != currentComicId) {
          return AutoPlayBoundarySwitchComic(next);
        }
        final String? first = firstComicId;
        if (first != null && first != currentComicId) {
          return AutoPlayBoundarySwitchComic(first);
        }
        return const AutoPlayBoundaryJumpToFirstPage();
    }
  }
}
