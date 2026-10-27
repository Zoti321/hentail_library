import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_metadata_edit_form_metrics.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/pages/md3e_series_detail_entry.dart';
import 'package:hentai_library/md3e/patterns/metadata_edit/md3e_series_metadata_edit_draft.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_outlined_text_field.dart';
import 'package:hentai_library/md3e/widgets/selection/md3e_segmented_capsule_bar.dart';
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

    final List<Md3eSeriesSerializationStatus> statuses =
        <Md3eSeriesSerializationStatus>[
          Md3eSeriesSerializationStatus.ongoing,
          Md3eSeriesSerializationStatus.ended,
          Md3eSeriesSerializationStatus.hiatus,
        ];

    int selectedIndex = statuses.indexOf(draft.serializationStatus);
    if (selectedIndex < 0) {
      selectedIndex = 0;
    }

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
        SizedBox(height: M3ETheme.of(context).spacing.sm),
        Md3eSegmentedCapsuleBar(
          segments: statuses
              .map(
                (Md3eSeriesSerializationStatus s) => Md3eSegmentedCapsuleSegment(
                  label: _serializationLabel(l10n, s),
                ),
              )
              .toList(),
          selectedIndex: selectedIndex,
          onSelected: (int index) {
            onDraftChanged(
              draft.copyWith(serializationStatus: statuses[index]),
            );
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

  static String _serializationLabel(
    AppLocalizations l10n,
    Md3eSeriesSerializationStatus status,
  ) {
    return switch (status) {
      Md3eSeriesSerializationStatus.ongoing => l10n.serializationStatusOngoing,
      Md3eSeriesSerializationStatus.ended => l10n.serializationStatusEnded,
      Md3eSeriesSerializationStatus.hiatus => l10n.serializationStatusHiatus,
      Md3eSeriesSerializationStatus.unknown => l10n.serializationStatusUnknown,
    };
  }
}
