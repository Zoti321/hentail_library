import 'package:hentai_library/features/series/presentation/patterns/metadata_edit/series_metadata_edit_draft.dart';
import 'package:hentai_library/features/series/domain/series.dart';
import 'package:hentai_library/features/series/domain/value_objects/series_metadata_form.dart';

SeriesMetadataEditDraft seriesMetadataDraftFromSeries(Series series) {
  final SeriesMetadataForm form = SeriesMetadataForm.fromSeries(series);
  return SeriesMetadataEditDraft(
    name: form.name,
    serializationStatus: form.serializationStatus,
    totalCountText: form.totalCountText,
  );
}
