import 'package:hentai_library/features/comic/di/comic_metadata_service.dart';
import 'package:hentai_library/core/logging/app_log.dart';
import 'package:hentai_library/features/comic/presentation/patterns/metadata_edit/comic_metadata_edit_draft.dart';
import 'package:hentai_library/features/comic/presentation/patterns/metadata_edit/comic_metadata_smart_facet_scope.dart';
import 'package:hentai_library/features/comic/presentation/view_models/comic_metadata_edit_ui_state.dart';
import 'package:hentai_library/features/comic/presentation/view_models/comic_metadata_editor_notifier.dart';
import 'package:hentai_library/features/comic/presentation/view_models/comic_metadata_smart_facet_providers.dart';
import 'package:hentai_library/features/comic/public/ui/comic_metadata_edit_mappers.dart';
import 'package:hentai_library/features/comic/domain/comic.dart';
import 'package:hentai_library/features/comic/domain/value_objects/comic_metadata_form.dart';
import 'package:hentai_library/shared/domain/models/value_objects/series_item_membership.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comic_metadata_edit_session_notifier.g.dart';

/// 漫画元数据编辑会话：持有草稿 / 锁 / 校验 / 保存中状态。
///
/// 持久化命令仍委托 [ComicMetadataEditorNotifier]。
@Riverpod()
class ComicMetadataEditSession extends _$ComicMetadataEditSession {
  late Comic _original;

  @override
  ComicMetadataEditUiState build(Comic comic) {
    _original = comic;
    Future<void>.microtask(_loadSeriesSortMembership);
    return ComicMetadataEditUiState(
      draft: comicMetadataDraftFromComic(comic),
      locks: comic.locks,
      smartFacetScope: comicMetadataSmartFacetScopeForComic(comic),
    );
  }

  void updateDraft(ComicMetadataEditDraft draft) {
    final ComicMetadataSmartFacetScope scope = state.smartFacetScope;
    state = state.copyWith(
      draft: draft,
      smartFacetScope: (
        comicId: scope.comicId,
        title: draft.title,
        resourcePath: scope.resourcePath,
        seriesId: scope.seriesId,
      ),
      clearTitleError:
          state.titleError != null && draft.validateTitle() == null,
    );
  }

  Future<void> setLock({
    bool? title,
    bool? description,
    bool? publishedAt,
    bool? contentRating,
    bool? authors,
    bool? tags,
    bool? languages,
    bool? parodies,
    bool? characters,
  }) async {
    if (state.saving) {
      return;
    }
    await ref
        .read(comicMetadataEditorProvider.notifier)
        .setLocks(
          _original.comicId,
          title: title,
          description: description,
          publishedAt: publishedAt,
          contentRating: contentRating,
          authors: authors,
          tags: tags,
          languages: languages,
          parodies: parodies,
          characters: characters,
        );
    state = state.copyWith(
      locks: state.locks.copyWith(
        title: title,
        description: description,
        publishedAt: publishedAt,
        contentRating: contentRating,
        authors: authors,
        tags: tags,
        languages: languages,
        parodies: parodies,
        characters: characters,
      ),
    );
  }

  /// 校验并保存。
  Future<ComicMetadataEditSaveResult> save() async {
    if (state.saving) {
      return ComicMetadataEditSaveResult.busy;
    }
    final String? titleError = state.draft.validateTitle();
    if (titleError != null) {
      state = state.copyWith(titleError: titleError);
      return ComicMetadataEditSaveResult.titleInvalid;
    }

    final SeriesItemMembership? seed = state.seed;
    final String? sortText = state.draft.seriesSortOrderText;
    double? sortOrder;
    if (seed != null && sortText != null) {
      final String trimmed = sortText.trim();
      final double? parsed = double.tryParse(trimmed);
      if (trimmed.isEmpty || parsed == null || !parsed.isFinite) {
        return ComicMetadataEditSaveResult.seriesSortInvalid;
      }
      sortOrder = parsed;
    }

    state = state.copyWith(saving: true);
    try {
      await ref.read(saveComicMetadataUseCaseProvider)(
        comicMetadataFormFromDraft(state.draft, _original).normalized,
        _original,
        sort: seed != null && sortOrder != null
            ? (
                seed: seed,
                sortOrder: sortOrder,
                draftLocked: seed.sortOrderLocked,
              )
            : null,
      );
      return ComicMetadataEditSaveResult.succeeded;
    } finally {
      state = state.copyWith(saving: false);
    }
  }

  Future<void> _loadSeriesSortMembership() async {
    try {
      final SeriesItemMembership? membership = await ref
          .read(comicMetadataEditorProvider.notifier)
          .findSeriesMembership(_original.comicId);
      if (!ref.mounted) {
        return;
      }
      if (membership == null) {
        return;
      }
      state = state.copyWith(
        seed: membership,
        smartFacetScope: comicMetadataSmartFacetScopeForComic(
          _original,
          seriesId: membership.seriesId,
        ),
        draft: state.draft.copyWith(
          seriesSortOrderText: _formatSortOrder(membership.sortOrder),
        ),
      );
    } catch (error, stackTrace) {
      logError(AppLog.ui('editMetadata'), '加载系列排序成员失败（可忽略）', error, stackTrace);
    }
  }
}

String _formatSortOrder(double value) {
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toString();
}
