import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/core/logging/app_log.dart';
import 'package:hentai_library/features/comic/presentation/patterns/metadata_edit/comic_metadata_edit_form.dart';
import 'package:hentai_library/features/comic/presentation/view_models/comic_metadata_edit_session_notifier.dart';
import 'package:hentai_library/features/comic/presentation/view_models/comic_metadata_edit_ui_state.dart';
import 'package:hentai_library/shared/ui/patterns/metadata_edit/metadata_edit_surface.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/app_snackbar.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

export 'package:hentai_library/features/comic/presentation/views/metadata_edit/comic_metadata_edit_layout.dart';
export 'package:hentai_library/features/comic/presentation/patterns/metadata_edit/comic_metadata_edit_draft.dart';

/// 漫画元数据编辑视图（已加载实体）：草稿在会话 Notifier；[save] 供外层 GlobalKey 调用。
class ComicMetadataEditFormLayout extends ConsumerStatefulWidget {
  const ComicMetadataEditFormLayout({
    super.key,
    required this.comic,
    this.presentation = MetadataEditPresentation.modal,
  });

  final Comic comic;
  final MetadataEditPresentation presentation;

  @override
  ConsumerState<ComicMetadataEditFormLayout> createState() =>
      ComicMetadataEditViewState();
}

class ComicMetadataEditViewState
    extends ConsumerState<ComicMetadataEditFormLayout> {
  /// 供全屏底栏确认按钮调用。
  Future<void> save() async {
    final AppLocalizations l10n = context.l10n;
    final ComicMetadataEditSession notifier = ref.read(
      comicMetadataEditSessionProvider(widget.comic).notifier,
    );
    try {
      final ComicMetadataEditSaveResult result = await notifier.save();
      if (!mounted) {
        return;
      }
      switch (result) {
        case ComicMetadataEditSaveResult.succeeded:
          showSuccessSnackbar(context, l10n.commonSavedToast);
          _leave();
        case ComicMetadataEditSaveResult.seriesSortInvalid:
          showErrorSnackbar(context, l10n.formSeriesItemSortOrderInvalid);
        case ComicMetadataEditSaveResult.titleInvalid:
        case ComicMetadataEditSaveResult.busy:
          break;
      }
    } catch (error, stackTrace) {
      logError(AppLog.ui('editMetadata'), '保存漫画元数据失败', error, stackTrace);
      if (mounted) {
        showErrorSnackbar(context, l10n.commonSaveFailedToast);
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
    final ComicMetadataEditUiState session = ref.watch(
      comicMetadataEditSessionProvider(widget.comic),
    );
    final ComicMetadataEditSession notifier = ref.read(
      comicMetadataEditSessionProvider(widget.comic).notifier,
    );
    final AppLocalizations l10n = context.l10n;

    return MetadataEditSurface(
      presentation: widget.presentation,
      title: l10n.dialogEditMetadataTitle,
      onCancel: _leave,
      onSave: save,
      saving: session.saving,
      body: ComicMetadataEditForm(
        draft: session.draft,
        locks: session.locks,
        onLockChanged:
            ({
              bool? title,
              bool? description,
              bool? publishedAt,
              bool? contentRating,
              bool? authors,
              bool? tags,
              bool? languages,
              bool? parodies,
              bool? characters,
            }) {
              unawaited(() async {
                try {
                  await notifier.setLock(
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
                } catch (error, stackTrace) {
                  logError(
                    AppLog.ui('editMetadata'),
                    '设置元数据字段锁失败',
                    error,
                    stackTrace,
                  );
                  if (mounted) {
                    showErrorSnackbar(context, l10n.commonSaveFailedToast);
                  }
                }
              }());
            },
        titleError: session.titleError,
        smartFacetScope: session.smartFacetScope,
        onDraftChanged: notifier.updateDraft,
      ),
    );
  }
}
