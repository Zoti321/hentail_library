import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Remembers the Series a Comic detail was opened from, so back can return
/// there after Read session exit replaces the stack (issue #83 / ADR-0005).
final comicDetailReturnSeriesProvider =
    NotifierProvider<ComicDetailReturnSeries, String?>(
      ComicDetailReturnSeries.new,
    );

class ComicDetailReturnSeries extends Notifier<String?> {
  @override
  String? build() => null;

  void remember(String seriesId) {
    final String normalized = seriesId.trim();
    state = normalized.isEmpty ? null : normalized;
  }

  void clear() {
    if (state == null) {
      return;
    }
    state = null;
  }
}

/// Best-effort clear when [context] may sit outside a [ProviderScope].
void clearComicDetailReturnSeriesFromContext(BuildContext context) {
  try {
    ProviderScope.containerOf(
      context,
    ).read(comicDetailReturnSeriesProvider.notifier).clear();
  } catch (_) {}
}
