import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/core/logging/app_log.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/series_metadata_editor_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/views/metadata_edit_md3e/metadata_edit_mappers.dart';
import 'package:hentai_library/features/library_browse/presentation/views/widgets/detail_status/detail_status_scaffold.dart';
import 'package:hentai_library/md3e/patterns/metadata_edit/md3e_metadata_edit_surface.dart';
import 'package:hentai_library/md3e/patterns/metadata_edit/md3e_series_metadata_edit_draft.dart';
import 'package:hentai_library/md3e/patterns/metadata_edit/md3e_series_metadata_edit_form.dart';
import 'package:hentai_library/md3e/theme/md3e_theme.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/series.dart';
import 'package:hentai_library/shared/domain/models/value_objects/form/series_metadata_form.dart';
import 'package:hentai_library/shared/domain/models/value_objects/series_meta_locks.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/custom_toast.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 生产系列元数据编辑整页（MD3E）：按 id 加载后渲染 [SeriesMetadataEditMd3eView]。
class SeriesMetadataEditMd3ePage extends ConsumerWidget {
  const SeriesMetadataEditMd3ePage({super.key, required this.seriesId});

  final String seriesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Series?> seriesAsync = ref.watch(
      seriesByIdStateProvider(seriesId),
    );
    return M3ETheme(
      data: md3eWithAppFontFamily(M3ETheme.of(context)),
      child: seriesAsync.when(
        data: (Series? series) {
          if (series == null) {
            return DetailNotFoundStatus(
              icon: LucideIcons.library,
              label: context.l10n.seriesDetailNotFound(seriesId),
            );
          }
          return SeriesMetadataEditMd3eView(series: series);
        },
        loading: () => const DetailLoadingStatus(),
        error: (Object error, StackTrace _) => DetailErrorStatus(
          label: context.l10n.seriesDetailLoadFailed(error.toString()),
        ),
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
      ),
    );
  }
}

/// 系列元数据编辑视图（已加载实体）：Lab 表单 + Lab 编辑壳，保存走生产 notifier。
class SeriesMetadataEditMd3eView extends ConsumerStatefulWidget {
  const SeriesMetadataEditMd3eView({super.key, required this.series});

  final Series series;

  @override
  ConsumerState<SeriesMetadataEditMd3eView> createState() =>
      _SeriesMetadataEditMd3eViewState();
}

class _SeriesMetadataEditMd3eViewState
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
        showCustomToast(
          context,
          message: context.l10n.commonSaveFailedToast,
          type: AppToastType.error,
        );
      }
    }
  }

  Future<void> _handleSave() async {
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
          showSuccessToast(context, context.l10n.commonSavedToast);
          _leave();
      }
    } catch (error, stackTrace) {
      logError(AppLog.ui('editSeries'), '保存系列元数据失败', error, stackTrace);
      if (mounted) {
        showCustomToast(
          context,
          message: context.l10n.commonSaveFailedToast,
          type: AppToastType.error,
        );
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
      presentation: Md3eMetadataEditPresentation.embedded,
      title: l10n.dialogEditSeriesTitle,
      onCancel: _leave,
      onSave: _handleSave,
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
