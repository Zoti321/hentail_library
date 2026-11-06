import 'package:hentai_library/features/series/presentation/views/series_detail/series_detail_view_object.dart';

/// Lab 系列元数据编辑草稿。
class SeriesMetadataEditDraft {
  const SeriesMetadataEditDraft({
    required this.name,
    this.serializationStatus = SeriesSerializationStatus.ongoing,
    this.totalCountText = '',
  });

  final String name;
  final SeriesSerializationStatus serializationStatus;
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
    SeriesSerializationStatus? serializationStatus,
    String? totalCountText,
  }) {
    return SeriesMetadataEditDraft(
      name: name ?? this.name,
      serializationStatus: serializationStatus ?? this.serializationStatus,
      totalCountText: totalCountText ?? this.totalCountText,
    );
  }

  String? validateName() {
    if (name.trim().isEmpty) {
      return '系列名称不能为空';
    }
    return null;
  }

  String? validateTotalCount() {
    final String text = totalCountText.trim();
    if (text.isEmpty) {
      return null;
    }
    final int? value = int.tryParse(text);
    if (value == null || value < 0) {
      return '请输入有效数字';
    }
    return null;
  }
}
