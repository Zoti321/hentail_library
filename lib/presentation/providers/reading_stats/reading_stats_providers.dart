import 'package:hentai_library/data/repository/reading_session_repo.dart';
import 'package:hentai_library/domain/repository/reading_session_repo.dart'
    as domain;
import 'package:hentai_library/domain/usecases/usecases.dart';
import 'package:hentai_library/presentation/providers/v2/deps/deps.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reading_stats_providers.g.dart';

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
domain.ReadingSessionRepository readingSessionRepo(Ref ref) {
  return ReadingSessionRepositoryImpl(ref.read(readingSessionDaoProvider));
}

@Riverpod(keepAlive: true)
RecordReadingSessionUseCase recordReadingSessionUseCase(Ref ref) {
  return RecordReadingSessionUseCase(ref.read(readingSessionRepoProvider));
}

/// 当前阅读页的会话开始时间（进入阅读页时设置，退出时用于计算时长并清除）
@Riverpod(keepAlive: true)
class ReadingSessionStart extends _$ReadingSessionStart {
  @override
  DateTime? build() => null;

  void setStartedAt(DateTime? value) => state = value;
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
