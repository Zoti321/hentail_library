import 'package:test/test.dart';
import 'package:hentai_library/features/series/domain/value_objects/serialization_status.dart';
import 'package:hentai_library/features/series/domain/series.dart';
import 'package:hentai_library/features/series/domain/value_objects/series_metadata_form.dart';
import 'package:hentai_library/features/series/domain/series_repository.dart';
import 'package:hentai_library/features/series/application/series_metadata_service.dart';

class _RecordingSeriesRepository implements SeriesRepository {
  String? seriesId;
  String? name;
  SerializationStatus? serializationStatus;
  int? totalCount;
  bool? clearTotalCount;
  int callCount = 0;
  bool fail = false;

  @override
  Future<void> updateUserMeta({
    required String seriesId,
    String? name,
    SerializationStatus? serializationStatus,
    int? totalCount,
    bool clearTotalCount = false,
  }) async {
    callCount += 1;
    if (fail) throw StateError('write');
    this.seriesId = seriesId;
    this.name = name;
    this.serializationStatus = serializationStatus;
    this.totalCount = totalCount;
    this.clearTotalCount = clearTotalCount;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Series _series({
  String name = '原系列',
  SerializationStatus status = SerializationStatus.ongoing,
  int? totalCount = 12,
}) {
  return Series(
    id: 'series-1',
    name: name,
    folderPath: '/library/series-1',
    serializationStatus: status,
    totalCount: totalCount,
  );
}

void main() {
  test(
    'an unsupported planned count prevents the whole metadata write',
    () async {
      final repo = _RecordingSeriesRepository();
      final result = await applySeriesMetadataForm(
        repo,
        SeriesMetadataForm(
          name: 'Changed name',
          serializationStatus: SerializationStatus.ended,
          totalCountText: '4294967297',
        ),
        _series(),
      );
      expect(result, isA<SeriesMetadataApplyInvalid>());
      expect(repo.callCount, 0);
    },
  );

  test('write failure propagates after one attempt', () async {
    final repo = _RecordingSeriesRepository()..fail = true;
    final original = _series();
    await expectLater(
      applySeriesMetadataForm(
        repo,
        SeriesMetadataForm.fromSeries(original).copyWith(name: 'new'),
        original,
      ),
      throwsStateError,
    );
    expect(repo.callCount, 1);
  });
  group('applySeriesMetadataForm', () {
    test('returns Invalid and does not call repository', () async {
      final _RecordingSeriesRepository repo = _RecordingSeriesRepository();
      final SeriesMetadataApplyResult result = await applySeriesMetadataForm(
        repo,
        SeriesMetadataForm(
          name: '',
          serializationStatus: SerializationStatus.ongoing,
          totalCountText: 'x',
        ),
        _series(),
      );

      expect(result, isA<SeriesMetadataApplyInvalid>());
      expect(repo.callCount, 0);
      final SeriesMetadataApplyInvalid invalid =
          result as SeriesMetadataApplyInvalid;
      expect(invalid.validation.nameError, isNotNull);
      expect(invalid.validation.totalCountError, isNotNull);
    });

    test('only submits changed serialization status', () async {
      final _RecordingSeriesRepository repo = _RecordingSeriesRepository();
      final Series original = _series(
        name: '原系列',
        status: SerializationStatus.ongoing,
        totalCount: 12,
      );
      final SeriesMetadataApplyResult result = await applySeriesMetadataForm(
        repo,
        SeriesMetadataForm.fromSeries(original)
            .copyWith(serializationStatus: SerializationStatus.ended),
        original,
      );

      expect(result, isA<SeriesMetadataApplySucceeded>());
      expect(repo.callCount, 1);
      expect(repo.seriesId, 'series-1');
      expect(repo.name, isNull);
      expect(repo.serializationStatus, SerializationStatus.ended);
      expect(repo.totalCount, isNull);
      expect(repo.clearTotalCount, isFalse);
    });

    test(
      'does not clear totalCount when already empty and unchanged',
      () async {
        final _RecordingSeriesRepository repo = _RecordingSeriesRepository();
        final Series original = _series(totalCount: null);
        final SeriesMetadataApplyResult result = await applySeriesMetadataForm(
          repo,
          SeriesMetadataForm.fromSeries(original),
          original,
        );

        expect(result, isA<SeriesMetadataApplySucceeded>());
        expect(repo.callCount, 0);
      },
    );

    test('sets totalCount when text is a positive integer', () async {
      final _RecordingSeriesRepository repo = _RecordingSeriesRepository();
      final Series original = _series(
        name: '旧名',
        status: SerializationStatus.ongoing,
        totalCount: 3,
      );
      final SeriesMetadataApplyResult result = await applySeriesMetadataForm(
        repo,
        SeriesMetadataForm(
          name: ' 新系列 ',
          serializationStatus: SerializationStatus.ended,
          totalCountText: '8',
        ),
        original,
      );

      expect(result, isA<SeriesMetadataApplySucceeded>());
      expect(repo.callCount, 1);
      expect(repo.seriesId, 'series-1');
      expect(repo.name, '新系列');
      expect(repo.serializationStatus, SerializationStatus.ended);
      expect(repo.totalCount, 8);
      expect(repo.clearTotalCount, isFalse);
    });

    test('clears totalCount when text becomes empty', () async {
      final _RecordingSeriesRepository repo = _RecordingSeriesRepository();
      final Series original = _series(
        name: '系列',
        status: SerializationStatus.ongoing,
        totalCount: 12,
      );
      final SeriesMetadataApplyResult result = await applySeriesMetadataForm(
        repo,
        SeriesMetadataForm.fromSeries(original).copyWith(totalCountText: ''),
        original,
      );

      expect(result, isA<SeriesMetadataApplySucceeded>());
      expect(repo.callCount, 1);
      expect(repo.name, isNull);
      expect(repo.totalCount, isNull);
      expect(repo.clearTotalCount, isTrue);
    });
  });
}
