import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/models/value_objects/form/series_metadata_form.dart';
import 'package:hentai_library/domain/models/value_objects/series_meta_locks.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/core/widgets/form/fluent_select_field.dart';
import 'package:hentai_library/ui/core/widgets/form/fluent_text_field.dart';
import 'package:hentai_library/ui/core/widgets/form/metadata_lock_button.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/adaptive_form_surface.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 打开系列编辑表面：medium/expanded 为 dialog，compact 为全页。
Future<void> showEditSeriesDialog({
  required BuildContext context,
  required Series series,
}) {
  return showAdaptiveFormSurfaceWidget<void>(
    context: context,
    surface: EditSeriesDialog(series: series),
  );
}

class EditSeriesDialog extends ConsumerStatefulWidget {
  const EditSeriesDialog({super.key, required this.series});

  final Series series;

  @override
  ConsumerState<EditSeriesDialog> createState() => _EditSeriesDialogState();
}

class _EditSeriesDialogState extends ConsumerState<EditSeriesDialog> {
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
      await ref.read(seriesRepoProvider).setMetaLocks(
        seriesId: widget.series.id,
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
    } catch (error) {
      if (mounted) {
        showErrorToast(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _lockBusy = false);
      }
    }
  }

  Future<void> _handleSave() async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      final SeriesMetadataApplyResult result = await _form.applyTo(
        ref.read(seriesRepoProvider),
        widget.series,
      );
      if (!mounted) {
        return;
      }
      switch (result) {
        case SeriesMetadataApplyInvalid(
          :final SeriesMetadataFormValidation validation,
        ):
          setState(() => _validation = validation);
        case SeriesMetadataApplySucceeded():
          showSuccessToast(context, context.l10n.dialogEditSeriesSavedToast);
          Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        showErrorToast(context, error);
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
    final l10n = context.l10n;
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool lockEnabled = !_saving && !_lockBusy;
    return AdaptiveFormSurface(
      title: l10n.dialogEditSeriesTitle,
      maxDialogWidth: 480,
      body: Column(
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
                (SeriesMetadataForm form) => form.copyWith(name: value),
              );
              if (_validation?.nameError != null) {
                setState(
                  () => _validation = _validation!.copyWith(nameError: null),
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
              onChanged: (bool locked) => _setLock(totalCount: locked),
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
      actions: <Widget>[
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
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
    );
  }
}
