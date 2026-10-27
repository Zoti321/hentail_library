import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_metadata_edit_form_metrics.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/patterns/metadata_edit/md3e_comic_metadata_edit_draft.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_comic_language_quick_pick.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_outlined_text_field.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_published_date_text_field.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_tag_input_field.dart';
import 'package:hentai_library/md3e/widgets/selection/md3e_segmented_capsule_bar.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_content_section.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_settings_tile.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

enum _Md3eComicMetadataEditTab { general, authorsTags }

List<String> _md3eTagListWithAdded(List<String> list, String value) {
  if (list.contains(value)) {
    return list;
  }
  return <String>[...list, value];
}

List<String> _md3eTagListWithRemoved(List<String> list, String value) {
  return list.where((String e) => e != value).toList();
}

/// 漫画元数据编辑表单主体（常规 + 作者&标签），字段对齐生产 [EditMetadataDialog]。
class Md3eComicMetadataEditForm extends StatefulWidget {
  const Md3eComicMetadataEditForm({
    super.key,
    required this.draft,
    required this.onDraftChanged,
    this.titleError,
  });

  final Md3eComicMetadataEditDraft draft;
  final ValueChanged<Md3eComicMetadataEditDraft> onDraftChanged;
  final String? titleError;

  @override
  State<Md3eComicMetadataEditForm> createState() =>
      _Md3eComicMetadataEditFormState();
}

class _Md3eComicMetadataEditFormState extends State<Md3eComicMetadataEditForm> {
  _Md3eComicMetadataEditTab _tab = _Md3eComicMetadataEditTab.general;

  void _update(Md3eComicMetadataEditDraft Function(Md3eComicMetadataEditDraft d) fn) {
    widget.onDraftChanged(fn(widget.draft));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final Md3eWindowSizeClass sizeClass = md3eWindowSizeClassOf(context);
    final double gap = Md3eMetadataEditFormMetrics.sectionGap(sizeClass);
    final Md3eComicMetadataEditDraft draft = widget.draft;

    final Widget tabBody = switch (_tab) {
      _Md3eComicMetadataEditTab.general => _GeneralFields(
        draft: draft,
        titleError: widget.titleError,
        gap: gap,
        onTitleChanged: (String v) =>
            _update((d) => d.copyWith(title: v)),
        onDescriptionChanged: (String v) =>
            _update((d) => d.copyWith(description: v)),
        onPublishedChanged: (String v) =>
            _update((d) => d.copyWith(publishedLabel: v)),
        onR18Changed: (bool v) => _update((d) => d.copyWith(isR18: v)),
        onLanguageAdded: (String v) => _update(
          (d) => d.copyWith(languages: _md3eTagListWithAdded(d.languages, v)),
        ),
        onLanguageRemoved: (String v) => _update(
          (d) => d.copyWith(languages: _md3eTagListWithRemoved(d.languages, v)),
        ),
      ),
      _Md3eComicMetadataEditTab.authorsTags => _AuthorsTagsFields(
        draft: draft,
        gap: gap,
        l10n: l10n,
        onParodiesChanged: (List<String> v) =>
            _update((d) => d.copyWith(parodies: v)),
        onAuthorsChanged: (List<String> v) =>
            _update((d) => d.copyWith(authors: v)),
        onCharactersChanged: (List<String> v) =>
            _update((d) => d.copyWith(characters: v)),
        onTagsChanged: (List<String> v) =>
            _update((d) => d.copyWith(tags: v)),
      ),
    };

    final bool useSideTabs = sizeClass.index >= Md3eWindowSizeClass.medium.index;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool boundedHeight = constraints.maxHeight.isFinite;
        final Widget scrollableTabBody = boundedHeight
            ? SingleChildScrollView(child: tabBody)
            : tabBody;

        if (!useSideTabs) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _TopTabBar(l10n: l10n, tab: _tab, onSelected: _selectTab),
              SizedBox(height: gap),
              if (boundedHeight)
                Flexible(child: scrollableTabBody)
              else
                tabBody,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 168,
              child: _SideTabList(l10n: l10n, tab: _tab, onSelected: _selectTab),
            ),
            SizedBox(width: gap),
            Expanded(child: scrollableTabBody),
          ],
        );
      },
    );
  }

  void _selectTab(int index) {
    setState(() => _tab = _Md3eComicMetadataEditTab.values[index]);
  }
}

class _TopTabBar extends StatelessWidget {
  const _TopTabBar({
    required this.l10n,
    required this.tab,
    required this.onSelected,
  });

