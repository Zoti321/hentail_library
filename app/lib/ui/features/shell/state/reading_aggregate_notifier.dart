import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/reading_history.dart';
import 'package:hentai_library/domain/models/entity/series_reading_history.dart';
import 'package:hentai_library/domain/reading/read_session.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reading_aggregate_notifier.g.dart';

class _ActiveReadingSession {
  _ActiveReadingSession({
    required this.comic,
    required this.mode,
    required this.seriesId,
    required this.pageIndex,
  });

  final Comic comic;
  final ReadSessionMode mode;
  final String? seriesId;
  int pageIndex;
}

/// 阅读进度写入：UI 仅通过 session 生命周期 API 交互。
@Riverpod(keepAlive: true)
class ReadingAggregateNotifier extends _$ReadingAggregateNotifier {
  _ActiveReadingSession? _session;
  Future<void>? _flushInFlight;

  @override
  int build() => 0;

  bool get hasActiveSession => _session != null;

  Future<void> beginSession({
    required Comic comic,
    required ReadSessionMode mode,
    String? seriesId,
    bool incognito = false,
    int initialPageIndex = 1,
  }) async {
    if (incognito) {
      _session = null;
      return;
    }
    final String? resolvedSeriesId = _normalizeSeriesId(
      mode == ReadSessionMode.series ? seriesId : null,
    );
    if (_session != null && _session!.comic.comicId != comic.comicId) {
      await _flushSession(_session!);
    }
    _session = _ActiveReadingSession(
      comic: comic,
      mode: mode,
      seriesId: resolvedSeriesId,
      pageIndex: initialPageIndex.clamp(1, 1 << 30),
    );
    await _flushSession(_session!);
  }

  void updatePage(int pageIndex) {
    if (_session == null || pageIndex < 1) {
      return;
    }
    _session!.pageIndex = pageIndex;
  }

  Future<void> flushProgress() async {
    final _ActiveReadingSession? session = _session;
    if (session == null) {
      return;
    }
    await _flushSession(session);
  }

  Future<void> endSession() async {
    final _ActiveReadingSession? session = _session;
    if (session == null) {
      return;
    }
    _session = null;
    await _flushSession(session);
  }

  Future<void> _flushSession(_ActiveReadingSession session) async {
    final Future<void>? inFlight = _flushInFlight;
    if (inFlight != null) {
      await inFlight;
    }
    final Future<void> flushTask = _persistSession(session);
    _flushInFlight = flushTask;
    try {
      await flushTask;
    } finally {
      if (identical(_flushInFlight, flushTask)) {
        _flushInFlight = null;
      }
    }
  }

  Future<void> _persistSession(_ActiveReadingSession session) async {
    final DateTime now = DateTime.now();
    await ref.read(readingHistoryRepoProvider).recordReading(
      ReadingHistory(
        comicId: session.comic.comicId,
        title: session.comic.title,
        lastReadTime: now,
        pageIndex: session.pageIndex,
      ),
    );
    final String? seriesId = session.seriesId;
    if (seriesId == null || seriesId.isEmpty) {
      return;
    }
    await ref.read(seriesReadingHistoryRepoProvider).recordSeriesReading(
      SeriesReadingHistory(
        seriesId: seriesId,
        lastReadComicId: session.comic.comicId,
        lastReadTime: now,
        pageIndex: session.pageIndex,
      ),
    );
  }

  String? _normalizeSeriesId(String? seriesId) {
    final String? trimmed = seriesId?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
