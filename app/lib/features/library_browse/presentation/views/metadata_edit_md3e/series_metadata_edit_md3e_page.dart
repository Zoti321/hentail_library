import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:hentai_library/features/library_browse/presentation/views/widgets/detail_status/detail_back_header.dart';
import 'package:hentai_library/features/library_browse/presentation/views/widgets/detail_status/detail_status_scaffold.dart';
import 'package:hentai_library/md3e/theme/md3e_theme.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/core/logging/app_log.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/series.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/value_objects/form/series_metadata_form.dart';
import 'package:hentai_library/shared/domain/models/value_objects/series_meta_locks.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/shared/ui/widgets/form/fluent_select_field.dart';
import 'package:hentai_library/shared/ui/widgets/form/fluent_text_field.dart';
import 'package:hentai_library/shared/ui/widgets/form/metadata_lock_button.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/series_metadata_editor_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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

/// 系列元数据编辑表单视图（已加载实体）。
class SeriesMetadataEditMd3eView extends ConsumerStatefulWidget {
  const SeriesMetadataEditMd3eView({super.key, required this.series});

  final Series series;

  @override
  ConsumerState<SeriesMetadataEditMd3eView> createState() =>
      _SeriesMetadataEditMd3eViewState();
}

class _SeriesMetadataEditMd3eViewState
    extends ConsumerState<SeriesMetadataEditMd3eView> {
  late SeriesMetadataForm _form;
  late SeriesMetaLocks _locks;
  SeriesMetadataFormValidation? _validation;
  bool _saving = false;
  bool _lockBusy = false;

  @override
  void initState() {
    super.initState();
    _form = SeriesMetadataForm.fromSeries(widget.series);
    _locks = widget.series.locks;
  }

  Future<void> _setLock({
    bool? name,
    bool? serializationStatus,
    bool? totalCount,
  }) async {
    if (_lockBusy) {
      return;
    }
    setState(() => _lockBusy = true);
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
    } finally {
      if (mounted) {
        setState(() => _lockBusy = false);
      }
    }
  }

  void _leaveAfterSave() {
    final NavigatorState navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    DetailBackHeader.popOrGoLibrary(context);
  }

  Future<void> _handleSave() async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      final SeriesMetadataApplyResult result = await ref
          .read(seriesMetadataEditorProvider.notifier)
          .apply(_form, widget.series);
      if (!mounted) {
        return;
      }
      switch (result) {
        case SeriesMetadataApplyInvalid(
          :final SeriesMetadataFormValidation validation,
        ):
          setState(() => _validation = validation);
        case SeriesMetadataApplySucceeded():
          showSuccessToast(context, context.l10n.commonSavedToast);
          _leaveAfterSave();
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

  void _updateForm(
    SeriesMetadataForm Function(SeriesMetadataForm form) update,
  ) {
    setState(() => _form = update(_form));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool lockEnabled = !_saving && !_lockBusy;
    return ColoredBox(
      color: cs.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const DetailBackHeader(),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(tokens.spacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: tokens.spacing.lg,
                      children: <Widget>[
                        FluentTextField(
                          labelText: l10n.formSeriesNameLabel,
                          labelTrailing: MetadataLockButton(
                            locked: _locks.name,
                            enabled: lockEnabled,
                            onChanged: (bool locked) => _setLock(name: locked),
                          ),
                          initialValue: _form.name,
                          errorText: _validation?.nameError,
                          enabled: !_saving,
                          onChanged: (String value) {
                            _updateForm(
                              (SeriesMetadataForm form) =>
                                  form.copyWith(name: value),
                            );
                            if (_validation?.nameError != null) {
                              setState(
                                () => _validation = _validation!.copyWith(
                                  nameError: null,
                                ),
                              );
                            }
                          },
                        ),
                        FluentSelectField<SerializationStatus>(
                          labelText: l10n.formSeriesSerializationStatusLabel,
                          labelTrailing: MetadataLockButton(
                            locked: _locks.serializationStatus,
                            enabled: lockEnabled,
                            onChanged: (bool locked) =>
                                _setLock(serializationStatus: locked),
                          ),
                          value: _form.serializationStatus,
                          items: SerializationStatus.values,
                          itemLabel: l10n.serializationStatusLabel,
                          enabled: !_saving,
                          onChanged: (SerializationStatus? value) {
                            if (value == null) {
                              return;
                            }
                            _updateForm(
                              (SeriesMetadataForm form) =>
                                  form.copyWith(serializationStatus: value),
                            );
                          },
                        ),
                        FluentTextField(
                          labelText: l10n.formSeriesTotalCountLabel,
                          labelTrailing: MetadataLockButton(
                            locked: _locks.totalCount,
                            enabled: lockEnabled,
                            onChanged: (bool locked) =>
                                _setLock(totalCount: locked),
                          ),
                          initialValue: _form.totalCountText,
                          errorText: _validation?.totalCountError,
                          enabled: !_saving,
                          keyboardType: TextInputType.number,
                          onChanged: (String value) {
                            _updateForm(
                              (SeriesMetadataForm form) =>
                                  form.copyWith(totalCountText: value),
                            );
                            if (_validation?.totalCountError != null) {
                              setState(
                                () => _validation = _validation!.copyWith(
                                  totalCountError: null,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(tokens.spacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => DetailBackHeader.popOrGoLibrary(context),
                    child: Text(l10n.commonCancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saving ? null : _handleSave,
                    child: _saving
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cs.onPrimary,
                            ),
                          )
                        : Text(l10n.commonSave),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
