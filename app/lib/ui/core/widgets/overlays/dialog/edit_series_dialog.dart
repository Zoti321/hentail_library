import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/models/value_objects/form/series_metadata_form.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
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
  late final TextEditingController _nameController;
  late final TextEditingController _totalCountController;
  late SerializationStatus _serializationStatus;
  SeriesMetadataFormValidation? _validation;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final SeriesMetadataForm initial = SeriesMetadataForm.fromSeries(
      widget.series,
    );
    _nameController = TextEditingController(text: initial.name);
    _totalCountController = TextEditingController(text: initial.totalCountText);
    _serializationStatus = initial.serializationStatus;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _totalCountController.dispose();
    super.dispose();
  }

  SeriesMetadataForm _draftFromControllers() {
    return SeriesMetadataForm(
      name: _nameController.text,
      serializationStatus: _serializationStatus,
      totalCountText: _totalCountController.text,
    );
  }

  Future<void> _handleSave() async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      final SeriesMetadataApplyResult result = await _draftFromControllers()
          .applyTo(
            ref.read(seriesRepoProvider),
            seriesId: widget.series.id,
          );
      if (!mounted) {
        return;
      }
      switch (result) {
        case SeriesMetadataApplyInvalid(:final SeriesMetadataFormValidation validation):
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    return AdaptiveFormSurface(
      title: l10n.dialogEditSeriesTitle,
      maxDialogWidth: 480,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: tokens.spacing.md,
        children: <Widget>[
          TextField(
            controller: _nameController,
            enabled: !_saving,
            onChanged: (_) {
              if (_validation?.nameError != null) {
                setState(
                  () => _validation = SeriesMetadataFormValidation(
                    nameError: null,
                    totalCountError: _validation?.totalCountError,
                  ),
                );
              }
            },
            decoration: InputDecoration(
              labelText: l10n.formSeriesNameLabel,
              border: const OutlineInputBorder(),
              isDense: true,
              errorText: _validation?.nameError,
            ),
          ),
          DropdownButtonFormField<SerializationStatus>(
            value: _serializationStatus,
            decoration: InputDecoration(
              labelText: l10n.formSeriesSerializationStatusLabel,
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: SerializationStatus.values
                .map(
                  (SerializationStatus status) =>
                      DropdownMenuItem<SerializationStatus>(
                        value: status,
                        child: Text(context.l10n.serializationStatusLabel(status)),
                      ),
                )
                .toList(),
            onChanged: _saving
                ? null
                : (SerializationStatus? value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _serializationStatus = value);
                  },
          ),
          TextField(
            controller: _totalCountController,
            enabled: !_saving,
            keyboardType: TextInputType.number,
            onChanged: (_) {
              if (_validation?.totalCountError != null) {
                setState(
                  () => _validation = SeriesMetadataFormValidation(
                    nameError: _validation?.nameError,
                    totalCountError: null,
                  ),
                );
              }
            },
            decoration: InputDecoration(
              labelText: l10n.formSeriesTotalCountLabel,
              hintText: l10n.formSeriesTotalCountHint,
              border: const OutlineInputBorder(),
              isDense: true,
              errorText: _validation?.totalCountError,
            ),
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
