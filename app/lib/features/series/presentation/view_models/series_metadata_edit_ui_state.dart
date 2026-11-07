import 'package:hentai_library/features/series/presentation/patterns/metadata_edit/series_metadata_edit_draft.dart';
import 'package:hentai_library/shared/domain/models/value_objects/series_meta_locks.dart';

/// [SeriesMetadataEditSession.save] 结果。
enum SeriesMetadataEditSaveResult { succeeded, busy, validationFailed }

/// 系列元数据编辑会话 UI 状态（不可变）。
class SeriesMetadataEditUiState {
  const SeriesMetadataEditUiState({
    required this.draft,
    required this.locks,
    this.nameError,
    this.totalCountError,
    this.saving = false,
  });

  final SeriesMetadataEditDraft draft;
  final SeriesMetaLocks locks;
  final String? nameError;
  final String? totalCountError;
  final bool saving;

  SeriesMetadataEditUiState copyWith({
    SeriesMetadataEditDraft? draft,
    SeriesMetaLocks? locks,
    String? nameError,
    bool clearNameError = false,
    String? totalCountError,
    bool clearTotalCountError = false,
    bool? saving,
  }) {
    return SeriesMetadataEditUiState(
      draft: draft ?? this.draft,
      locks: locks ?? this.locks,
      nameError: clearNameError ? null : (nameError ?? this.nameError),
      totalCountError: clearTotalCountError
          ? null
          : (totalCountError ?? this.totalCountError),
      saving: saving ?? this.saving,
    );
  }
}
