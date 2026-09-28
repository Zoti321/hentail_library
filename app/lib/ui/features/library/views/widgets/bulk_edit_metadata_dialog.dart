import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/library/comic_metadata_bulk_patch_types.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/models/value_objects/comic_language.dart';
import 'package:hentai_library/ui/core/layout/app_layout_breakpoints.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/chrome/capsule_tab_bar.dart';
import 'package:hentai_library/ui/core/widgets/element/chip/outlined_meta_chip.dart';
import 'package:hentai_library/ui/core/widgets/form/author_library_multi_select_field.dart';
import 'package:hentai_library/ui/core/widgets/form/character_library_multi_select_field.dart';
import 'package:hentai_library/ui/core/widgets/form/fluent_date_picker_field.dart';
import 'package:hentai_library/ui/core/widgets/form/fluent_text_field.dart';
import 'package:hentai_library/ui/core/widgets/form/fluent_toggle_field.dart';
import 'package:hentai_library/ui/core/widgets/form/parody_library_multi_select_field.dart';
import 'package:hentai_library/ui/core/widgets/form/tag_library_multi_select_field.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/adaptive_form_surface.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/dialog_side_tab_bar.dart';
import 'package:hentai_library/ui/features/library/view_models/comic_metadata_smart_facet_providers.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const double _kBulkEditDialogWidth = 720;
const double _kBulkEditDialogRadius = 4;
const double _kBulkEditShellChromeReserve = 120;
const double _kBulkEditBodyMinHeight = 240;
const double _kBulkEditFieldListWidth = 200;

enum _BulkEditTab { general, authorsAndTags }

enum _BulkFieldKind {
  description,
  publishedAt,
  contentRating,
  languages,
  authors,
  tags,
  parodies,
  characters,
}

extension _BulkEditTabFields on _BulkEditTab {
  List<_BulkFieldKind> get fields => switch (this) {
    _BulkEditTab.general => <_BulkFieldKind>[
      _BulkFieldKind.description,
      _BulkFieldKind.publishedAt,
      _BulkFieldKind.contentRating,
      _BulkFieldKind.languages,
    ],
    _BulkEditTab.authorsAndTags => <_BulkFieldKind>[
      _BulkFieldKind.authors,
      _BulkFieldKind.tags,
      _BulkFieldKind.parodies,
      _BulkFieldKind.characters,
    ],
  };
}

class _BulkMultiValueFieldState {
  ComicMetadataBulkMultiValueOp op = ComicMetadataBulkMultiValueOp.add;
  List<String> values = const <String>[];
  bool mixedValues = false;
}

class _BulkScalarFieldState {
  ComicMetadataBulkScalarOp op = ComicMetadataBulkScalarOp.replace;
  bool mixedValues = false;
  String description = '';
  DateTime? publishedAt;
}

class _BulkContentRatingFieldState {
  bool isR18 = false;
  bool mixedValues = false;
}

Future<ComicMetadataBulkPatch?> showBulkEditMetadataDialog({
  required BuildContext context,
  required List<String> comicIds,
}) {
  return showAdaptiveFormSurfaceWidget<ComicMetadataBulkPatch?>(
    context: context,
    surface: BulkEditMetadataDialog(comicIds: comicIds),
  );
}

class BulkEditMetadataDialog extends ConsumerStatefulWidget {
  const BulkEditMetadataDialog({super.key, required this.comicIds});

  final List<String> comicIds;

  @override
  ConsumerState<BulkEditMetadataDialog> createState() =>
      _BulkEditMetadataDialogState();
}

