import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/core/logging/app_log.dart';
import 'package:hentai_library/features/series/presentation/view_models/series_metadata_editor_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/catalog/views/metadata_edit_md3e/metadata_edit_mappers.dart';
import 'package:hentai_library/shared/ui/patterns/metadata_edit/metadata_edit_surface.dart';
import 'package:hentai_library/features/series/presentation/patterns/metadata_edit/series_metadata_edit_draft.dart';
import 'package:hentai_library/features/series/presentation/patterns/metadata_edit/series_metadata_edit_form.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/series.dart';
import 'package:hentai_library/shared/domain/models/value_objects/form/series_metadata_form.dart';
import 'package:hentai_library/shared/domain/models/value_objects/series_meta_locks.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/app_snackbar.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 系列元数据编辑视图（已加载实体）：Lab 表单 + Lab 编辑壳，保存走生产 notifier。
class SeriesMetadataEditMd3eView extends ConsumerStatefulWidget {
  const SeriesMetadataEditMd3eView({
    super.key,
    required this.series,
    this.presentation = Md3eMetadataEditPresentation.modal,
  });

  final Series series;
  final Md3eMetadataEditPresentation presentation;

  @override
  ConsumerState<SeriesMetadataEditMd3eView> createState() =>
      SeriesMetadataEditMd3eViewState();
}

class SeriesMetadataEditMd3eViewState
    extends ConsumerState<SeriesMetadataEditMd3eView> {
  late Md3eSeriesMetadataEditDraft _draft;
  late SeriesMetaLocks _locks;
  String? _nameError;
  String? _totalCountError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _draft = seriesMetadataDraftFromSeries(widget.series);
    _locks = widget.series.locks;
  }

  Future<void> _setLock({
    bool? name,
    bool? serializationStatus,
    bool? totalCount,
  }) async {
    if (_saving) {
      return;
    }
    try {
      await ref
          .read(seriesMetadataEditorProvider.notifier)
          .setLocks(
            widget.series.id,
            name: name,
            serializationStatus: serializationStatus,
            totalCount: totalCount,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _locks = _locks.copyWith(
          name: name,
          serializationStatus: serializationStatus,
          totalCount: totalCount,
        );
      });
    } catch (error, stackTrace) {
      logError(AppLog.ui('editSeries'), '设置系列元数据字段锁失败', error, stackTrace);
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
    setState(() => _saving = true);
    try {
      final SeriesMetadataApplyResult result = await ref
          .read(seriesMetadataEditorProvider.notifier)
          .apply(
            seriesMetadataFormFromDraft(_draft, widget.series),
            widget.series,
          );
      if (!mounted) {
        return;
      }
      switch (result) {
        case SeriesMetadataApplyInvalid(
          :final SeriesMetadataFormValidation validation,
        ):
          setState(() {
            _nameError = validation.nameError;
            _totalCountError = validation.totalCountError;
          });
        case SeriesMetadataApplySucceeded():
          showSuccessSnackbar(context, context.l10n.commonSavedToast);
          _leave();
      }
    } catch (error, stackTrace) {
      logError(AppLog.ui('editSeries'), '保存系列元数据失败', error, stackTrace);
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
      title: l10n.dialogEditSeriesTitle,
      onCancel: _leave,
      onSave: save,
      saving: _saving,
      maxWidth: 560,
      body: Md3eSeriesMetadataEditForm(
        draft: _draft,
        locks: _locks,
        onLockChanged: _setLock,
        nameError: _nameError,
        totalCountError: _totalCountError,
        onDraftChanged: (Md3eSeriesMetadataEditDraft value) {
          setState(() {
            _draft = value;
            _nameError = null;
            _totalCountError = null;
          });
        },
      ),
    );
  }
}
