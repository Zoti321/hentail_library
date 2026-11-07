import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/metadata_edit_form_metrics.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/series/presentation/views/series_detail/series_detail_view_object.dart';
import 'package:hentai_library/shared/ui/patterns/metadata_edit/metadata_edit_form_scroll.dart';
import 'package:hentai_library/shared/ui/patterns/metadata_edit/metadata_field_label_row.dart';
import 'package:hentai_library/features/series/presentation/patterns/metadata_edit/series_metadata_edit_draft.dart';
import 'package:hentai_library/features/series/presentation/patterns/metadata_edit/series_metadata_locks_pane.dart';
import 'package:hentai_library/shared/ui/widgets/inputs/outlined_text_field.dart';
import 'package:hentai_library/shared/ui/widgets/inputs/series_serialization_dropdown.dart';
import 'package:hentai_library/shared/ui/widgets/list_detail/list_detail_detail_transition.dart';
import 'package:hentai_library/shared/ui/widgets/list_detail/list_detail_nav_item.dart';
import 'package:hentai_library/shared/ui/widgets/selection/segmented_capsule_bar.dart';
import 'package:hentai_library/shared/domain/models/value_objects/series_meta_locks.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:hentai_library/features/library_browse/public/catalog/for_comic_and_series.dart';

enum _SeriesMetadataEditTab { content, fieldLocks }

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
  _SeriesMetadataEditTab _tab = _SeriesMetadataEditTab.content;
  bool _detailTransitionReverse = false;

  Widget _scrollPane(Widget child) {
    return ScrollConfiguration(
      behavior: MetadataEditScrollBehavior(),
      child: SingleChildScrollView(primary: false, child: child),
    );
  }

  Widget _detailTransition(Widget child) {
    return ListDetailDetailTransition(
      switchKey: _tab,
      reverse: _detailTransitionReverse,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MetadataEditFormMetrics.detailContentHorizontalInset,
        ),
        child: child,
      ),
    );
  }

  Widget _sideTabLayout({
    required double viewportHeight,
    required double gap,
    required AppLocalizations l10n,
    required Widget tabBody,
  }) {
    return SizedBox(
      height: viewportHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: MetadataEditFormMetrics.sideTabColumnWidth,
            child: _scrollPane(
              _SideTabList(l10n: l10n, tab: _tab, onSelected: _selectTab),
            ),
          ),
          SizedBox(width: gap),
          Expanded(child: _detailTransition(_scrollPane(tabBody))),
        ],
      ),
    );
  }

  Widget _topTabLayout({
    required double viewportHeight,
    required double gap,
    required AppLocalizations l10n,
    required Widget tabBody,
  }) {
    return SizedBox(
      height: viewportHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SegmentedCapsuleBar(
            segments: <SegmentedCapsuleSegment>[
              SegmentedCapsuleSegment(label: l10n.dialogEditMetadataTabContent),
              SegmentedCapsuleSegment(
                label: l10n.dialogEditMetadataTabFieldLocks,
              ),
            ],
            selectedIndex: _tab.index,
            onSelected: _selectTab,
          ),
          SizedBox(height: gap),
          Expanded(child: _detailTransition(_scrollPane(tabBody))),
        ],
      ),
    );
  }

  void _selectTab(int index) {
    setState(() {
      final _SeriesMetadataEditTab next = _SeriesMetadataEditTab.values[index];
      _detailTransitionReverse = next.index < _tab.index;
      _tab = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final WindowSizeClass sizeClass = windowSizeClassOf(context);
    final double gap = MetadataEditFormMetrics.sectionGap(sizeClass);

    final Widget tabBody = switch (_tab) {
      _SeriesMetadataEditTab.content => _SeriesContentFields(
        draft: widget.draft,
        onDraftChanged: widget.onDraftChanged,
        nameError: widget.nameError,
        totalCountError: widget.totalCountError,
        gap: gap,
        l10n: l10n,
      ),
      _SeriesMetadataEditTab.fieldLocks => SeriesMetadataLocksPane(
        locks: widget.locks,
        onLockChanged: widget.onLockChanged,
      ),
    };

    final bool useSideTabs = sizeClass.index >= WindowSizeClass.medium.index;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewportHeight =
            MetadataEditFormMetrics.resolveTabbedViewportHeight(
              context,
              constraints,
            );

        if (useSideTabs) {
          return _sideTabLayout(
            viewportHeight: viewportHeight,
            gap: gap,
            l10n: l10n,
            tabBody: tabBody,
          );
        }

        return _topTabLayout(
          viewportHeight: viewportHeight,
          gap: gap,
          l10n: l10n,
          tabBody: tabBody,
        );
      },
    );
  }
}

class _SideTabList extends StatelessWidget {
  const _SideTabList({
    required this.l10n,
    required this.tab,
    required this.onSelected,
  });

  final AppLocalizations l10n;
  final _SeriesMetadataEditTab tab;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final List<(String label, _SeriesMetadataEditTab value)> items =
        <(String, _SeriesMetadataEditTab)>[
          (l10n.dialogEditMetadataTabContent, _SeriesMetadataEditTab.content),
          (
            l10n.dialogEditMetadataTabFieldLocks,
            _SeriesMetadataEditTab.fieldLocks,
          ),
        ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final (String label, _SeriesMetadataEditTab value) in items)
          ListDetailNavItem(
            key: ValueKey<_SeriesMetadataEditTab>(value),
            label: label,
            selected: tab == value,
            onTap: () => onSelected(value.index),
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
          onChanged: (SeriesSerializationStatus status) {
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