class _BulkEditMetadataDialogState
    extends ConsumerState<BulkEditMetadataDialog> {
  final Map<_BulkFieldKind, _BulkMultiValueFieldState> _multiFields =
      <_BulkFieldKind, _BulkMultiValueFieldState>{
        for (final _BulkFieldKind kind in <_BulkFieldKind>[
          _BulkFieldKind.tags,
          _BulkFieldKind.authors,
          _BulkFieldKind.languages,
          _BulkFieldKind.parodies,
          _BulkFieldKind.characters,
        ])
          kind: _BulkMultiValueFieldState(),
      };
  final _BulkScalarFieldState _descriptionField = _BulkScalarFieldState();
  final _BulkScalarFieldState _publishedAtField = _BulkScalarFieldState();
  final _BulkContentRatingFieldState _contentRatingField =
      _BulkContentRatingFieldState();
  _BulkEditTab _selectedTab = _BulkEditTab.general;
  _BulkFieldKind? _selectedField;
  final Set<_BulkFieldKind> _dirtyFields = <_BulkFieldKind>{};
  bool _loading = true;
  ComicMetadataSmartFacetScope? _scope;

  @override
  void initState() {
    super.initState();
    _loadMixedHints();
  }

  Future<void> _loadMixedHints() async {
    final List<Comic> comics = await ref
        .read(comicRepoProvider)
        .findByIds(widget.comicIds);
    if (!mounted) {
      return;
    }
    final Comic? anchor = comics.isNotEmpty ? comics.first : null;
    setState(() {
      _multiFields[_BulkFieldKind.tags]!.mixedValues = _isMixed(
        comics.map((Comic c) => c.tags.map((t) => t.name).toList()),
      );
      _multiFields[_BulkFieldKind.authors]!.mixedValues = _isMixed(
        comics.map((Comic c) => c.authors.map((a) => a.name).toList()),
      );
      _multiFields[_BulkFieldKind.languages]!.mixedValues = _isMixed(
        comics.map((Comic c) => List<String>.from(c.languages)),
      );
      _multiFields[_BulkFieldKind.parodies]!.mixedValues = _isMixed(
        comics.map((Comic c) => List<String>.from(c.parodies)),
      );
      _multiFields[_BulkFieldKind.characters]!.mixedValues = _isMixed(
        comics.map((Comic c) => List<String>.from(c.characters)),
      );
      _contentRatingField.mixedValues = _isMixed(
        comics.map(
          (Comic c) => <String>[
            c.contentRating == ContentRating.r18 ? 'r18' : 'safe',
          ],
        ),
      );
      _descriptionField.mixedValues = _isMixed(
        comics.map((Comic c) => <String>[c.description ?? '']),
      );
      _publishedAtField.mixedValues = _isMixed(
        comics.map(
          (Comic c) => <String>[
            c.publishedAt?.millisecondsSinceEpoch.toString() ?? '',
          ],
        ),
      );
      if (anchor != null) {
        _scope = (
          comicId: anchor.comicId,
          title: anchor.title,
          resourcePath: anchor.path,
          seriesId: null,
        );
      }
      _selectedField = _BulkFieldKind.description;
      _loading = false;
    });
  }

  void _markDirty(_BulkFieldKind kind) {
    if (_dirtyFields.add(kind)) {
      setState(() {});
    }
  }

  bool _isFieldDirty(_BulkFieldKind kind) => _dirtyFields.contains(kind);

  bool _isMixed(Iterable<List<String>> lists) {
    final Iterator<List<String>> it = lists.iterator;
    if (!it.moveNext()) {
      return false;
    }
    final List<String> first = List<String>.from(it.current)..sort();
    while (it.moveNext()) {
      final List<String> next = List<String>.from(it.current)..sort();
      if (!_listEquals(first, next)) {
        return true;
      }
    }
    return false;
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  _BulkFieldKind _defaultFieldForTab(_BulkEditTab tab) => tab.fields.first;

  void _selectTab(int index) {
    final _BulkEditTab tab = _BulkEditTab.values[index];
    if (tab == _selectedTab) {
      return;
    }
    setState(() {
      _selectedTab = tab;
      _selectedField = _defaultFieldForTab(tab);
    });
  }

  void _selectField(_BulkFieldKind kind) {
    if (_selectedField == kind) {
      return;
    }
    setState(() => _selectedField = kind);
  }

  String _fieldLabel(AppLocalizations l10n, _BulkFieldKind kind) {
    return switch (kind) {
      _BulkFieldKind.tags => l10n.bulkEditMetadataFieldTags,
      _BulkFieldKind.authors => l10n.bulkEditMetadataFieldAuthors,
      _BulkFieldKind.languages => l10n.bulkEditMetadataFieldLanguages,
      _BulkFieldKind.parodies => l10n.bulkEditMetadataFieldParodies,
      _BulkFieldKind.characters => l10n.bulkEditMetadataFieldCharacters,
      _BulkFieldKind.contentRating => l10n.bulkEditMetadataFieldContentRating,
      _BulkFieldKind.description => l10n.bulkEditMetadataFieldDescription,
      _BulkFieldKind.publishedAt => l10n.bulkEditMetadataFieldPublishedAt,
    };
  }

  String? _fieldSummary(AppLocalizations l10n, _BulkFieldKind kind) {
    if (!_isFieldDirty(kind)) {
      return null;
    }
    return switch (kind) {
      _BulkFieldKind.languages ||
      _BulkFieldKind.authors ||
      _BulkFieldKind.tags ||
      _BulkFieldKind.parodies ||
      _BulkFieldKind.characters => () {
        final _BulkMultiValueFieldState state = _multiFields[kind]!;
        return l10n.bulkEditMetadataFieldSummaryCount(
          _multiOpLabels(l10n)[state.op] ?? state.op.name,
          state.values.length,
        );
      }(),
      _BulkFieldKind.description || _BulkFieldKind.publishedAt => () {
        final _BulkScalarFieldState state = switch (kind) {
          _BulkFieldKind.description => _descriptionField,
          _BulkFieldKind.publishedAt => _publishedAtField,
          _ => throw StateError('$kind'),
        };
        return state.op == ComicMetadataBulkScalarOp.clear
            ? l10n.bulkEditMetadataFieldSummaryClear
            : l10n.bulkEditMetadataFieldSummaryReplace;
      }(),
      _BulkFieldKind.contentRating =>
        _contentRatingField.isR18 ? 'R18' : l10n.filterAgeAllAges,
    };
  }

  ComicMetadataBulkPatch? _buildPatch() {
    final _BulkMultiValueFieldState tags = _multiFields[_BulkFieldKind.tags]!;
    final _BulkMultiValueFieldState authors =
        _multiFields[_BulkFieldKind.authors]!;
    final _BulkMultiValueFieldState languages =
        _multiFields[_BulkFieldKind.languages]!;
    final _BulkMultiValueFieldState parodies =
        _multiFields[_BulkFieldKind.parodies]!;
    final _BulkMultiValueFieldState characters =
        _multiFields[_BulkFieldKind.characters]!;
    if (_dirtyFields.isEmpty) {
      return null;
    }
    return ComicMetadataBulkPatch(
      tags: _dirtyFields.contains(_BulkFieldKind.tags)
          ? ComicMetadataBulkMultiValuePatch(op: tags.op, values: tags.values)
          : null,
      authors: _dirtyFields.contains(_BulkFieldKind.authors)
          ? ComicMetadataBulkMultiValuePatch(
              op: authors.op,
              values: authors.values,
            )
          : null,
      languages: _dirtyFields.contains(_BulkFieldKind.languages)
          ? ComicMetadataBulkMultiValuePatch(
              op: languages.op,
              values: languages.values,
            )
          : null,
      parodies: _dirtyFields.contains(_BulkFieldKind.parodies)
          ? ComicMetadataBulkMultiValuePatch(
              op: parodies.op,
              values: parodies.values,
            )
          : null,
      characters: _dirtyFields.contains(_BulkFieldKind.characters)
          ? ComicMetadataBulkMultiValuePatch(
              op: characters.op,
              values: characters.values,
            )
          : null,
      contentRating: _dirtyFields.contains(_BulkFieldKind.contentRating)
          ? (_contentRatingField.isR18 ? 'r18' : 'safe')
          : null,
      description: _dirtyFields.contains(_BulkFieldKind.description)
          ? (_descriptionField.op == ComicMetadataBulkScalarOp.clear
                ? const ComicMetadataBulkDescriptionPatch.clear()
                : ComicMetadataBulkDescriptionPatch.replace(
                    _descriptionField.description,
                  ))
          : null,
      publishedAt: _dirtyFields.contains(_BulkFieldKind.publishedAt)
          ? (_publishedAtField.op == ComicMetadataBulkScalarOp.clear
                ? const ComicMetadataBulkPublishedAtPatch.clear()
                : ComicMetadataBulkPublishedAtPatch.replace(
                    _publishedAtField.publishedAt?.millisecondsSinceEpoch ?? 0,
                  ))
          : null,
    );
  }

  Future<void> _onSave() async {
    final AppLocalizations l10n = context.l10n;
    final ComicMetadataBulkPatch? patch = _buildPatch();
    if (patch == null) {
      return;
    }
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text(l10n.bulkEditMetadataConfirmTitle),
            content: Text(
              l10n.bulkEditMetadataConfirmBody(
                widget.comicIds.length,
                patch.enabledFieldCount,
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.commonSaveChanges),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) {
      return;
    }
    Navigator.of(context).pop(patch);
  }

  List<DialogSideTabItem> _sideTabs(AppLocalizations l10n) =>
      <DialogSideTabItem>[
        DialogSideTabItem(
          label: l10n.dialogEditMetadataTabGeneral,
          icon: LucideIcons.textAlignCenter,
        ),
        DialogSideTabItem(
          label: l10n.dialogEditMetadataTabAuthorsTags,
          icon: LucideIcons.users,
        ),
      ];

  List<CapsuleTabItem> _capsuleTabs(AppLocalizations l10n) => <CapsuleTabItem>[
    CapsuleTabItem(
      label: l10n.dialogEditMetadataTabGeneral,
      icon: LucideIcons.textAlignCenter,
    ),
    CapsuleTabItem(
      label: l10n.dialogEditMetadataTabAuthorsTags,
      icon: LucideIcons.users,
    ),
  ];

  Widget _buildMasterDetail(
    AppLocalizations l10n,
    ComicMetadataSmartFacetScope scope,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          width: _kBulkEditFieldListWidth,
          child: _BulkEditFieldList(
            fields: _selectedTab.fields,
            selectedField: _selectedField,
            labelFor: (_BulkFieldKind kind) => _fieldLabel(l10n, kind),
            isDirty: _isFieldDirty,
            isMixed: _isFieldMixed,
            summaryFor: (_BulkFieldKind kind) => _fieldSummary(l10n, kind),
            mixedLabel: l10n.bulkEditMetadataMixedValues,
            onSelect: _selectField,
          ),
        ),
        VerticalDivider(
          width: 1,
          color: Theme.of(context).colorScheme.hentai.borderSubtle,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              context.tokens.spacing.lg,
              0,
              context.tokens.spacing.lg,
              context.tokens.spacing.xs,
            ),
            child: _BulkEditFieldDetail(
              selectedField: _selectedField,
              selectHint: l10n.bulkEditMetadataSelectFieldHint,
              child: _selectedField == null
                  ? null
                  : _buildFieldEditor(l10n, scope, _selectedField!),
            ),
          ),
        ),
      ],
    );
  }

  bool _isFieldMixed(_BulkFieldKind kind) {
    return switch (kind) {
      _BulkFieldKind.description => _descriptionField.mixedValues,
      _BulkFieldKind.publishedAt => _publishedAtField.mixedValues,
      _BulkFieldKind.contentRating => _contentRatingField.mixedValues,
      _BulkFieldKind.languages ||
      _BulkFieldKind.authors ||
      _BulkFieldKind.tags ||
      _BulkFieldKind.parodies ||
      _BulkFieldKind.characters => _multiFields[kind]!.mixedValues,
    };
  }

  Widget _buildFieldEditor(
    AppLocalizations l10n,
    ComicMetadataSmartFacetScope scope,
    _BulkFieldKind kind,
  ) {
    return switch (kind) {
      _BulkFieldKind.tags ||
      _BulkFieldKind.authors ||
      _BulkFieldKind.languages ||
      _BulkFieldKind.parodies ||
      _BulkFieldKind.characters => _BulkMultiValueFieldDetail(
        state: _multiFields[kind]!,
        opLabels: _multiOpLabels(l10n),
        onChanged: () {
          _markDirty(kind);
          setState(() {});
        },
        child: _buildMultiValueInput(l10n, scope, kind),
      ),
      _BulkFieldKind.description || _BulkFieldKind.publishedAt => () {
        final _BulkScalarFieldState state = switch (kind) {
          _BulkFieldKind.description => _descriptionField,
          _BulkFieldKind.publishedAt => _publishedAtField,
          _ => throw StateError('$kind'),
        };
        return _BulkScalarFieldDetail(
          state: state,
          opLabels: _scalarOpLabels(l10n),
          onChanged: () {
            _markDirty(kind);
            setState(() {});
          },
          child: kind == _BulkFieldKind.description
              ? FluentTextField(
                  labelText: l10n.bulkEditMetadataFieldDescription,
                  initialValue: _descriptionField.description,
                  maxLines: 4,
                  enabled:
                      _descriptionField.op == ComicMetadataBulkScalarOp.replace,
                  onChanged: (String value) {
                    _descriptionField.description = value;
                    _markDirty(_BulkFieldKind.description);
                  },
                )
              : FluentDatePickerField(
                  labelText: l10n.bulkEditMetadataFieldPublishedAt,
                  value: _publishedAtField.publishedAt,
                  enabled:
                      _publishedAtField.op == ComicMetadataBulkScalarOp.replace,
                  onChanged: (DateTime? value) {
                    _publishedAtField.publishedAt = value;
                    _markDirty(_BulkFieldKind.publishedAt);
                  },
                ),
        );
      }(),
      _BulkFieldKind.contentRating => _BulkContentRatingFieldDetail(
        label: l10n.bulkEditMetadataFieldContentRating,
        state: _contentRatingField,
        allAgesLabel: l10n.filterAgeAllAges,
        onChanged: () {
          _markDirty(_BulkFieldKind.contentRating);
          setState(() {});
        },
      ),
    };
  }

  Widget _buildMultiValueInput(
    AppLocalizations l10n,
    ComicMetadataSmartFacetScope scope,
    _BulkFieldKind kind,
  ) {
    final _BulkMultiValueFieldState state = _multiFields[kind]!;
    return switch (kind) {
      _BulkFieldKind.tags => TagLibraryMultiSelectField(
        label: l10n.bulkEditMetadataFieldTags,
        icon: LucideIcons.tag,
        selectedNames: state.values,
        scope: scope,
        onAdd: (String name) => _addMultiValue(_BulkFieldKind.tags, name),
        onRemove: (String name) => _removeMultiValue(_BulkFieldKind.tags, name),
      ),
      _BulkFieldKind.authors => AuthorLibraryMultiSelectField(
        label: l10n.bulkEditMetadataFieldAuthors,
        icon: LucideIcons.penTool,
        selectedNames: state.values,
        scope: scope,
        onAdd: (String name) => _addMultiValue(_BulkFieldKind.authors, name),
        onRemove: (String name) =>
            _removeMultiValue(_BulkFieldKind.authors, name),
      ),
      _BulkFieldKind.languages => _LanguageChipField(
        l10n: l10n,
        selected: state.values,
        onAdd: (String name) => _addMultiValue(_BulkFieldKind.languages, name),
        onRemove: (String name) =>
            _removeMultiValue(_BulkFieldKind.languages, name),
      ),
      _BulkFieldKind.parodies => ParodyLibraryMultiSelectField(
        label: l10n.bulkEditMetadataFieldParodies,
        icon: LucideIcons.bookMarked,
        selectedNames: state.values,
        scope: scope,
        onAdd: (String name) => _addMultiValue(_BulkFieldKind.parodies, name),
        onRemove: (String name) =>
            _removeMultiValue(_BulkFieldKind.parodies, name),
      ),
      _BulkFieldKind.characters => CharacterLibraryMultiSelectField(
        label: l10n.bulkEditMetadataFieldCharacters,
        icon: LucideIcons.userRound,
        selectedNames: state.values,
        scope: scope,
        onAdd: (String name) => _addMultiValue(_BulkFieldKind.characters, name),
        onRemove: (String name) =>
            _removeMultiValue(_BulkFieldKind.characters, name),
      ),
      _ => throw StateError('$kind'),
    };
  }

  void _addMultiValue(_BulkFieldKind kind, String name) {
    setState(() {
      final _BulkMultiValueFieldState field = _multiFields[kind]!;
      if (!field.values.contains(name)) {
        field.values = <String>[...field.values, name];
      }
      _dirtyFields.add(kind);
    });
  }

  void _removeMultiValue(_BulkFieldKind kind, String name) {
    setState(() {
      _multiFields[kind]!.values = _multiFields[kind]!.values
          .where((String v) => v != name)
          .toList();
      _dirtyFields.add(kind);
    });
  }

  Map<ComicMetadataBulkMultiValueOp, String> _multiOpLabels(
    AppLocalizations l10n,
  ) {
    return <ComicMetadataBulkMultiValueOp, String>{
      ComicMetadataBulkMultiValueOp.add: l10n.bulkEditMetadataOpAdd,
      ComicMetadataBulkMultiValueOp.remove: l10n.bulkEditMetadataOpRemove,
      ComicMetadataBulkMultiValueOp.replace: l10n.bulkEditMetadataOpReplace,
    };
  }

  Map<ComicMetadataBulkScalarOp, String> _scalarOpLabels(
    AppLocalizations l10n,
  ) {
    return <ComicMetadataBulkScalarOp, String>{
      ComicMetadataBulkScalarOp.replace: l10n.bulkEditMetadataOpReplace,
      ComicMetadataBulkScalarOp.clear: l10n.bulkEditMetadataOpClear,
    };
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ComicMetadataSmartFacetScope? scope = _scope;
    final bool compact = AppLayoutBreakpoints.isCompact(
      MediaQuery.sizeOf(context).width,
    );
    final int selectedTabIndex = _selectedTab.index;

    final Widget loadedBody;
    if (scope == null) {
      loadedBody = const SizedBox.shrink();
    } else if (compact) {
      loadedBody = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(
              tokens.spacing.lg,
              0,
              tokens.spacing.lg,
              tokens.spacing.md,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: CapsuleTabBar(
                items: _capsuleTabs(l10n),
                selectedIndex: selectedTabIndex,
                onSelected: _selectTab,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: tokens.spacing.lg),
                  child: _BulkEditFieldList(
                    fields: _selectedTab.fields,
                    selectedField: _selectedField,
                    labelFor: (_BulkFieldKind kind) => _fieldLabel(l10n, kind),
                    isDirty: _isFieldDirty,
                    isMixed: _isFieldMixed,
                    summaryFor: (_BulkFieldKind kind) =>
                        _fieldSummary(l10n, kind),
                    mixedLabel: l10n.bulkEditMetadataMixedValues,
                    onSelect: _selectField,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      tokens.spacing.lg,
                      tokens.spacing.md,
                      tokens.spacing.lg,
                      tokens.spacing.xs,
                    ),
                    child: _BulkEditFieldDetail(
                      selectedField: _selectedField,
                      selectHint: l10n.bulkEditMetadataSelectFieldHint,
                      child: _selectedField == null
                          ? null
                          : _buildFieldEditor(l10n, scope, _selectedField!),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      loadedBody = ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: _kBulkEditBodyMinHeight,
          maxHeight: math.max(
            _kBulkEditBodyMinHeight,
            MediaQuery.sizeOf(context).height * 0.88 -
                _kBulkEditShellChromeReserve,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DialogSideTabBar(
              items: _sideTabs(l10n),
              selectedIndex: selectedTabIndex,
              showDivider: false,
              onSelected: _selectTab,
            ),
            Expanded(child: _buildMasterDetail(l10n, scope)),
          ],
        ),
      );
    }

    return AdaptiveFormSurface(
      title: l10n.bulkEditMetadataTitle(widget.comicIds.length),
      maxDialogWidth: _kBulkEditDialogWidth,
      borderRadius: _kBulkEditDialogRadius,
      scrollableBody: false,
      bodyPadding: EdgeInsets.zero,
      backgroundColor: cs.surface,
      showFooterDivider: false,
      fitContentHeight: true,
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : loadedBody,
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        const SizedBox(width: 8),
        FilledButton(onPressed: _onSave, child: Text(l10n.commonSaveChanges)),
      ],
    );
  }
}

