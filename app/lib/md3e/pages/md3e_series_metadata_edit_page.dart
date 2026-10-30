import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/layout/md3e_metadata_edit_form_metrics.dart';
import 'package:hentai_library/md3e/motion/md3e_motion.dart';
import 'package:hentai_library/md3e/pages/md3e_series_detail_page_preview_data.dart';
import 'package:hentai_library/md3e/patterns/metadata_edit/md3e_metadata_edit_surface.dart';
import 'package:hentai_library/md3e/patterns/metadata_edit/md3e_series_metadata_edit_draft.dart';
import 'package:hentai_library/md3e/patterns/metadata_edit/md3e_series_metadata_edit_form.dart';
import 'package:hentai_library/shared/domain/models/value_objects/series_meta_locks.dart';

export 'package:hentai_library/md3e/patterns/metadata_edit/md3e_series_metadata_edit_draft.dart';

/// 系列元数据编辑 Lab 页。
class Md3eSeriesMetadataEditPage extends StatefulWidget {
  const Md3eSeriesMetadataEditPage({
    super.key,
    this.initialDraft,
    this.presentation = Md3eMetadataEditPresentation.embedded,
    this.onSaved,
    this.onCancel,
  });

  final Md3eSeriesMetadataEditDraft? initialDraft;
  final Md3eMetadataEditPresentation presentation;
  final ValueChanged<Md3eSeriesMetadataEditDraft>? onSaved;
  final VoidCallback? onCancel;

  @override
  State<Md3eSeriesMetadataEditPage> createState() =>
      _Md3eSeriesMetadataEditPageState();
}

class _Md3eSeriesMetadataEditPageState extends State<Md3eSeriesMetadataEditPage> {
  late Md3eSeriesMetadataEditDraft _draft = widget.initialDraft ??
      Md3eSeriesMetadataEditDraft.fromEntry(
        Md3eSeriesDetailPagePreviewData.sample(),
      );
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
    await Future<void>.delayed(Md3eMotion.labSimulatedSaveDuration);
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

    return Md3eMetadataEditSurface(
      presentation: widget.presentation,
      maxWidth: Md3eMetadataEditFormMetrics.seriesMaxWidth,
      title: l10n.dialogEditSeriesTitle,
      onCancel: _handleCancel,
      onSave: _handleSave,
      saving: _saving,
      body: Md3eSeriesMetadataEditForm(
        draft: _draft,
        locks: _locks,
        onLockChanged: _onLockChanged,
        nameError: _nameError,
        totalCountError: _totalCountError,
        onDraftChanged: (Md3eSeriesMetadataEditDraft value) {
          setState(() {
            _draft = value;
            if (_nameError != null && value.validateName() == null) {
              _nameError = null;
            }
            if (_totalCountError != null && value.validateTotalCount() == null) {
              _totalCountError = null;
            }
          });
        },
      ),
    );
  }
}
