import 'package:hentai_library/features/library_browse/public/catalog/for_comic_and_series.dart';
import 'package:hentai_library/features/series/presentation/patterns/metadata_edit/series_metadata_edit_draft.dart';
import 'package:hentai_library/features/series/presentation/view_models/series_metadata_edit_ui_state.dart';
import 'package:hentai_library/features/series/presentation/view_models/series_metadata_editor_notifier.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/series.dart';
import 'package:hentai_library/shared/domain/models/value_objects/form/series_metadata_form.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'series_metadata_edit_session_notifier.g.dart';

/// 系列元数据编辑会话：持有草稿 / 锁 / 校验 / 保存中状态。
@Riverpod()
class SeriesMetadataEditSession extends _$SeriesMetadataEditSession {
  late Series _original;

  @override
  SeriesMetadataEditUiState build(Series series) {
    _original = series;
    return SeriesMetadataEditUiState(
      draft: seriesMetadataDraftFromSeries(series),
      locks: series.locks,
    );
  }

  void updateDraft(SeriesMetadataEditDraft draft) {
    state = state.copyWith(
      draft: draft,
      clearNameError: true,
      clearTotalCountError: true,
    );
  }

  Future<void> setLock({
    bool? name,
    bool? serializationStatus,
    bool? totalCount,
  }) async {
    if (state.saving) {
      return;
    }
    await ref
        .read(seriesMetadataEditorProvider.notifier)
        .setLocks(
          _original.id,
          name: name,
          serializationStatus: serializationStatus,
          totalCount: totalCount,
        );
    state = state.copyWith(
      locks: state.locks.copyWith(
        name: name,
        serializationStatus: serializationStatus,
        totalCount: totalCount,
      ),
    );
  }

  Future<SeriesMetadataEditSaveResult> save() async {
    if (state.saving) {
      return SeriesMetadataEditSaveResult.busy;
    }
    state = state.copyWith(saving: true);
    late final SeriesMetadataEditSaveResult outcome;
    try {
      final SeriesMetadataApplyResult result = await ref
          .read(seriesMetadataEditorProvider.notifier)
          .apply(
            seriesMetadataFormFromDraft(state.draft, _original),
            _original,
          );
      switch (result) {
        case SeriesMetadataApplyInvalid(
          :final SeriesMetadataFormValidation validation,
        ):
          state = state.copyWith(
            nameError: validation.nameError,
            totalCountError: validation.totalCountError,
          );
          outcome = SeriesMetadataEditSaveResult.validationFailed;
        case SeriesMetadataApplySucceeded():
          outcome = SeriesMetadataEditSaveResult.succeeded;
      }
    } finally {
      state = state.copyWith(saving: false);
    }
    return outcome;
  }
}
