import 'package:hentai_library/md3e/pages/md3e_series_detail_entry.dart';

/// Lab 系列元数据编辑草稿。
class Md3eSeriesMetadataEditDraft {
  const Md3eSeriesMetadataEditDraft({
    required this.name,
    this.serializationStatus = Md3eSeriesSerializationStatus.ongoing,
    this.totalCountText = '',
  });

  final String name;
  final Md3eSeriesSerializationStatus serializationStatus;
  final String totalCountText;

  factory Md3eSeriesMetadataEditDraft.fromEntry(Md3eSeriesDetailEntry entry) {
    final String? total = entry.volumeTotal?.toString();
    return Md3eSeriesMetadataEditDraft(
      name: entry.title,
      serializationStatus: entry.serializationStatus,
      totalCountText: total ?? '',
    );
  }

  Md3eSeriesMetadataEditDraft copyWith({
    String? name,
    Md3eSeriesSerializationStatus? serializationStatus,
    String? totalCountText,
  }) {
    return Md3eSeriesMetadataEditDraft(
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
