import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/core/logging/app_log.dart';
import 'package:hentai_library/features/comic/presentation/view_models/comic_metadata_editor_notifier.dart';
import 'package:hentai_library/features/comic/presentation/patterns/metadata_edit/comic_metadata_edit_draft.dart';
import 'package:hentai_library/features/comic/presentation/patterns/metadata_edit/comic_metadata_smart_facet_scope.dart';
import 'package:hentai_library/features/comic/presentation/view_models/comic_metadata_smart_facet_providers.dart';
import 'package:hentai_library/features/comic/presentation/patterns/metadata_edit/comic_metadata_edit_form.dart';
import 'package:hentai_library/shared/ui/patterns/metadata_edit/metadata_edit_surface.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/value_objects/comic_meta_locks.dart';
import 'package:hentai_library/shared/domain/models/value_objects/form/comic_metadata_form.dart';
import 'package:hentai_library/shared/domain/models/value_objects/series_item_membership.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/app_snackbar.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hentai_library/features/library_browse/public/catalog/for_comic_and_series.dart';

/// 漫画元数据编辑视图（已加载实体）：Lab 表单 + Lab 编辑壳，保存走生产 notifier。
class ComicMetadataEditMd3eView extends ConsumerStatefulWidget {
  const ComicMetadataEditMd3eView({
    super.key,
    required this.comic,
    this.presentation = Md3eMetadataEditPresentation.modal,
  });

  final Comic comic;
  final Md3eMetadataEditPresentation presentation;

  @override
  ConsumerState<ComicMetadataEditMd3eView> createState() =>
      ComicMetadataEditMd3eViewState();
}

class ComicMetadataEditMd3eViewState
    extends ConsumerState<ComicMetadataEditMd3eView> {
  late Md3eComicMetadataEditDraft _draft;
  late ComicMetaLocks _locks;
  SeriesItemMembership? _seed;
  String? _titleError;
  bool _saving = false;
  late ComicMetadataSmartFacetScope _smartFacetScope;

  @override
  void initState() {
    super.initState();
    _draft = comicMetadataDraftFromComic(widget.comic);
    _locks = widget.comic.locks;
    _smartFacetScope = comicMetadataSmartFacetScopeForComic(widget.comic);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSeriesSortMembership();
    });
  }

  Future<void> _loadSeriesSortMembership() async {
    try {
      final SeriesItemMembership? membership = await ref
          .read(comicMetadataEditorProvider.notifier)
          .findSeriesMembership(widget.comic.comicId);
      if (!mounted) {
        return;
      }
      setState(() {
        _seed = membership;
        if (membership != null) {
          _smartFacetScope = comicMetadataSmartFacetScopeForComic(
            widget.comic,
            seriesId: membership.seriesId,
          );
          _draft = _draft.copyWith(
            seriesSortOrderText: _formatSortOrder(membership.sortOrder),
          );
        }
      });
    } catch (_) {
      // 没有系列归属或读取失败时不显示排序字段。
    }
  }

  Future<void> _setLock({
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
    if (_saving) {
      return;
    }
    try {
      await ref
          .read(comicMetadataEditorProvider.notifier)
          .setLocks(
            widget.comic.comicId,
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
      if (!mounted) {
        return;
      }
      setState(() {
        _locks = _locks.copyWith(
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
      });
    } catch (error, stackTrace) {
      logError(AppLog.ui('editMetadata'), '设置元数据字段锁失败', error, stackTrace);
      if (mounted) {
        showErrorSnackbar(context, context.l10n.commonSaveFailedToast);
      }
    }
  }

  /// 供全屏底栏确认按钮调用。
  Future<void> save() async {
    if (_saving) {
      return;
    }
    final String? titleError = _draft.validateTitle();
    if (titleError != null) {
      setState(() => _titleError = titleError);
      return;
    }

    final SeriesItemMembership? seed = _seed;
    final String? sortText = _draft.seriesSortOrderText;
    double? sortOrder;
    if (seed != null && sortText != null) {
      final String trimmed = sortText.trim();
      final double? parsed = double.tryParse(trimmed);
      if (trimmed.isEmpty || parsed == null || !parsed.isFinite) {
        showErrorSnackbar(context, context.l10n.formSeriesItemSortOrderInvalid);
        return;
      }
      sortOrder = parsed;
    }

    setState(() => _saving = true);
    try {
      final ComicMetadataEditorNotifier editor = ref.read(
        comicMetadataEditorProvider.notifier,
      );
      await editor.apply(
        comicMetadataFormFromDraft(_draft, widget.comic).normalized,
        widget.comic,
      );
      if (seed != null && sortOrder != null) {
        await editor.persistSeriesSort(
          comicId: widget.comic.comicId,
          seed: seed,
          sortOrder: sortOrder,
          draftLocked: seed.sortOrderLocked,
        );
      }
      if (mounted) {
        showSuccessSnackbar(context, context.l10n.commonSavedToast);
        _leave();
      }
    } catch (error, stackTrace) {
      logError(AppLog.ui('editMetadata'), '保存漫画元数据失败', error, stackTrace);
      if (mounted) {
        showErrorSnackbar(context, context.l10n.commonSaveFailedToast);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _leave() {
    final NavigatorState navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Md3eMetadataEditSurface(
      presentation: widget.presentation,
      title: l10n.dialogEditMetadataTitle,
      onCancel: _leave,
      onSave: save,
      saving: _saving,
      body: Md3eComicMetadataEditForm(
        draft: _draft,
        locks: _locks,
        onLockChanged: _setLock,
        titleError: _titleError,
        smartFacetScope: _smartFacetScope,
        onDraftChanged: (Md3eComicMetadataEditDraft value) {
          setState(() {
            _draft = value;
            _smartFacetScope = (
              comicId: _smartFacetScope.comicId,
              title: value.title,
              resourcePath: _smartFacetScope.resourcePath,
              seriesId: _smartFacetScope.seriesId,
            );
            if (_titleError != null && value.validateTitle() == null) {
              _titleError = null;
            }
          });
        },
      ),
    );
  }
}

String _formatSortOrder(double value) {
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toString();
}