  final AppLocalizations l10n;
  final _Md3eComicMetadataEditTab tab;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Md3eSegmentedCapsuleBar(
      segments: <Md3eSegmentedCapsuleSegment>[
        Md3eSegmentedCapsuleSegment(label: l10n.dialogEditMetadataTabGeneral),
        Md3eSegmentedCapsuleSegment(
          label: l10n.dialogEditMetadataTabAuthorsTags,
        ),
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
  final _Md3eComicMetadataEditTab tab;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final List<(String label, _Md3eComicMetadataEditTab value)> items =
        <(String, _Md3eComicMetadataEditTab)>[
          (l10n.dialogEditMetadataTabGeneral, _Md3eComicMetadataEditTab.general),
          (
            l10n.dialogEditMetadataTabAuthorsTags,
            _Md3eComicMetadataEditTab.authorsTags,
          ),
        ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: items.map(((String, _Md3eComicMetadataEditTab) item) {
        final bool selected = tab == item.$2;
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: M3EButton(
            onPressed: () => onSelected(item.$2.index),
            style: selected ? M3EButtonStyle.tonal : M3EButtonStyle.text,
            label: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                item.$1,
                style: theme.typeScale.labelLarge.copyWith(
                  color: selected
                      ? theme.colorScheme.onSecondaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      }).toList(),
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
  });

  final Md3eComicMetadataEditDraft draft;
  final String? titleError;
  final double gap;
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
        Md3eOutlinedTextField(
          label: l10n.formComicTitleLabel,
          initialValue: draft.title,
          hintText: l10n.formComicTitleHint,
          errorText: titleError,
          onChanged: onTitleChanged,
        ),
        SizedBox(height: gap),
        Md3eOutlinedTextField(
          label: l10n.formComicDescriptionLabel,
          initialValue: draft.description,
          hintText: l10n.formComicDescriptionHint,
          maxLines: 4,
          onChanged: onDescriptionChanged,
        ),
        SizedBox(height: gap),
        Md3ePublishedDateTextField(
          label: l10n.formPublishedDateLabel,
          value: draft.publishedLabel,
          onChanged: onPublishedChanged,
        ),
        SizedBox(height: gap),
        Md3eContentSection.group(
          title: l10n.formAgeRestrictionLabel,
          children: <Widget>[
            Md3eSettingsSwitchTile(
              leading: Symbols.eighteen_up_rating,
              title: Text(
                draft.isR18 ? 'R18' : l10n.filterAgeAllAges,
              ),
              description: Text(l10n.formAgeRestrictionLabel),
              value: draft.isR18,
              onChanged: onR18Changed,
            ),
          ],
        ),
        SizedBox(height: gap),
        Text(
          l10n.formLanguagesLabel,
          style: M3ETheme.of(context).typeScale.labelLarge.copyWith(
            color: M3ETheme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: M3ETheme.of(context).spacing.sm),
        Md3eComicLanguageQuickPick(
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
        Md3eTagInputField(
          label: l10n.metadataAdd,
          tags: draft.languages,
          onTagCommitted: onLanguageAdded,
          onTagRemoved: onLanguageRemoved,
          maxWidth: double.infinity,
        ),
      ],
    );
  }
}

class _AuthorsTagsFields extends StatelessWidget {
  const _AuthorsTagsFields({
    required this.draft,
    required this.gap,
    required this.l10n,
    required this.onParodiesChanged,
    required this.onAuthorsChanged,
    required this.onCharactersChanged,
    required this.onTagsChanged,
  });

  final Md3eComicMetadataEditDraft draft;
  final double gap;
  final AppLocalizations l10n;
  final ValueChanged<List<String>> onParodiesChanged;
  final ValueChanged<List<String>> onAuthorsChanged;
  final ValueChanged<List<String>> onCharactersChanged;
  final ValueChanged<List<String>> onTagsChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _tagField(
          label: l10n.comicDetailParodies,
          tags: draft.parodies,
          onAdd: (String v) => onParodiesChanged(
            _md3eTagListWithAdded(draft.parodies, v),
          ),
          onRemove: (String v) => onParodiesChanged(
            _md3eTagListWithRemoved(draft.parodies, v),
          ),
        ),
        SizedBox(height: gap),
        _tagField(
          label: l10n.comicDetailAuthors,
          tags: draft.authors,
          onAdd: (String v) =>
              onAuthorsChanged(_md3eTagListWithAdded(draft.authors, v)),
          onRemove: (String v) => onAuthorsChanged(
            _md3eTagListWithRemoved(draft.authors, v),
          ),
        ),
        SizedBox(height: gap),
        _tagField(
          label: l10n.comicDetailCharacters,
          tags: draft.characters,
          onAdd: (String v) => onCharactersChanged(
            _md3eTagListWithAdded(draft.characters, v),
          ),
          onRemove: (String v) => onCharactersChanged(
            _md3eTagListWithRemoved(draft.characters, v),
          ),
        ),
        SizedBox(height: gap),
        _tagField(
          label: l10n.comicDetailTags,
          tags: draft.tags,
          onAdd: (String v) =>
              onTagsChanged(_md3eTagListWithAdded(draft.tags, v)),
          onRemove: (String v) =>
              onTagsChanged(_md3eTagListWithRemoved(draft.tags, v)),
        ),
      ],
    );
  }

  Widget _tagField({
    required String label,
    required List<String> tags,
    required ValueChanged<String> onAdd,
    required ValueChanged<String> onRemove,
  }) {
    return Md3eTagInputField(
      label: label,
      tags: tags,
      onTagCommitted: onAdd,
      onTagRemoved: onRemove,
      maxWidth: double.infinity,
    );
  }

}
