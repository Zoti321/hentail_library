import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/comic/presentation/patterns/metadata_edit/comic_metadata_edit_draft.dart';
import 'package:hentai_library/features/comic/presentation/patterns/metadata_edit/comic_metadata_locks_pane.dart';
import 'package:hentai_library/features/comic/presentation/widgets/comic_language_quick_pick.dart';
import 'package:hentai_library/features/comic/domain/value_objects/comic_meta_locks.dart';
import 'package:hentai_library/features/comic/presentation/view_models/comic_metadata_smart_facet_providers.dart';
import 'package:hentai_library/features/comic/presentation/views/widgets/form/author_library_multi_select_field.dart';
import 'package:hentai_library/features/comic/presentation/views/widgets/form/character_library_multi_select_field.dart';
import 'package:hentai_library/features/comic/presentation/views/widgets/form/parody_library_multi_select_field.dart';
import 'package:hentai_library/features/comic/presentation/views/widgets/form/tag_library_multi_select_field.dart';
import 'package:hentai_library/shared/ui/widgets/settings/content_section.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_tile.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:hentai_library/shared/ui/catalog/metadata_edit/metadata_lock_callbacks.dart';

List<String> tagListWithAdded(List<String> list, String value) {
  if (list.contains(value)) {
    return list;
  }
  return <String>[...list, value];
}

List<String> tagListWithRemoved(List<String> list, String value) {
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
  int _tabIndex = 0;

  void _update(ComicMetadataEditDraft Function(ComicMetadataEditDraft d) fn) {
    widget.onDraftChanged(fn(widget.draft));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final WindowSizeClass sizeClass = windowSizeClassOf(context);
    final double gap = MetadataEditFormMetrics.sectionGap(sizeClass);
    final ComicMetadataEditDraft draft = widget.draft;

    return MetadataEditTabbedShell(
      selectedIndex: _tabIndex,
      onSelected: (int index) => setState(() => _tabIndex = index),
      tabs: <MetadataEditTab>[
        (
          label: l10n.dialogEditMetadataTabGeneral,
          body: _GeneralFields(
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
              (d) => d.copyWith(languages: tagListWithAdded(d.languages, v)),
            ),
            onLanguageRemoved: (String v) => _update(
              (d) =>
                  d.copyWith(languages: tagListWithRemoved(d.languages, v)),
            ),
            onSortOrderChanged: (String v) =>
                _update((d) => d.copyWith(seriesSortOrderText: v)),
          ),
        ),
        (
          label: l10n.dialogEditMetadataTabAuthorsTags,
          body: _AuthorsTagsFields(
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
            onTagsChanged: (List<String> v) =>
                _update((d) => d.copyWith(tags: v)),
          ),
        ),
        (
          label: l10n.dialogEditMetadataTabFieldLocks,
          body: ComicMetadataLocksPane(
            locks: widget.locks,
            onLockChanged: widget.onLockChanged,
          ),
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
              onParodiesChanged(tagListWithAdded(draft.parodies, v)),
          onRemove: (String v) =>
              onParodiesChanged(tagListWithRemoved(draft.parodies, v)),
          onClearAll: () => onParodiesChanged(const <String>[]),
        ),
        SizedBox(height: gap),
        AuthorLibraryMultiSelectField(
          label: l10n.comicDetailAuthors,
          icon: Symbols.person,
          scope: scope,
          selectedNames: draft.authors,
          onAdd: (String v) =>
              onAuthorsChanged(tagListWithAdded(draft.authors, v)),
          onRemove: (String v) =>
              onAuthorsChanged(tagListWithRemoved(draft.authors, v)),
          onClearAll: () => onAuthorsChanged(const <String>[]),
        ),
        SizedBox(height: gap),
        CharacterLibraryMultiSelectField(
          label: l10n.comicDetailCharacters,
          icon: Symbols.groups,
          scope: scope,
          selectedNames: draft.characters,
          onAdd: (String v) =>
              onCharactersChanged(tagListWithAdded(draft.characters, v)),
          onRemove: (String v) =>
              onCharactersChanged(tagListWithRemoved(draft.characters, v)),
          onClearAll: () => onCharactersChanged(const <String>[]),
        ),
        SizedBox(height: gap),
        TagLibraryMultiSelectField(
          label: l10n.comicDetailTags,
          icon: Symbols.label,
          scope: scope,
          selectedNames: draft.tags,
          onAdd: (String v) => onTagsChanged(tagListWithAdded(draft.tags, v)),
          onRemove: (String v) =>
              onTagsChanged(tagListWithRemoved(draft.tags, v)),
          onClearAll: () => onTagsChanged(const <String>[]),
        ),
      ],
    );
  }
}
