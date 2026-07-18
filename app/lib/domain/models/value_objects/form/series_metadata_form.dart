import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/repositories/series_repository.dart';

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

/// [SeriesMetadataForm.applyTo] 的结果：非法不调仓储；成功已落库。
/// 仓储异常仍向上抛，由 UI toast。
sealed class SeriesMetadataApplyResult {
  const SeriesMetadataApplyResult();
}

final class SeriesMetadataApplyInvalid extends SeriesMetadataApplyResult {
  const SeriesMetadataApplyInvalid(this.validation);

  final SeriesMetadataFormValidation validation;
}

final class SeriesMetadataApplySucceeded extends SeriesMetadataApplyResult {
  const SeriesMetadataApplySucceeded();
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
      }
    }

    return SeriesMetadataFormValidation(
      nameError: nameError,
      totalCountError: totalCountError,
    );
  }

  /// 非法 → [SeriesMetadataApplyInvalid]；合法 → `updateUserMeta` 后
  /// [SeriesMetadataApplySucceeded]。空 [totalCountText] → `clearTotalCount: true`（幂等）。
  Future<SeriesMetadataApplyResult> applyTo(
    SeriesRepository repository, {
    required String seriesId,
  }) async {
    final SeriesMetadataFormValidation validation = validate();
    if (!validation.isValid) {
      return SeriesMetadataApplyInvalid(validation);
    }

    final String trimmedName = name.trim();
    final String rawTotal = totalCountText.trim();
    final int? totalCount;
    final bool clearTotalCount;
    if (rawTotal.isEmpty) {
      totalCount = null;
      clearTotalCount = true;
    } else {
      totalCount = int.parse(rawTotal);
      clearTotalCount = false;
    }

    await repository.updateUserMeta(
      seriesId: seriesId,
      name: trimmedName,
      serializationStatus: serializationStatus,
      totalCount: totalCount,
      clearTotalCount: clearTotalCount,
    );
    return const SeriesMetadataApplySucceeded();
  }
}
