import 'package:hentai_library/domain/entity/reading_history.dart' as entity;
import 'package:hentai_library/presentation/providers/deps/deps.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_page_notifier.g.dart';

/// 阅读统计结果：热力图数据、总时长、有阅读天数、日均时长
class ReadingStats {
  const ReadingStats({
    required this.heatmapData,
    required this.totalSeconds,
    required this.daysWithReading,
  });

  final Map<DateTime, int> heatmapData;
  final int totalSeconds;
  final int daysWithReading;

  int get averageSecondsPerDay =>
      daysWithReading > 0 ? totalSeconds ~/ daysWithReading : 0;
}

@Riverpod(keepAlive: true)
Stream<List<entity.ReadingHistory>> readingHistoryStream(Ref ref) {
  return ref.watch(readingHistoryRepoProvider).watchAllHistory();
}

@Riverpod(keepAlive: true)
Future<ReadingStats> readingStats(Ref ref) async {
  final repo = ref.read(readingSessionRepoProvider);
  await repo.clearExpiredSessions();

  const rangeDays = 365;
  final end = DateTime.now();
  final start = end.subtract(const Duration(days: rangeDays));
  final sessions = await repo.getSessionsInRange(start, end);

  final Map<DateTime, int> heatmapData = {};
  var totalSeconds = 0;

  for (final s in sessions) {
    final day = DateTime(s.date.year, s.date.month, s.date.day);
    heatmapData[day] = (heatmapData[day] ?? 0) + s.durationSeconds;
    totalSeconds += s.durationSeconds;
  }

  return ReadingStats(
    heatmapData: heatmapData,
    totalSeconds: totalSeconds,
    daysWithReading: heatmapData.length,
  );
}
