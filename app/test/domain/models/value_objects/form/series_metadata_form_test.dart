import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/models/value_objects/form/series_metadata_form.dart';
import 'package:hentai_library/domain/repositories/series_repository.dart';
import 'package:test/test.dart';

class _RecordingSeriesRepository implements SeriesRepository {
  String? seriesId;
  String? name;
  SerializationStatus? serializationStatus;
  int? totalCount;
  bool? clearTotalCount;
  int callCount = 0;

  @override
  Future<void> updateUserMeta({
    required String seriesId,
    String? name,
    SerializationStatus? serializationStatus,
    int? totalCount,
    bool clearTotalCount = false,
  }) async {
    callCount += 1;
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
  group('SeriesMetadataForm.fromSeries', () {
    test('maps name, status, and totalCount text', () {
      final SeriesMetadataForm form = SeriesMetadataForm.fromSeries(
        _series(totalCount: 5),
      );
      expect(form.name, '原系列');
      expect(form.serializationStatus, SerializationStatus.ongoing);
      expect(form.totalCountText, '5');
    });

    test('empty totalCountText when Series has no planned count', () {
      final SeriesMetadataForm form = SeriesMetadataForm.fromSeries(
        _series(totalCount: null),
      );
      expect(form.totalCountText, '');
    });
  });

  group('SeriesMetadataForm.validate', () {
    test('rejects blank name', () {
      final SeriesMetadataFormValidation v = SeriesMetadataForm(
        name: '  ',
        serializationStatus: SerializationStatus.ended,
        totalCountText: '3',
      ).validate();
      expect(v.isValid, isFalse);
      expect(v.nameError, '系列名称不能为空');
      expect(v.totalCountError, isNull);
    });

    test('rejects non-positive totalCount text', () {
      final SeriesMetadataFormValidation v = SeriesMetadataForm(
        name: '系列',
        serializationStatus: SerializationStatus.ended,
        totalCountText: '0',
      ).validate();
      expect(v.isValid, isFalse);
      expect(v.totalCountError, '漫画总数须为正整数，留空表示不设置');
    });

    test('rejects non-integer totalCount text', () {
      final SeriesMetadataFormValidation v = SeriesMetadataForm(
        name: '系列',
        serializationStatus: SerializationStatus.ended,
        totalCountText: 'abc',
      ).validate();
      expect(v.isValid, isFalse);
      expect(v.totalCountError, isNotNull);
    });

    test('reports name and totalCount errors together', () {
      final SeriesMetadataFormValidation v = SeriesMetadataForm(
        name: '',
        serializationStatus: SerializationStatus.unknown,
        totalCountText: '-1',
      ).validate();
      expect(v.nameError, isNotNull);
      expect(v.totalCountError, isNotNull);
    });

    test('accepts empty totalCountText', () {
      final SeriesMetadataFormValidation v = SeriesMetadataForm(
        name: '系列',
        serializationStatus: SerializationStatus.hiatus,
        totalCountText: '  ',
      ).validate();
      expect(v.isValid, isTrue);
    });
  });

  group('SeriesMetadataForm.applyTo', () {
    test('returns Invalid and does not call repository', () async {
      final _RecordingSeriesRepository repo = _RecordingSeriesRepository();
      final SeriesMetadataApplyResult result = await SeriesMetadataForm(
        name: '',
        serializationStatus: SerializationStatus.ongoing,
        totalCountText: 'x',
      ).applyTo(repo, seriesId: 'series-1');

      expect(result, isA<SeriesMetadataApplyInvalid>());
      expect(repo.callCount, 0);
      final SeriesMetadataApplyInvalid invalid =
          result as SeriesMetadataApplyInvalid;
      expect(invalid.validation.nameError, isNotNull);
      expect(invalid.validation.totalCountError, isNotNull);
    });

    test('sets totalCount when text is a positive integer', () async {
      final _RecordingSeriesRepository repo = _RecordingSeriesRepository();
      final SeriesMetadataApplyResult result = await SeriesMetadataForm(
        name: ' 新系列 ',
        serializationStatus: SerializationStatus.ended,
        totalCountText: '8',
      ).applyTo(repo, seriesId: 'series-1');

      expect(result, isA<SeriesMetadataApplySucceeded>());
      expect(repo.callCount, 1);
      expect(repo.seriesId, 'series-1');
      expect(repo.name, '新系列');
      expect(repo.serializationStatus, SerializationStatus.ended);
      expect(repo.totalCount, 8);
      expect(repo.clearTotalCount, isFalse);
    });

    test('clears totalCount idempotently when text is empty', () async {
      final _RecordingSeriesRepository repo = _RecordingSeriesRepository();
      final SeriesMetadataApplyResult result = await SeriesMetadataForm(
        name: '系列',
        serializationStatus: SerializationStatus.ongoing,
        totalCountText: '',
      ).applyTo(repo, seriesId: 'series-1');

      expect(result, isA<SeriesMetadataApplySucceeded>());
      expect(repo.totalCount, isNull);
      expect(repo.clearTotalCount, isTrue);
    });
  });
}
