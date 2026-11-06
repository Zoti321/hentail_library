import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/metadata_edit_form_metrics.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/comic/presentation/patterns/metadata_edit/comic_metadata_edit_draft.dart';
import 'package:hentai_library/features/comic/presentation/patterns/metadata_edit/comic_metadata_locks_pane.dart';
import 'package:hentai_library/shared/ui/patterns/metadata_edit/metadata_field_label_row.dart';
import 'package:hentai_library/shared/ui/patterns/metadata_edit/metadata_edit_form_scroll.dart';
import 'package:hentai_library/shared/ui/widgets/list_detail/list_detail_detail_transition.dart';
import 'package:hentai_library/shared/ui/widgets/list_detail/list_detail_nav_item.dart';
import 'package:hentai_library/shared/ui/widgets/inputs/comic_language_quick_pick.dart';
import 'package:hentai_library/shared/domain/models/value_objects/comic_meta_locks.dart';
import 'package:hentai_library/shared/ui/widgets/inputs/outlined_text_field.dart';
import 'package:hentai_library/shared/ui/widgets/inputs/published_date_text_field.dart';
import 'package:hentai_library/features/comic/presentation/view_models/comic_metadata_smart_facet_providers.dart';
import 'package:hentai_library/features/comic/presentation/views/widgets/form/author_library_multi_select_field.dart';
import 'package:hentai_library/features/comic/presentation/views/widgets/form/character_library_multi_select_field.dart';
import 'package:hentai_library/features/comic/presentation/views/widgets/form/parody_library_multi_select_field.dart';
import 'package:hentai_library/features/comic/presentation/views/widgets/form/tag_library_multi_select_field.dart';
import 'package:hentai_library/shared/ui/widgets/selection/segmented_capsule_bar.dart';
import 'package:hentai_library/shared/ui/widgets/settings/content_section.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_tile.dart';
import 'package:hentai_library/shared/ui/widgets/inputs/tag_input_field.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:hentai_library/features/library_browse/public/catalog/for_comic_and_series.dart';

enum _ComicMetadataEditTab { general, authorsTags, fieldLocks }

List<String> TagListWithAdded(List<String> list, String value) {
  if (list.contains(value)) {
    return list;
  }
  return <String>[...list, value];
}

List<String> TagListWithRemoved(List<String> list, String value) {
  return list.where((String e) => e != value).toList();
}

/// 漫画元数据编辑表单主体（常规 + 作者&标签），字段对齐生产 [EditMetadataDialog]。
class ComicMetadataEditForm extends StatefulWidget {
  const ComicMetadataEditForm({
    super.key,
    required this.draft,
    required this.onDraftChanged,
    required this.locks,
    required this.onLockChanged,
    required this.smartFacetScope,
    this.titleError,
  });

  final ComicMetadataEditDraft draft;
  final ValueChanged<ComicMetadataEditDraft> onDraftChanged;
  final ComicMetaLocks locks;
  final ComicMetadataLockChanged onLockChanged;
  final ComicMetadataSmartFacetScope smartFacetScope;
  final String? titleError;

  @override
  State<ComicMetadataEditForm> createState() => _ComicMetadataEditFormState();
}

class _ComicMetadataEditFormState extends State<ComicMetadataEditForm> {
  _ComicMetadataEditTab _tab = _ComicMetadataEditTab.general;

  void _update(ComicMetadataEditDraft Function(ComicMetadataEditDraft d) fn) {
    widget.onDraftChanged(fn(widget.draft));
  }

