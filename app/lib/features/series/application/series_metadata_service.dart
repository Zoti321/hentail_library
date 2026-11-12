import 'package:hentai_library/features/series/domain/value_objects/serialization_status.dart';
import 'package:hentai_library/features/series/domain/series.dart';
import 'package:hentai_library/features/series/domain/value_objects/series_metadata_form.dart';
import 'package:hentai_library/features/series/domain/series_repository.dart';

/// 校验 [SeriesMetadataForm] 并相对 [original] 落库；无变化不调仓储。
Future<SeriesMetadataApplyResult> applySeriesMetadataForm(
  SeriesRepository repository,
  SeriesMetadataForm form,
  Series original,
) async {
  final SeriesMetadataFormValidation validation = form.validate();
  if (!validation.isValid) {
    return SeriesMetadataApplyInvalid(validation);
  }

  final String trimmedName = form.name.trim();
  final String? namePatch = trimmedName != original.name ? trimmedName : null;
  final SerializationStatus? statusPatch =
      form.serializationStatus != original.serializationStatus
      ? form.serializationStatus
      : null;

  final String rawTotal = form.totalCountText.trim();
  final int? totalCount;
  final bool clearTotalCount;
  if (rawTotal.isEmpty) {
    if (original.totalCount != null) {
      totalCount = null;
      clearTotalCount = true;
    } else {
      totalCount = null;
      clearTotalCount = false;
    }
  } else {
    final int parsed = int.parse(rawTotal);
    if (parsed != original.totalCount) {
      totalCount = parsed;
      clearTotalCount = false;
    } else {
      totalCount = null;
      clearTotalCount = false;
    }
  }

  final bool hasChanges =
      namePatch != null ||
      statusPatch != null ||
      totalCount != null ||
      clearTotalCount;
  if (!hasChanges) {
    return const SeriesMetadataApplySucceeded();
  }

  await repository.updateUserMeta(
    seriesId: original.id,
    name: namePatch,
    serializationStatus: statusPatch,
    totalCount: totalCount,
    clearTotalCount: clearTotalCount,
  );
  return const SeriesMetadataApplySucceeded();
}
