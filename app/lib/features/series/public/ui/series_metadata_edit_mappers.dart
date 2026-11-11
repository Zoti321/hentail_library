import 'package:hentai_library/features/series/presentation/patterns/metadata_edit/series_metadata_edit_draft.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/series.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/features/series/presentation/views/series_detail/series_detail_view_object.dart';
import 'package:hentai_library/shared/domain/models/value_objects/form/series_metadata_form.dart';

SeriesMetadataEditDraft seriesMetadataDraftFromSeries(Series series) {
  final SeriesMetadataForm form = SeriesMetadataForm.fromSeries(series);
  return SeriesMetadataEditDraft(
    name: form.name,
    serializationStatus: SeriesSerializationStatus.values.byName(
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
