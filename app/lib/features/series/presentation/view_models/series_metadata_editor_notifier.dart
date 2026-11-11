import 'package:hentai_library/features/series/application/series_metadata_service.dart';
import 'package:hentai_library/features/series/domain/series.dart';
import 'package:hentai_library/features/series/domain/value_objects/series_metadata_form.dart';
import 'package:hentai_library/features/series/public/di/series_repository_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'series_metadata_editor_notifier.g.dart';

/// Series 元数据编辑表面的命令入口：保存表单与字段锁。
@Riverpod(keepAlive: true)
class SeriesMetadataEditorNotifier extends _$SeriesMetadataEditorNotifier {
  @override
  void build() {}

  Future<SeriesMetadataApplyResult> apply(
    SeriesMetadataForm form,
    Series original,
  ) {
    return applySeriesMetadataForm(
      ref.read(seriesRepoProvider),
      form,
      original,
    );
  }

  Future<void> setLocks(
    String seriesId, {
    bool? name,
    bool? serializationStatus,
    bool? totalCount,
  }) {
    return ref
        .read(seriesRepoProvider)
        .setMetaLocks(
          seriesId: seriesId,
          name: name,
          serializationStatus: serializationStatus,
          totalCount: totalCount,
        );
  }
}
