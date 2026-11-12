import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/core/logging/app_log.dart';
import 'package:hentai_library/features/series/presentation/patterns/metadata_edit/series_metadata_edit_form.dart';
import 'package:hentai_library/features/series/presentation/view_models/series_metadata_edit_session_notifier.dart';
import 'package:hentai_library/features/series/presentation/view_models/series_metadata_edit_ui_state.dart';
import 'package:hentai_library/shared/ui/patterns/metadata_edit/metadata_edit_surface.dart';
import 'package:hentai_library/features/series/domain/series.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/app_snackbar.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

export 'package:hentai_library/features/series/presentation/views/metadata_edit/series_metadata_edit_layout.dart';
export 'package:hentai_library/features/series/presentation/patterns/metadata_edit/series_metadata_edit_draft.dart';

/// 系列元数据编辑视图：草稿在会话 Notifier；[save] 供外层 GlobalKey 调用。
class SeriesMetadataEditFormLayout extends ConsumerStatefulWidget {
  const SeriesMetadataEditFormLayout({
    super.key,
    required this.series,
    this.presentation = MetadataEditPresentation.modal,
  });

  final Series series;
  final MetadataEditPresentation presentation;

  @override
  ConsumerState<SeriesMetadataEditFormLayout> createState() =>
      SeriesMetadataEditViewState();
}

class SeriesMetadataEditViewState
    extends ConsumerState<SeriesMetadataEditFormLayout> {
  /// 供全屏底栏确认按钮调用。
  Future<void> save() async {
    final AppLocalizations l10n = context.l10n;
    final SeriesMetadataEditSession notifier = ref.read(
      seriesMetadataEditSessionProvider(widget.series).notifier,
    );
    try {
      final SeriesMetadataEditSaveResult result = await notifier.save();
      if (!mounted) {
        return;
      }
      switch (result) {
        case SeriesMetadataEditSaveResult.succeeded:
          showSuccessSnackbar(context, l10n.commonSavedToast);
          _leave();
        case SeriesMetadataEditSaveResult.validationFailed:
        case SeriesMetadataEditSaveResult.busy:
          break;
      }
    } catch (error, stackTrace) {
      logError(AppLog.ui('editSeries'), '保存系列元数据失败', error, stackTrace);
      if (mounted) {
        showErrorSnackbar(context, l10n.commonSaveFailedToast);
      }
    }
  }

  void _handleLockChanged({
    required SeriesMetadataEditSession notifier,
    required AppLocalizations l10n,
    required bool? name,
    required bool? serializationStatus,
    required bool? totalCount,
  }) {
    unawaited(() async {
      try {
        await notifier.setLock(
          name: name,
          serializationStatus: serializationStatus,
          totalCount: totalCount,
        );
      } catch (error, stackTrace) {
        logError(AppLog.ui('editSeries'), '设置系列元数据字段锁失败', error, stackTrace);
        if (mounted) {
          showErrorSnackbar(context, l10n.commonSaveFailedToast);
        }
      }
    }());
  }

  void _leave() {
    final NavigatorState navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final SeriesMetadataEditUiState session = ref.watch(
      seriesMetadataEditSessionProvider(widget.series),
    );
    final SeriesMetadataEditSession notifier = ref.read(
      seriesMetadataEditSessionProvider(widget.series).notifier,
    );
    final AppLocalizations l10n = context.l10n;

    return MetadataEditSurface(
      presentation: widget.presentation,
      title: l10n.dialogEditSeriesTitle,
      onCancel: _leave,
      onSave: save,
      saving: session.saving,
      maxWidth: 560,
      body: SeriesMetadataEditForm(
        draft: session.draft,
        locks: session.locks,
        onLockChanged:
            ({bool? name, bool? serializationStatus, bool? totalCount}) =>
                _handleLockChanged(
                  notifier: notifier,
                  l10n: l10n,
                  name: name,
                  serializationStatus: serializationStatus,
                  totalCount: totalCount,
                ),
        nameError: session.nameError,
        totalCountError: session.totalCountError,
        onDraftChanged: notifier.updateDraft,
      ),
    );
  }
}