class _BulkEditFieldList extends StatelessWidget {
  const _BulkEditFieldList({
    required this.fields,
    required this.selectedField,
    required this.labelFor,
    required this.isDirty,
    required this.isMixed,
    required this.summaryFor,
    required this.mixedLabel,
    required this.onSelect,
  });

  final List<_BulkFieldKind> fields;
  final _BulkFieldKind? selectedField;
  final String Function(_BulkFieldKind kind) labelFor;
  final bool Function(_BulkFieldKind kind) isDirty;
  final bool Function(_BulkFieldKind kind) isMixed;
  final String? Function(_BulkFieldKind kind) summaryFor;
  final String mixedLabel;
  final ValueChanged<_BulkFieldKind> onSelect;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: tokens.spacing.xs,
      children: fields
          .map(
            (_BulkFieldKind kind) => _BulkEditFieldListRow(
              label: labelFor(kind),
              dirty: isDirty(kind),
              selected: selectedField == kind,
              mixed: isMixed(kind),
              summary: summaryFor(kind),
              mixedLabel: mixedLabel,
              onSelect: () => onSelect(kind),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _BulkEditFieldListRow extends StatelessWidget {
  const _BulkEditFieldListRow({
    required this.label,
    required this.dirty,
    required this.selected,
    required this.mixed,
    required this.summary,
    required this.mixedLabel,
    required this.onSelect,
  });

  final String label;
  final bool dirty;
  final bool selected;
  final bool mixed;
  final String? summary;
  final String mixedLabel;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color? background = selected
        ? cs.primary.withAlpha(20)
        : dirty
        ? cs.hentai.hoverBackground.withAlpha(80)
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(tokens.radius.sm),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(tokens.radius.sm),
            border: Border(
              left: BorderSide(
                color: selected ? cs.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spacing.sm,
              vertical: tokens.spacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spacing.xs,
              children: <Widget>[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: tokens.text.bodySm,
                    fontWeight: FontWeight.w600,
                    color: cs.hentai.textPrimary,
                  ),
                ),
                if (summary != null || mixed)
                  Row(
                    children: <Widget>[
                      if (summary != null)
                        Flexible(
                          child: Text(
                            summary!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: tokens.text.labelXs,
                              color: cs.hentai.textSecondary,
                            ),
                          ),
                        ),
                      if (mixed) ...<Widget>[
                        if (summary != null) SizedBox(width: tokens.spacing.xs),
                        Text(
                          mixedLabel,
                          style: TextStyle(
                            fontSize: tokens.text.labelXs,
                            color: cs.hentai.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BulkEditFieldDetail extends StatelessWidget {
  const _BulkEditFieldDetail({
    required this.selectedField,
    required this.selectHint,
    required this.child,
  });

  final _BulkFieldKind? selectedField;
  final String selectHint;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (selectedField == null || child == null) {
      return _BulkEditDetailPlaceholder(message: selectHint);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: context.tokens.spacing.md,
      children: <Widget>[child!],
    );
  }
}

class _BulkEditDetailPlaceholder extends StatelessWidget {
  const _BulkEditDetailPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(tokens.spacing.xl),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: tokens.text.bodySm,
            color: cs.hentai.textTertiary,
          ),
        ),
      ),
    );
  }
}

class _LanguageChipField extends StatelessWidget {
  const _LanguageChipField({
    required this.l10n,
    required this.selected,
    required this.onAdd,
    required this.onRemove,
  });

  final AppLocalizations l10n;
  final List<String> selected;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<String> choices = <String>[
      ...ComicLanguageNames.closedSet,
      ...selected.where(
        (String name) => !ComicLanguageNames.closedSet.contains(name),
      ),
    ];
    return Wrap(
      spacing: tokens.spacing.sm,
      runSpacing: tokens.spacing.sm,
      children: choices.map((String canonical) {
        final bool isSelected = selected.contains(canonical);
        return OutlinedMetaChip(
          text: l10n.comicLanguageLabel(canonical),
          compact: true,
          borderColor: isSelected ? cs.primary : null,
          textColor: isSelected ? cs.primary : null,
          onTap: () {
            if (isSelected) {
              onRemove(canonical);
            } else {
              onAdd(canonical);
            }
          },
        );
      }).toList(),
    );
  }
}

class _BulkMultiValueFieldDetail extends StatelessWidget {
  const _BulkMultiValueFieldDetail({
    required this.state,
    required this.opLabels,
    required this.child,
    required this.onChanged,
  });

  final _BulkMultiValueFieldState state;
  final Map<ComicMetadataBulkMultiValueOp, String> opLabels;
  final Widget child;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: context.tokens.spacing.sm,
      children: <Widget>[
        _BulkEditOperationSelector(
          label: context.l10n.bulkEditMetadataOperationLabel,
          items: ComicMetadataBulkMultiValueOp.values
              .map(
                (ComicMetadataBulkMultiValueOp op) =>
                    CapsuleTabItem(label: opLabels[op] ?? op.name),
              )
              .toList(growable: false),
          selectedIndex: ComicMetadataBulkMultiValueOp.values.indexOf(state.op),
          onSelected: (int index) {
            state.op = ComicMetadataBulkMultiValueOp.values[index];
            onChanged();
          },
        ),
        child,
      ],
    );
  }
}

