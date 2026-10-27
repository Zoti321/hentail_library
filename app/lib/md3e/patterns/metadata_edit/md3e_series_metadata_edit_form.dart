import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_metadata_edit_form_metrics.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/pages/md3e_series_detail_entry.dart';
import 'package:hentai_library/md3e/patterns/metadata_edit/md3e_series_metadata_edit_draft.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_outlined_text_field.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_series_serialization_dropdown.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 系列元数据编辑表单（对齐生产 [EditSeriesDialog] 字段）。
class Md3eSeriesMetadataEditForm extends StatelessWidget {
  const Md3eSeriesMetadataEditForm({
    super.key,
    required this.draft,
    required this.onDraftChanged,
    this.nameError,
    this.totalCountError,
  });

  final Md3eSeriesMetadataEditDraft draft;
  final ValueChanged<Md3eSeriesMetadataEditDraft> onDraftChanged;
  final String? nameError;
  final String? totalCountError;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final Md3eWindowSizeClass sizeClass = md3eWindowSizeClassOf(context);
    final double gap = Md3eMetadataEditFormMetrics.sectionGap(sizeClass);
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
        Text(
          l10n.formSeriesSerializationStatusLabel,
          style: M3ETheme.of(context).typeScale.labelLarge.copyWith(
            color: M3ETheme.of(context).colorScheme.onSurfaceVariant,
          ),
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
