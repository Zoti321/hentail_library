import 'package:hentai_library/features/series/presentation/views/series_detail/series_detail_view_object.dart';
import 'package:hentai_library/features/series/domain/value_objects/series_metadata_form.dart';

/// Lab 系列元数据编辑草稿。
class SeriesMetadataEditDraft {
  const SeriesMetadataEditDraft({
    required this.name,
    this.serializationStatus = SerializationStatus.ongoing,
    this.totalCountText = '',
  });

  final String name;
  final SerializationStatus serializationStatus;
  final String totalCountText;

  factory SeriesMetadataEditDraft.fromEntry(SeriesDetailViewObject entry) {
    final String? total = entry.volumeTotal?.toString();
    return SeriesMetadataEditDraft(
      name: entry.title,
      serializationStatus: entry.serializationStatus,
      totalCountText: total ?? '',
    );
  }

  SeriesMetadataEditDraft copyWith({
    String? name,
    SerializationStatus? serializationStatus,
    String? totalCountText,
  }) {
    return SeriesMetadataEditDraft(
      name: name ?? this.name,
      serializationStatus: serializationStatus ?? this.serializationStatus,
      totalCountText: totalCountText ?? this.totalCountText,
    );
  }

  SeriesMetadataForm toForm() => SeriesMetadataForm(
    name: name,
    serializationStatus: serializationStatus,
    totalCountText: totalCountText,
  );

  SeriesMetadataFormValidation validate() => toForm().validate();
}
