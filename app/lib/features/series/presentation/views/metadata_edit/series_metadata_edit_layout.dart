import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/layout/metadata_edit_form_metrics.dart';
import 'package:hentai_library/shared/ui/motion/motion.dart';
import 'package:hentai_library/shared/ui/patterns/metadata_edit/metadata_edit_surface.dart';
import 'package:hentai_library/features/series/presentation/patterns/metadata_edit/series_metadata_edit_draft.dart';
import 'package:hentai_library/features/series/presentation/patterns/metadata_edit/series_metadata_edit_form.dart';
import 'package:hentai_library/shared/domain/models/value_objects/series_meta_locks.dart';

export 'package:hentai_library/features/series/presentation/patterns/metadata_edit/series_metadata_edit_draft.dart';

/// 系列元数据编辑 Lab 页。
class SeriesMetadataEditLayout extends StatefulWidget {
  const SeriesMetadataEditLayout({
    super.key,
    required this.initialDraft,
    this.presentation = MetadataEditPresentation.embedded,
    this.onSaved,
    this.onCancel,
  });

  final SeriesMetadataEditDraft initialDraft;
  final MetadataEditPresentation presentation;
  final ValueChanged<SeriesMetadataEditDraft>? onSaved;
  final VoidCallback? onCancel;

  @override
  State<SeriesMetadataEditLayout> createState() =>
      _SeriesMetadataEditPageState();
}

class _SeriesMetadataEditPageState
    extends State<SeriesMetadataEditLayout> {
  late SeriesMetadataEditDraft _draft = widget.initialDraft;
  String? _nameError;
  String? _totalCountError;
  bool _saving = false;
  SeriesMetaLocks _locks = SeriesMetaLocks.unlocked;

  void _onLockChanged({
    bool? name,
    bool? serializationStatus,
    bool? totalCount,
  }) {
    setState(
      () => _locks = _locks.copyWith(
        name: name,
        serializationStatus: serializationStatus,
        totalCount: totalCount,
      ),
    );
  }

  void _handleCancel() {
    widget.onCancel?.call();
    if (widget.onCancel == null && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  Future<void> saveAndPop() => _handleSave();

  Future<void> _handleSave() async {
    final String? nameError = _draft.validateName();
    final String? totalError = _draft.validateTotalCount();
    if (nameError != null || totalError != null) {
      setState(() {
        _nameError = nameError;
        _totalCountError = totalError;
      });
      return;
    }
    setState(() => _saving = true);
    await Future<void>.delayed(LabMotion.labSimulatedSaveDuration);
    if (!mounted) {
      return;
    }
    widget.onSaved?.call(_draft);
    setState(() => _saving = false);
    if (widget.onSaved == null && Navigator.canPop(context)) {
      Navigator.of(context).pop(_draft);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return MetadataEditSurface(
      presentation: widget.presentation,
      maxWidth: MetadataEditFormMetrics.seriesMaxWidth,
      title: l10n.dialogEditSeriesTitle,
      onCancel: _handleCancel,
      onSave: _handleSave,
      saving: _saving,
      body: SeriesMetadataEditForm(
        draft: _draft,
        locks: _locks,
        onLockChanged: _onLockChanged,
        nameError: _nameError,
        totalCountError: _totalCountError,
        onDraftChanged: (SeriesMetadataEditDraft value) {
          setState(() {
            _draft = value;
            if (_nameError != null && value.validateName() == null) {
              _nameError = null;
            }
            if (_totalCountError != null &&
                value.validateTotalCount() == null) {
              _totalCountError = null;
            }
          });
        },
      ),
    );
  }
}