  Widget _scrollPane(Widget child) {
    return ScrollConfiguration(
      behavior: MetadataEditScrollBehavior(),
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
            width: MetadataEditFormMetrics.sideTabColumnWidth,
            child: _scrollPane(
              _SideTabList(l10n: l10n, tab: _tab, onSelected: _selectTab),
            ),
          ),
          SizedBox(width: gap),
          Expanded(
            child: ListDetailDetailTransition(
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
          _TopTabBar(l10n: l10n, tab: _tab, onSelected: _selectTab),
          SizedBox(height: gap),
          Expanded(
            child: ListDetailDetailTransition(
              switchKey: _tab,
              child: _scrollPane(tabBody),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final WindowSizeClass sizeClass = windowSizeClassOf(context);
    final double gap = MetadataEditFormMetrics.sectionGap(sizeClass);
    final ComicMetadataEditDraft draft = widget.draft;

    final Widget tabBody = switch (_tab) {
      _ComicMetadataEditTab.general => _GeneralFields(
        draft: draft,
        titleError: widget.titleError,
        gap: gap,
        onTitleChanged: (String v) => _update((d) => d.copyWith(title: v)),
        onDescriptionChanged: (String v) =>
            _update((d) => d.copyWith(description: v)),
        onPublishedChanged: (String v) =>
            _update((d) => d.copyWith(publishedLabel: v)),
        onR18Changed: (bool v) => _update((d) => d.copyWith(isR18: v)),
        onLanguageAdded: (String v) => _update(
          (d) => d.copyWith(languages: TagListWithAdded(d.languages, v)),
        ),
        onLanguageRemoved: (String v) => _update(
          (d) => d.copyWith(languages: TagListWithRemoved(d.languages, v)),
        ),
        onSortOrderChanged: (String v) =>
            _update((d) => d.copyWith(seriesSortOrderText: v)),
      ),
      _ComicMetadataEditTab.authorsTags => _AuthorsTagsFields(
        draft: draft,
        gap: gap,
        l10n: l10n,
        scope: widget.smartFacetScope,
        onParodiesChanged: (List<String> v) =>
            _update((d) => d.copyWith(parodies: v)),
        onAuthorsChanged: (List<String> v) =>
            _update((d) => d.copyWith(authors: v)),
        onCharactersChanged: (List<String> v) =>
            _update((d) => d.copyWith(characters: v)),
        onTagsChanged: (List<String> v) => _update((d) => d.copyWith(tags: v)),
      ),
      _ComicMetadataEditTab.fieldLocks => ComicMetadataLocksPane(
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

  void _selectTab(int index) {
    setState(() => _tab = _ComicMetadataEditTab.values[index]);
  }
}

class _TopTabBar extends StatelessWidget {
  const _TopTabBar({
    required this.l10n,
    required this.tab,
    required this.onSelected,
  });

  final AppLocalizations l10n;
  final _ComicMetadataEditTab tab;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SegmentedCapsuleBar(
      segments: <SegmentedCapsuleSegment>[
        SegmentedCapsuleSegment(label: l10n.dialogEditMetadataTabGeneral),
        SegmentedCapsuleSegment(label: l10n.dialogEditMetadataTabAuthorsTags),
        SegmentedCapsuleSegment(label: l10n.dialogEditMetadataTabFieldLocks),
      ],
      selectedIndex: tab.index,
      onSelected: onSelected,
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
  final _ComicMetadataEditTab tab;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final List<(String label, _ComicMetadataEditTab value)> items =
        <(String, _ComicMetadataEditTab)>[
          (l10n.dialogEditMetadataTabGeneral, _ComicMetadataEditTab.general),
          (
            l10n.dialogEditMetadataTabAuthorsTags,
            _ComicMetadataEditTab.authorsTags,
          ),
          (
            l10n.dialogEditMetadataTabFieldLocks,
            _ComicMetadataEditTab.fieldLocks,
          ),
        ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final (String label, _ComicMetadataEditTab value) in items)
          ListDetailNavItem(
            key: ValueKey<_ComicMetadataEditTab>(value),
            label: label,
            selected: tab == value,
            onTap: () => onSelected(value.index),
          ),
      ],
    );
  }
}

class _GeneralFields extends StatelessWidget {
  const _GeneralFields({
    required this.draft,
    required this.titleError,
    required this.gap,
    required this.onTitleChanged,
    required this.onDescriptionChanged,
    required this.onPublishedChanged,
    required this.onR18Changed,
    required this.onLanguageAdded,
    required this.onLanguageRemoved,
    required this.onSortOrderChanged,
  });

  final ComicMetadataEditDraft draft;
  final String? titleError;
  final double gap;
  final ValueChanged<String> onSortOrderChanged;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onDescriptionChanged;
  final ValueChanged<String> onPublishedChanged;
  final ValueChanged<bool> onR18Changed;
  final ValueChanged<String> onLanguageAdded;
  final ValueChanged<String> onLanguageRemoved;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        OutlinedTextField(
          label: l10n.formComicTitleLabel,
          initialValue: draft.title,
          hintText: l10n.formComicTitleHint,
          errorText: titleError,
          onChanged: onTitleChanged,
        ),
        SizedBox(height: gap),
        OutlinedTextField(
          label: l10n.formComicDescriptionLabel,
          initialValue: draft.description,
          hintText: l10n.formComicDescriptionHint,
          maxLines: 4,
          onChanged: onDescriptionChanged,
        ),
        SizedBox(height: gap),
        PublishedDateTextField(
          label: l10n.formPublishedDateLabel,
          value: draft.publishedLabel,
          onChanged: onPublishedChanged,
        ),
        SizedBox(height: gap),
        ContentSection.group(
          title: l10n.formAgeRestrictionLabel,
          children: <Widget>[
            SettingsSwitchTile(
              leading: Symbols.eighteen_up_rating,
              title: Text(draft.isR18 ? 'R18' : l10n.filterAgeAllAges),
              description: Text(l10n.formAgeRestrictionLabel),
              value: draft.isR18,
              onChanged: onR18Changed,
            ),
          ],
        ),
        SizedBox(height: gap),
        MetadataFieldLabelRow(label: l10n.formLanguagesLabel),
        SizedBox(height: M3ETheme.of(context).spacing.sm),
        ComicLanguageQuickPick(
          selected: draft.languages,
          onCanonicalToggled: (String canonical) {
            if (draft.languages.contains(canonical)) {
              onLanguageRemoved(canonical);
            } else {
              onLanguageAdded(canonical);
            }
          },
        ),
        SizedBox(height: M3ETheme.of(context).spacing.sm),
        TagInputField(
          label: l10n.metadataAdd,
          tags: draft.languages,
          onTagCommitted: onLanguageAdded,
          onTagRemoved: onLanguageRemoved,
          maxWidth: double.infinity,
        ),
        if (draft.seriesSortOrderText != null) ...<Widget>[
          SizedBox(height: gap),
          OutlinedTextField(
            label: l10n.formSeriesItemSortOrderLabel,
            initialValue: draft.seriesSortOrderText!,
            hintText: l10n.formSeriesItemSortOrderHint,
            onChanged: onSortOrderChanged,
          ),
        ],
      ],
    );
  }
}

class _AuthorsTagsFields extends ConsumerWidget {
  const _AuthorsTagsFields({
    required this.draft,
    required this.gap,
    required this.l10n,
    required this.scope,
    required this.onParodiesChanged,
    required this.onAuthorsChanged,
    required this.onCharactersChanged,
    required this.onTagsChanged,
  });

  final ComicMetadataEditDraft draft;
  final double gap;
  final AppLocalizations l10n;
  final ComicMetadataSmartFacetScope scope;
  final ValueChanged<List<String>> onParodiesChanged;
  final ValueChanged<List<String>> onAuthorsChanged;
  final ValueChanged<List<String>> onCharactersChanged;
  final ValueChanged<List<String>> onTagsChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ParodyLibraryMultiSelectField(
          label: l10n.comicDetailParodies,
          icon: Symbols.category,
          scope: scope,
          selectedNames: draft.parodies,
          onAdd: (String v) =>
              onParodiesChanged(TagListWithAdded(draft.parodies, v)),
          onRemove: (String v) =>
              onParodiesChanged(TagListWithRemoved(draft.parodies, v)),
          onClearAll: () => onParodiesChanged(const <String>[]),
        ),
        SizedBox(height: gap),
        AuthorLibraryMultiSelectField(
          label: l10n.comicDetailAuthors,
          icon: Symbols.person,
          scope: scope,
          selectedNames: draft.authors,
          onAdd: (String v) =>
              onAuthorsChanged(TagListWithAdded(draft.authors, v)),
          onRemove: (String v) =>
              onAuthorsChanged(TagListWithRemoved(draft.authors, v)),
          onClearAll: () => onAuthorsChanged(const <String>[]),
        ),
        SizedBox(height: gap),
        CharacterLibraryMultiSelectField(
          label: l10n.comicDetailCharacters,
          icon: Symbols.groups,
          scope: scope,
          selectedNames: draft.characters,
          onAdd: (String v) =>
              onCharactersChanged(TagListWithAdded(draft.characters, v)),
          onRemove: (String v) =>
              onCharactersChanged(TagListWithRemoved(draft.characters, v)),
          onClearAll: () => onCharactersChanged(const <String>[]),
        ),
        SizedBox(height: gap),
        TagLibraryMultiSelectField(
          label: l10n.comicDetailTags,
          icon: Symbols.label,
          scope: scope,
          selectedNames: draft.tags,
          onAdd: (String v) => onTagsChanged(TagListWithAdded(draft.tags, v)),
          onRemove: (String v) =>
              onTagsChanged(TagListWithRemoved(draft.tags, v)),
          onClearAll: () => onTagsChanged(const <String>[]),
        ),
      ],
    );
  }
}
