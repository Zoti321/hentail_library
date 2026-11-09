import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/reading_stats/application/record_read_session_activity.dart';
import 'package:hentai_library/features/reading_stats/domain/reading_activity_stats_repository.dart';
import 'package:hentai_library/shared/domain/library/reading_activity_stats.dart';

void main() {
  test('skips repository when neither duration nor finished applies', () async {
    final _FakeRepo repo = _FakeRepo();
    final RecordReadSessionActivity useCase = RecordReadSessionActivity(repo);

    await useCase.record(
      comicId: 'c1',
      incognito: false,
      foregroundElapsed: const Duration(seconds: 3),
      pageIndex: 1,
      pageCount: 10,
    );

    expect(repo.calls, isEmpty);
  });

  test('records full duration and finished mark when rules match', () async {
    final _FakeRepo repo = _FakeRepo();
    final RecordReadSessionActivity useCase = RecordReadSessionActivity(repo);

    await useCase.record(
      comicId: 'c1',
      incognito: false,
      foregroundElapsed: const Duration(seconds: 30),
      pageIndex: 10,
      pageCount: 10,
    );

    expect(repo.calls, hasLength(1));
    expect(repo.calls.single.comicId, 'c1');
    expect(repo.calls.single.addDuration, const Duration(seconds: 30));
    expect(repo.calls.single.markFinished, isTrue);
  });

  test('incognito records nothing', () async {
    final _FakeRepo repo = _FakeRepo();
    final RecordReadSessionActivity useCase = RecordReadSessionActivity(repo);

    await useCase.record(
      comicId: 'c1',
      incognito: true,
      foregroundElapsed: const Duration(seconds: 30),
      pageIndex: 10,
      pageCount: 10,
    );

    expect(repo.calls, isEmpty);
  });
}

final class _Call {
  const _Call({
    required this.comicId,
    required this.addDuration,
    required this.markFinished,
  });

  final String comicId;
  final Duration? addDuration;
  final bool markFinished;
}

final class _FakeRepo implements ReadingActivityStatsRepository {
  final List<_Call> calls = <_Call>[];

  @override
  Stream<ReadingActivityStats> watchActivityStats() =>
      const Stream<ReadingActivityStats>.empty();

  @override
  Future<void> recordSessionActivity({
    required String comicId,
    Duration? addDuration,
    required bool markFinished,
  }) async {
    calls.add(
      _Call(
        comicId: comicId,
        addDuration: addDuration,
        markFinished: markFinished,
      ),
    );
  }
}
