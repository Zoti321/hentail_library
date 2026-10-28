import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_metadata_edit_form_metrics.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/pages/md3e_series_detail_entry.dart';
import 'package:hentai_library/md3e/patterns/metadata_edit/md3e_metadata_field_label_row.dart';
import 'package:hentai_library/md3e/patterns/metadata_edit/md3e_metadata_lock_callbacks.dart';
import 'package:hentai_library/md3e/patterns/metadata_edit/md3e_series_metadata_edit_draft.dart';
import 'package:hentai_library/md3e/patterns/metadata_edit/md3e_series_metadata_locks_pane.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_outlined_text_field.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_series_serialization_dropdown.dart';
import 'package:hentai_library/md3e/widgets/selection/md3e_segmented_capsule_bar.dart';
import 'package:hentai_library/shared/domain/models/value_objects/series_meta_locks.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

enum _Md3eSeriesMetadataEditTab { content, fieldLocks }

/// 系列元数据编辑表单（对齐生产 [EditSeriesDialog] 字段）。
class Md3eSeriesMetadataEditForm extends StatefulWidget {
  const Md3eSeriesMetadataEditForm({
    super.key,
    required this.draft,
    required this.onDraftChanged,
    required this.locks,
    required this.onLockChanged,
    this.nameError,
    this.totalCountError,
  });

  final Md3eSeriesMetadataEditDraft draft;
  final ValueChanged<Md3eSeriesMetadataEditDraft> onDraftChanged;
  final SeriesMetaLocks locks;
  final Md3eSeriesMetadataLockChanged onLockChanged;
  final String? nameError;
  final String? totalCountError;

  @override
  State<Md3eSeriesMetadataEditForm> createState() =>
      _Md3eSeriesMetadataEditFormState();
}

class _Md3eSeriesMetadataEditFormState extends State<Md3eSeriesMetadataEditForm> {
  _Md3eSeriesMetadataEditTab _tab = _Md3eSeriesMetadataEditTab.content;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final Md3eWindowSizeClass sizeClass = md3eWindowSizeClassOf(context);
    final double gap = Md3eMetadataEditFormMetrics.sectionGap(sizeClass);

    final Widget tabBody = switch (_tab) {
      _Md3eSeriesMetadataEditTab.content => _SeriesContentFields(
        draft: widget.draft,
        onDraftChanged: widget.onDraftChanged,
        nameError: widget.nameError,
        totalCountError: widget.totalCountError,
        gap: gap,
        l10n: l10n,
      ),
      _Md3eSeriesMetadataEditTab.fieldLocks => Md3eSeriesMetadataLocksPane(
        locks: widget.locks,
        onLockChanged: widget.onLockChanged,
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Md3eSegmentedCapsuleBar(
          segments: <Md3eSegmentedCapsuleSegment>[
            Md3eSegmentedCapsuleSegment(label: l10n.dialogEditMetadataTabContent),
            Md3eSegmentedCapsuleSegment(label: l10n.dialogEditMetadataTabFieldLocks),
          ],
          selectedIndex: _tab.index,
          onSelected: (int index) {
            setState(() => _tab = _Md3eSeriesMetadataEditTab.values[index]);
          },
        ),
        SizedBox(height: gap),
        tabBody,
      ],
    );
  }
}

class _SeriesContentFields extends StatelessWidget {
  const _SeriesContentFields({
    required this.draft,
    required this.onDraftChanged,
    required this.nameError,
    required this.totalCountError,
    required this.gap,
    required this.l10n,
  });

  final Md3eSeriesMetadataEditDraft draft;
  final ValueChanged<Md3eSeriesMetadataEditDraft> onDraftChanged;
  final String? nameError;
  final String? totalCountError;
  final double gap;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final M3ESpacing spacing = M3ETheme.of(context).spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Md3eOutlinedTextField(
          label: l10n.formSeriesNameLabel,
          initialValue: draft.name,
          errorText: nameError,
          onChanged: (String value) =>
              onDraftChanged(draft.copyWith(name: value)),
        ),
        SizedBox(height: gap),
        Md3eMetadataFieldLabelRow(
          label: l10n.formSeriesSerializationStatusLabel,
        ),
        SizedBox(height: spacing.sm),
        Md3eSeriesSerializationDropdown(
          value: draft.serializationStatus,
          onChanged: (Md3eSeriesSerializationStatus status) {
            onDraftChanged(draft.copyWith(serializationStatus: status));
          },
        ),
        SizedBox(height: gap),
        Md3eOutlinedTextField(
          label: l10n.formSeriesTotalCountLabel,
          initialValue: draft.totalCountText,
          hintText: l10n.formSeriesTotalCountHint,
          errorText: totalCountError,
          keyboardType: TextInputType.number,
          onChanged: (String value) =>
              onDraftChanged(draft.copyWith(totalCountText: value)),
        ),
      ],
    );
  }
}
