import 'package:hentai_library/features/series/domain/value_objects/serialization_status.dart';
import 'package:hentai_library/features/series/presentation/patterns/metadata_edit/series_metadata_edit_draft.dart';
import 'package:hentai_library/features/series/domain/series.dart';
import 'package:hentai_library/features/series/presentation/views/series_detail/series_detail_view_object.dart';
import 'package:hentai_library/features/series/domain/value_objects/series_metadata_form.dart';

SeriesMetadataEditDraft seriesMetadataDraftFromSeries(Series series) {
  final SeriesMetadataForm form = SeriesMetadataForm.fromSeries(series);
  return SeriesMetadataEditDraft(
    name: form.name,
    serializationStatus: SerializationStatus.values.byName(
      form.serializationStatus.name,
    ),
    totalCountText: form.totalCountText,
  );
}

SeriesMetadataForm seriesMetadataFormFromDraft(
  SeriesMetadataEditDraft draft,
  Series series,
) {
  return SeriesMetadataForm.fromSeries(series).copyWith(
    name: draft.name,
    serializationStatus: SerializationStatus.values.byName(
      draft.serializationStatus.name,
    ),
    totalCountText: draft.totalCountText,
  );
}
