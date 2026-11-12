import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/series/presentation/views/series_detail/series_detail_view_object.dart';
import 'package:hentai_library/features/series/presentation/patterns/metadata_edit/series_metadata_edit_draft.dart';
import 'package:hentai_library/features/series/presentation/patterns/metadata_edit/series_metadata_locks_pane.dart';
import 'package:hentai_library/features/series/presentation/patterns/metadata_edit/series_serialization_dropdown.dart';
import 'package:hentai_library/features/series/domain/value_objects/series_meta_locks.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:hentai_library/shared/ui/catalog/metadata_edit/metadata_lock_callbacks.dart';

/// 系列元数据编辑表单（对齐生产 [EditSeriesDialog] 字段）。
class SeriesMetadataEditForm extends StatefulWidget {
  const SeriesMetadataEditForm({
    super.key,
    required this.draft,
    required this.onDraftChanged,
    required this.locks,
    required this.onLockChanged,
    this.nameError,
    this.totalCountError,
  });

  final SeriesMetadataEditDraft draft;
  final ValueChanged<SeriesMetadataEditDraft> onDraftChanged;
  final SeriesMetaLocks locks;
  final SeriesMetadataLockChanged onLockChanged;
  final String? nameError;
  final String? totalCountError;

  @override
  State<SeriesMetadataEditForm> createState() => _SeriesMetadataEditFormState();
}

class _SeriesMetadataEditFormState extends State<SeriesMetadataEditForm> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final WindowSizeClass sizeClass = windowSizeClassOf(context);
    final double gap = MetadataEditFormMetrics.sectionGap(sizeClass);

    return MetadataEditTabbedShell(
      selectedIndex: _tabIndex,
      onSelected: (int index) => setState(() => _tabIndex = index),
      tabs: <MetadataEditTab>[
        (
          label: l10n.dialogEditMetadataTabContent,
          body: _SeriesContentFields(
            draft: widget.draft,
            onDraftChanged: widget.onDraftChanged,
            nameError: widget.nameError,
            totalCountError: widget.totalCountError,
            gap: gap,
            l10n: l10n,
          ),
        ),
        (
          label: l10n.dialogEditMetadataTabFieldLocks,
          body: SeriesMetadataLocksPane(
            locks: widget.locks,
            onLockChanged: widget.onLockChanged,
          ),
        ),
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

  final SeriesMetadataEditDraft draft;
  final ValueChanged<SeriesMetadataEditDraft> onDraftChanged;
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
        OutlinedTextField(
          label: l10n.formSeriesNameLabel,
          initialValue: draft.name,
          errorText: nameError,
          onChanged: (String value) =>
              onDraftChanged(draft.copyWith(name: value)),
        ),
        SizedBox(height: gap),
        MetadataFieldLabelRow(label: l10n.formSeriesSerializationStatusLabel),
        SizedBox(height: spacing.sm),
        SeriesSerializationDropdown(
          value: draft.serializationStatus,
          onChanged: (SerializationStatus status) {
            onDraftChanged(draft.copyWith(serializationStatus: status));
          },
        ),
        SizedBox(height: gap),
        OutlinedTextField(
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
