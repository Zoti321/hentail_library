import 'package:hentai_library/features/series/domain/series.dart';
import 'package:hentai_library/features/series/domain/value_objects/series_metadata_form.dart';
import 'package:hentai_library/features/series/domain/series_repository.dart';

/// 保存结果：非法草稿不写入；成功包括无变化的草稿。
/// 仓储异常继续向上传播，由界面呈现。
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

class ApplySeriesMetadataFormUseCase {
  const ApplySeriesMetadataFormUseCase(this._repository);

  final SeriesRepository _repository;

  Future<SeriesMetadataApplyResult> call(
    SeriesMetadataForm form,
    Series original,
  ) async {
    switch (form.diffAgainst(original)) {
      case SeriesMetadataDraftInvalid(:final validation):
        return SeriesMetadataApplyInvalid(validation);
      case SeriesMetadataDraftUnchanged():
        return const SeriesMetadataApplySucceeded();
      case SeriesMetadataDraftChanges(
        :final name,
        :final serializationStatus,
        :final totalCount,
        :final clearTotalCount,
      ):
        await _repository.updateUserMeta(
          seriesId: original.id,
          name: name,
          serializationStatus: serializationStatus,
          totalCount: totalCount,
          clearTotalCount: clearTotalCount,
        );
        return const SeriesMetadataApplySucceeded();
    }
  }
}
