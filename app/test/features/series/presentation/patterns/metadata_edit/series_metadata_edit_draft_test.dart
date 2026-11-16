import 'package:hentai_library/features/series/domain/value_objects/series_folder_info.dart';
import 'package:hentai_library/features/series/domain/value_objects/series_metadata.dart';
import 'package:hentai_library/features/series/domain/series.dart';
import 'package:hentai_library/features/series/domain/value_objects/series_metadata_form.dart';
import 'package:hentai_library/features/series/presentation/mappers/series_metadata_edit_mappers.dart';
import 'package:hentai_library/features/series/presentation/patterns/metadata_edit/series_metadata_edit_draft.dart';
import 'package:hentai_library/features/series/presentation/views/series_detail/series_detail_view_object.dart';
import 'package:test/test.dart';

void main() {
  test('toForm keeps every edited field and unnormalized input text', () {
    const draft = SeriesMetadataEditDraft(
      name: '  Edited series  ',
      serializationStatus: SerializationStatus.hiatus,
      totalCountText: ' 0007 ',
    );
    final form = draft.toForm();
    expect(form.name, draft.name);
    expect(form.serializationStatus, same(draft.serializationStatus));
    expect(form.totalCountText, draft.totalCountText);
  });

  for (final status in SerializationStatus.values) {
    for (final total in <int?>[null, 7]) {
      test(
        'fromSeries preserves canonical status $status and total $total',
        () {
          final original = Series(
            id: 'series',
            folderInfo: SeriesFolderInfo(folderPath: '/series'),
            metadata: SeriesMetadata(
              name: 'Original',
              serializationStatus: status,
              totalCount: total,
            ),
          );
          final draft = seriesMetadataDraftFromSeries(original);
          expect(draft.name, original.name);
          expect(draft.serializationStatus, same(status));
          expect(draft.totalCountText, total?.toString() ?? '');
          expect(draft.toForm(), SeriesMetadataForm.fromSeries(original));
        },
      );
    }
  }

  test('fromEntry and copyWith retain the editable const draft contract', () {
    final draft = SeriesMetadataEditDraft.fromEntry(
      const SeriesDetailViewObject(
        title: 'Lab series',
        serializationStatus: SerializationStatus.ended,
        volumeTotal: 12,
      ),
    );
    expect(draft.name, 'Lab series');
    expect(draft.serializationStatus, SerializationStatus.ended);
    expect(draft.totalCountText, '12');
    final edited = draft.copyWith(name: 'Changed', totalCountText: '   ');
    expect(
      edited.toForm(),
      SeriesMetadataForm(
        name: 'Changed',
        serializationStatus: SerializationStatus.ended,
        totalCountText: '   ',
      ),
    );
    expect(draft.totalCountText, '12');
  });

  for (final (name, text, nameError, countError) in [
    ('Series', '', false, false),
    ('Series', '   ', false, false),
    ('Series', ' 7 ', false, false),
    ('Series', '0', false, true),
    ('Series', '-1', false, true),
    ('Series', '1.5', false, true),
    ('Series', 'many', false, true),
    ('  ', '7', true, false),
    ('', '0', true, true),
  ]) {
    test('canonical validation for name="$name", total="$text"', () {
      final draft = SeriesMetadataEditDraft(name: name, totalCountText: text);
      final validation = draft.validate();
      expect(validation, draft.toForm().validate());
      expect(validation.nameError != null, nameError);
      expect(validation.totalCountError != null, countError);
      expect(validation.isValid, !nameError && !countError);
    });
  }
}
