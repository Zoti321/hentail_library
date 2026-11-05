import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/metadata_edit_form_metrics.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/series/presentation/views/series_detail_md3e/series_detail_page_entry.dart';
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

class _Md3eSeriesMetadataEditFormState
    extends State<Md3eSeriesMetadataEditForm> {
  _Md3eSeriesMetadataEditTab _tab = _Md3eSeriesMetadataEditTab.content;

  Widget _scrollPane(Widget child) {
    return ScrollConfiguration(
      behavior: Md3eMetadataEditScrollBehavior(),
      child: SingleChildScrollView(primary: false, child: child),
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
            width: Md3eMetadataEditFormMetrics.sideTabColumnWidth,
            child: _scrollPane(_SideTabList(l10n: l10n, tab: _tab, onSelected: _selectTab)),
          ),
          SizedBox(width: gap),
          Expanded(
            child: Md3eListDetailDetailTransition(
              switchKey: _tab,
              child: _scrollPane(tabBody),
            ),
          ),
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
          Md3eSegmentedCapsuleBar(
            segments: <Md3eSegmentedCapsuleSegment>[
              Md3eSegmentedCapsuleSegment(
                label: l10n.dialogEditMetadataTabContent,
              ),
              Md3eSegmentedCapsuleSegment(
                label: l10n.dialogEditMetadataTabFieldLocks,
              ),
            ],
            selectedIndex: _tab.index,
            onSelected: (int index) {
              setState(() => _tab = _Md3eSeriesMetadataEditTab.values[index]);
            },
          ),
          SizedBox(height: gap),
          Expanded(
            child: Md3eListDetailDetailTransition(
              switchKey: _tab,
              child: _scrollPane(tabBody),
            ),
          ),
        ],
      ),
    );
  }

  void _selectTab(int index) {
    setState(() => _tab = _Md3eSeriesMetadataEditTab.values[index]);
  }

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

    final bool useSideTabs =
        sizeClass.index >= Md3eWindowSizeClass.medium.index;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewportHeight =
            Md3eMetadataEditFormMetrics.resolveTabbedViewportHeight(
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
  final _Md3eSeriesMetadataEditTab tab;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final List<(String label, _Md3eSeriesMetadataEditTab value)> items =
        <(String, _Md3eSeriesMetadataEditTab)>[
          (l10n.dialogEditMetadataTabContent, _Md3eSeriesMetadataEditTab.content),
          (
            l10n.dialogEditMetadataTabFieldLocks,
            _Md3eSeriesMetadataEditTab.fieldLocks,
          ),
        ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final (String label, _Md3eSeriesMetadataEditTab value) in items)
          Md3eListDetailNavItem(
            key: ValueKey<_Md3eSeriesMetadataEditTab>(value),
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