class _BulkScalarFieldDetail extends StatelessWidget {
  const _BulkScalarFieldDetail({
    required this.state,
    required this.opLabels,
    required this.child,
    required this.onChanged,
  });

  final _BulkScalarFieldState state;
  final Map<ComicMetadataBulkScalarOp, String> opLabels;
  final Widget child;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: context.tokens.spacing.sm,
      children: <Widget>[
        _BulkEditOperationSelector(
          label: context.l10n.bulkEditMetadataOperationLabel,
          items: ComicMetadataBulkScalarOp.values
              .map(
                (ComicMetadataBulkScalarOp op) =>
                    CapsuleTabItem(label: opLabels[op] ?? op.name),
              )
              .toList(growable: false),
          selectedIndex: ComicMetadataBulkScalarOp.values.indexOf(state.op),
          onSelected: (int index) {
            state.op = ComicMetadataBulkScalarOp.values[index];
            onChanged();
          },
        ),
        child,
      ],
    );
  }
}

class _BulkContentRatingFieldDetail extends StatelessWidget {
  const _BulkContentRatingFieldDetail({
    required this.label,
    required this.state,
    required this.allAgesLabel,
    required this.onChanged,
  });

  final String label;
  final _BulkContentRatingFieldState state;
  final String allAgesLabel;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return FluentToggleField(
      labelText: label,
      value: state.isR18,
      onChanged: (bool value) {
        state.isR18 = value;
        onChanged();
      },
      checkedLabel: 'R18',
      uncheckedLabel: allAgesLabel,
    );
  }
}

class _BulkEditOperationSelector extends StatelessWidget {
  const _BulkEditOperationSelector({
    required this.label,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final String label;
  final List<CapsuleTabItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.xs,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            fontSize: tokens.text.bodySm,
            fontWeight: FontWeight.w500,
            color: cs.hentai.textPrimary,
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: CapsuleTabBar(
            items: items,
            selectedIndex: selectedIndex,
            onSelected: onSelected,
          ),
        ),
      ],
    );
  }
}
