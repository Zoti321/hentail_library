import 'package:hentai_library/features/series/public/serialization_status.dart';
import 'package:hentai_library/features/series/domain/series.dart';
import 'package:hentai_library/features/series/domain/value_objects/series_metadata_form.dart';
import 'package:test/test.dart';

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
  group('SeriesMetadataForm.diffAgainst', () {
    test('validates all fields before parsing changes', () {
      final diff = SeriesMetadataForm(
        name: ' ',
        serializationStatus: SerializationStatus.ended,
        totalCountText: 'bad',
      ).diffAgainst(_series());
      expect(diff, isA<SeriesMetadataDraftInvalid>());
      final invalid = diff as SeriesMetadataDraftInvalid;
      expect(invalid.validation.nameError, isNotNull);
      expect(invalid.validation.totalCountError, isNotNull);
    });

    test('trimmed names and equivalent numeric text produce no changes', () {
      final original = _series();
      final diff = SeriesMetadataForm.fromSeries(original)
          .copyWith(name: ' 原系列 ', totalCountText: ' 012 ')
          .diffAgainst(original);
      expect(diff, isA<SeriesMetadataDraftUnchanged>());
    });

    test('changed fields form one patch and blank count distinguishes clear from unchanged', () {
      final original = _series();
      final diff = SeriesMetadataForm(
        name: ' 新名 ',
        serializationStatus: SerializationStatus.ended,
        totalCountText: '8',
      ).diffAgainst(original) as SeriesMetadataDraftChanges;
      expect(diff.name, '新名');
      expect(diff.serializationStatus, SerializationStatus.ended);
      expect(diff.totalCount, 8);
      expect(diff.clearTotalCount, isFalse);

      final cleared =
          SeriesMetadataForm.fromSeries(original)
                  .copyWith(totalCountText: ' ')
                  .diffAgainst(original)
              as SeriesMetadataDraftChanges;
      expect(cleared.name, isNull);
      expect(cleared.totalCount, isNull);
      expect(cleared.clearTotalCount, isTrue);
      final noCount = _series(totalCount: null);
      expect(
        SeriesMetadataForm.fromSeries(noCount).diffAgainst(noCount),
        isA<SeriesMetadataDraftUnchanged>(),
      );
    });
  });
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
    for (final count in [2147483648, 4294967297]) {
      test(
        'rejects a planned count that cannot be persisted exactly: $count',
        () {
          final form = SeriesMetadataForm(
            name: 'Series',
            serializationStatus: SerializationStatus.ongoing,
            totalCountText: '$count',
          );
          expect(form.validate().totalCountError, isNotNull);
          expect(
            form.diffAgainst(_series()),
            isA<SeriesMetadataDraftInvalid>(),
          );
        },
      );
    }

    test('accepts the largest supported count without changing its value', () {
      final form = SeriesMetadataForm(
        name: 'Series',
        serializationStatus: SerializationStatus.ongoing,
        totalCountText: '2147483647',
      );
      expect(form.validate().isValid, isTrue);
      final diff = form.diffAgainst(_series()) as SeriesMetadataDraftChanges;
      expect(diff.totalCount, 2147483647);
    });

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
}
