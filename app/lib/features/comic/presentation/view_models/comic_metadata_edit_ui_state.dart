import 'package:hentai_library/features/comic/presentation/patterns/metadata_edit/comic_metadata_edit_draft.dart';
import 'package:hentai_library/features/comic/presentation/view_models/comic_metadata_smart_facet_providers.dart';
import 'package:hentai_library/shared/domain/models/value_objects/comic_meta_locks.dart';
import 'package:hentai_library/shared/domain/models/value_objects/series_item_membership.dart';

/// [ComicMetadataEditSession.save] 结果。
enum ComicMetadataEditSaveResult {
  succeeded,
  busy,
  titleInvalid,
  seriesSortInvalid,
}

/// 漫画元数据编辑会话 UI 状态（不可变）。
class ComicMetadataEditUiState {
  const ComicMetadataEditUiState({
    required this.draft,
    required this.locks,
    required this.smartFacetScope,
    this.seed,
    this.titleError,
    this.saving = false,
  });

  final ComicMetadataEditDraft draft;
  final ComicMetaLocks locks;
  final ComicMetadataSmartFacetScope smartFacetScope;
  final SeriesItemMembership? seed;
  final String? titleError;
  final bool saving;

  ComicMetadataEditUiState copyWith({
    ComicMetadataEditDraft? draft,
    ComicMetaLocks? locks,
    ComicMetadataSmartFacetScope? smartFacetScope,
    SeriesItemMembership? seed,
    bool clearSeed = false,
    String? titleError,
    bool clearTitleError = false,
    bool? saving,
  }) {
    return ComicMetadataEditUiState(
      draft: draft ?? this.draft,
      locks: locks ?? this.locks,
      smartFacetScope: smartFacetScope ?? this.smartFacetScope,
      seed: clearSeed ? null : (seed ?? this.seed),
      titleError: clearTitleError ? null : (titleError ?? this.titleError),
      saving: saving ?? this.saving,
    );
  }
}
