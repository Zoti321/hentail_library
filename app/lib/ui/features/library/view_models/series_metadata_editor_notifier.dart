import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/value_objects/form/series_metadata_form.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
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
    return form.applyTo(ref.read(seriesRepoProvider), original);
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
