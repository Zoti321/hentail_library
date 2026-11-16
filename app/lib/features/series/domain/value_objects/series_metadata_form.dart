import 'package:hentai_library/features/series/domain/value_objects/serialization_status.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/features/series/domain/series.dart';

part 'series_metadata_form.freezed.dart';

/// Series 用户元数据编辑草稿（名称、连载状态、计划总卷数原始文本）。
@freezed
abstract class SeriesMetadataForm with _$SeriesMetadataForm {
  factory SeriesMetadataForm({
    required String name,
    required SerializationStatus serializationStatus,
    @Default('') String totalCountText,
  }) = _SeriesMetadataForm;

  factory SeriesMetadataForm.fromSeries(Series series) {
    return SeriesMetadataForm(
      name: series.name,
      serializationStatus: series.serializationStatus,
      totalCountText: series.totalCount?.toString() ?? '',
    );
  }
}

/// 字段级校验结果；[isValid] 为 true 时方可落库。
@freezed
abstract class SeriesMetadataFormValidation
    with _$SeriesMetadataFormValidation {
  const factory SeriesMetadataFormValidation({
    String? nameError,
    String? totalCountError,
  }) = _SeriesMetadataFormValidation;

  const SeriesMetadataFormValidation._();

  bool get isValid => nameError == null && totalCountError == null;
}

extension SeriesMetadataFormOps on SeriesMetadataForm {
  /// 一次算出全部字段错误（可同时亮 name + totalCount）。
  SeriesMetadataFormValidation validate() {
    final String? nameError = name.trim().isEmpty ? '系列名称不能为空' : null;

    String? totalCountError;
    final String rawTotal = totalCountText.trim();
    if (rawTotal.isNotEmpty) {
      final int? parsed = int.tryParse(rawTotal);
      if (parsed == null || parsed <= 0) {
        totalCountError = '漫画总数须为正整数，留空表示不设置';
      } else if (parsed > maxSeriesTotalCount) {
        totalCountError = '漫画总数不能超过 $maxSeriesTotalCount';
      }
    }

    return SeriesMetadataFormValidation(
      nameError: nameError,
      totalCountError: totalCountError,
    );
  }
}

sealed class SeriesMetadataDraftDiff {
  const SeriesMetadataDraftDiff();
}

final class SeriesMetadataDraftInvalid extends SeriesMetadataDraftDiff {
  const SeriesMetadataDraftInvalid(this.validation);
  final SeriesMetadataFormValidation validation;
}

final class SeriesMetadataDraftUnchanged extends SeriesMetadataDraftDiff {
  const SeriesMetadataDraftUnchanged();
}

final class SeriesMetadataDraftChanges extends SeriesMetadataDraftDiff {
  const SeriesMetadataDraftChanges({
    this.name,
    this.serializationStatus,
    this.totalCount,
    this.clearTotalCount = false,
  });
  final String? name;
  final SerializationStatus? serializationStatus;
  final int? totalCount;
  final bool clearTotalCount;
}

extension SeriesMetadataFormDiff on SeriesMetadataForm {
  SeriesMetadataDraftDiff diffAgainst(Series original) {
    final validation = validate();
    if (!validation.isValid) {
      return SeriesMetadataDraftInvalid(validation);
    }
    final trimmedName = name.trim();
    final namePatch = trimmedName != original.name ? trimmedName : null;
    final statusPatch = serializationStatus != original.serializationStatus
        ? serializationStatus
        : null;
    final rawTotal = totalCountText.trim();
    final parsedTotal = rawTotal.isEmpty ? null : int.parse(rawTotal);
    final totalCount = parsedTotal != original.totalCount ? parsedTotal : null;
    final clearTotalCount = parsedTotal == null && original.totalCount != null;
    if (namePatch == null &&
        statusPatch == null &&
        totalCount == null &&
        !clearTotalCount) {
      return const SeriesMetadataDraftUnchanged();
    }
    return SeriesMetadataDraftChanges(
      name: namePatch,
      serializationStatus: statusPatch,
      totalCount: totalCount,
      clearTotalCount: clearTotalCount,
    );
  }
}
