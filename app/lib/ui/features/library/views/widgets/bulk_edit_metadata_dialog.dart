import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/library/comic_metadata_bulk_patch_types.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/models/value_objects/comic_language.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/chip/outlined_meta_chip.dart';
import 'package:hentai_library/ui/core/widgets/form/author_library_multi_select_field.dart';
import 'package:hentai_library/ui/core/widgets/form/character_library_multi_select_field.dart';
import 'package:hentai_library/ui/core/widgets/form/fluent_date_picker_field.dart';
import 'package:hentai_library/ui/core/widgets/form/fluent_text_field.dart';
import 'package:hentai_library/ui/core/widgets/form/fluent_toggle_field.dart';
import 'package:hentai_library/ui/core/widgets/form/parody_library_multi_select_field.dart';
import 'package:hentai_library/ui/core/widgets/form/tag_library_multi_select_field.dart';
import 'package:hentai_library/ui/core/widgets/foundation/toggle_switch.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/adaptive_form_surface.dart';
import 'package:hentai_library/ui/features/library/view_models/comic_metadata_smart_facet_providers.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const double _kBulkEditDialogWidth = 720;

enum _BulkFieldKind {
  tags,
  authors,
  languages,
  parodies,
  characters,
  contentRating,
  description,
  publishedAt,
}

class _BulkMultiValueFieldState {
  _BulkMultiValueFieldState({
    this.enabled = false,
    this.op = ComicMetadataBulkMultiValueOp.add,
    this.values = const <String>[],
    this.mixedValues = false,
  });

  bool enabled;
  ComicMetadataBulkMultiValueOp op;
  List<String> values;
  bool mixedValues;
}

class _BulkScalarFieldState {
  _BulkScalarFieldState({
    this.enabled = false,
    this.op = ComicMetadataBulkScalarOp.replace,
    this.mixedValues = false,
  });

  bool enabled;
  ComicMetadataBulkScalarOp op;
  bool mixedValues;
  String description = '';
  DateTime? publishedAt;
}

class _BulkContentRatingFieldState {
  _BulkContentRatingFieldState({
    this.enabled = false,
    this.isR18 = false,
    this.mixedValues = false,
  });

  bool enabled;
  bool isR18;
  bool mixedValues;
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

class _BulkEditMetadataDialogState extends ConsumerState<BulkEditMetadataDialog> {
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
          (Comic c) => <String>[c.contentRating == ContentRating.r18 ? 'r18' : 'safe'],
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
      _loading = false;
    });
  }

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
    if (!tags.enabled &&
        !authors.enabled &&
        !languages.enabled &&
        !parodies.enabled &&
        !characters.enabled &&
        !_contentRatingField.enabled &&
        !_descriptionField.enabled &&
        !_publishedAtField.enabled) {
      return null;
    }
    return ComicMetadataBulkPatch(
      tags: tags.enabled
          ? ComicMetadataBulkMultiValuePatch(op: tags.op, values: tags.values)
          : null,
      authors: authors.enabled
          ? ComicMetadataBulkMultiValuePatch(
              op: authors.op,
              values: authors.values,
            )
          : null,
      languages: languages.enabled
          ? ComicMetadataBulkMultiValuePatch(
              op: languages.op,
              values: languages.values,
            )
          : null,
      parodies: parodies.enabled
          ? ComicMetadataBulkMultiValuePatch(
              op: parodies.op,
              values: parodies.values,
            )
          : null,
      characters: characters.enabled
          ? ComicMetadataBulkMultiValuePatch(
              op: characters.op,
              values: characters.values,
            )
          : null,
      contentRating: _contentRatingField.enabled
          ? (_contentRatingField.isR18 ? 'r18' : 'safe')
          : null,
      description: _descriptionField.enabled
          ? (_descriptionField.op == ComicMetadataBulkScalarOp.clear
                ? const ComicMetadataBulkDescriptionPatch.clear()
                : ComicMetadataBulkDescriptionPatch.replace(
                    _descriptionField.description,
                  ))
          : null,
      publishedAt: _publishedAtField.enabled
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
    final bool confirmed = await showDialog<bool>(
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

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ComicMetadataSmartFacetScope? scope = _scope;
    return AdaptiveFormSurface(
      title: l10n.bulkEditMetadataTitle(widget.comicIds.length),
      maxDialogWidth: _kBulkEditDialogWidth,
      scrollableBody: true,
      backgroundColor: cs.surface,
      body: _loading || scope == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(tokens.spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: tokens.spacing.lg,
                children: <Widget>[
                  _buildMultiValueField(
                    l10n: l10n,
                    kind: _BulkFieldKind.tags,
                    label: l10n.bulkEditMetadataFieldTags,
                    icon: LucideIcons.tag,
                    scope: scope,
                    childBuilder: (_BulkMultiValueFieldState state) =>
                        TagLibraryMultiSelectField(
                          label: l10n.bulkEditMetadataFieldTags,
                          icon: LucideIcons.tag,
                          selectedNames: state.values,
                          scope: scope,
                          onAdd: (String name) => _addMultiValue(
                            _BulkFieldKind.tags,
                            name,
                          ),
                          onRemove: (String name) => _removeMultiValue(
                            _BulkFieldKind.tags,
                            name,
                          ),
                        ),
                  ),
                  _buildMultiValueField(
                    l10n: l10n,
                    kind: _BulkFieldKind.authors,
                    label: l10n.bulkEditMetadataFieldAuthors,
                    icon: LucideIcons.penTool,
                    scope: scope,
                    childBuilder: (_BulkMultiValueFieldState state) =>
                        AuthorLibraryMultiSelectField(
                          label: l10n.bulkEditMetadataFieldAuthors,
                          icon: LucideIcons.penTool,
                          selectedNames: state.values,
                          scope: scope,
                          onAdd: (String name) => _addMultiValue(
                            _BulkFieldKind.authors,
                            name,
                          ),
                          onRemove: (String name) => _removeMultiValue(
                            _BulkFieldKind.authors,
                            name,
                          ),
                        ),
                  ),
                  _buildMultiValueField(
                    l10n: l10n,
                    kind: _BulkFieldKind.languages,
                    label: l10n.bulkEditMetadataFieldLanguages,
                    icon: LucideIcons.languages,
                    scope: scope,
                    childBuilder: (_BulkMultiValueFieldState state) =>
                        _LanguageChipField(
                          l10n: l10n,
                          selected: state.values,
                          onAdd: (String name) => _addMultiValue(
                            _BulkFieldKind.languages,
                            name,
                          ),
                          onRemove: (String name) => _removeMultiValue(
                            _BulkFieldKind.languages,
                            name,
                          ),
                        ),
                  ),
                  _buildMultiValueField(
                    l10n: l10n,
                    kind: _BulkFieldKind.parodies,
                    label: l10n.bulkEditMetadataFieldParodies,
                    icon: LucideIcons.bookMarked,
                    scope: scope,
                    childBuilder: (_BulkMultiValueFieldState state) =>
                        ParodyLibraryMultiSelectField(
                          label: l10n.bulkEditMetadataFieldParodies,
                          icon: LucideIcons.bookMarked,
                          selectedNames: state.values,
                          scope: scope,
                          onAdd: (String name) => _addMultiValue(
                            _BulkFieldKind.parodies,
                            name,
                          ),
                          onRemove: (String name) => _removeMultiValue(
                            _BulkFieldKind.parodies,
                            name,
                          ),
                        ),
                  ),
                  _buildMultiValueField(
                    l10n: l10n,
                    kind: _BulkFieldKind.characters,
                    label: l10n.bulkEditMetadataFieldCharacters,
                    icon: LucideIcons.userRound,
                    scope: scope,
                    childBuilder: (_BulkMultiValueFieldState state) =>
                        CharacterLibraryMultiSelectField(
                          label: l10n.bulkEditMetadataFieldCharacters,
                          icon: LucideIcons.userRound,
                          selectedNames: state.values,
                          scope: scope,
                          onAdd: (String name) => _addMultiValue(
                            _BulkFieldKind.characters,
                            name,
                          ),
                          onRemove: (String name) => _removeMultiValue(
                            _BulkFieldKind.characters,
                            name,
                          ),
                        ),
                  ),
                  _BulkContentRatingFieldEditor(
                    label: l10n.bulkEditMetadataFieldContentRating,
                    state: _contentRatingField,
                    mixedLabel: l10n.bulkEditMetadataMixedValues,
                    allAgesLabel: l10n.filterAgeAllAges,
                    onChanged: () => setState(() {}),
                  ),
                  _BulkScalarFieldEditor(
                    label: l10n.bulkEditMetadataFieldDescription,
                    state: _descriptionField,
                    mixedLabel: l10n.bulkEditMetadataMixedValues,
                    opLabels: _scalarOpLabels(l10n),
                    child: FluentTextField(
                      labelText: l10n.bulkEditMetadataFieldDescription,
                      initialValue: _descriptionField.description,
                      maxLines: 4,
                      enabled:
                          _descriptionField.op ==
                          ComicMetadataBulkScalarOp.replace,
                      onChanged: (String value) {
                        _descriptionField.description = value;
                      },
                    ),
                    onChanged: () => setState(() {}),
                  ),
                  _BulkScalarFieldEditor(
                    label: l10n.bulkEditMetadataFieldPublishedAt,
                    state: _publishedAtField,
                    mixedLabel: l10n.bulkEditMetadataMixedValues,
                    opLabels: _scalarOpLabels(l10n),
                    child: FluentDatePickerField(
                      labelText: l10n.bulkEditMetadataFieldPublishedAt,
                      value: _publishedAtField.publishedAt,
                      enabled:
                          _publishedAtField.op ==
                          ComicMetadataBulkScalarOp.replace,
                      onChanged: (DateTime? value) {
                        _publishedAtField.publishedAt = value;
                      },
                    ),
                    onChanged: () => setState(() {}),
                  ),
                ],
              ),
            ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _onSave,
          child: Text(l10n.commonSaveChanges),
        ),
      ],
    );
  }

  Widget _buildMultiValueField({
    required AppLocalizations l10n,
    required _BulkFieldKind kind,
    required String label,
    required IconData icon,
    required ComicMetadataSmartFacetScope scope,
    required Widget Function(_BulkMultiValueFieldState state) childBuilder,
  }) {
    final _BulkMultiValueFieldState state = _multiFields[kind]!;
    return _BulkMultiValueFieldEditor(
      label: label,
      state: state,
      mixedLabel: l10n.bulkEditMetadataMixedValues,
      opLabels: _multiOpLabels(l10n),
      child: childBuilder(state),
      onChanged: () => setState(() {}),
    );
  }

  void _addMultiValue(_BulkFieldKind kind, String name) {
    setState(() {
      final _BulkMultiValueFieldState field = _multiFields[kind]!;
      if (!field.values.contains(name)) {
        field.values = <String>[...field.values, name];
      }
    });
  }

  void _removeMultiValue(_BulkFieldKind kind, String name) {
    setState(() {
      _multiFields[kind]!.values = _multiFields[kind]!
          .values
          .where((String v) => v != name)
          .toList();
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

class _BulkMultiValueFieldEditor extends StatelessWidget {
  const _BulkMultiValueFieldEditor({
    required this.label,
    required this.state,
    required this.mixedLabel,
    required this.opLabels,
    required this.child,
    required this.onChanged,
  });

  final String label;
  final _BulkMultiValueFieldState state;
  final String mixedLabel;
  final Map<ComicMetadataBulkMultiValueOp, String> opLabels;
  final Widget child;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: tokens.spacing.sm,
      children: <Widget>[
        Row(
          children: <Widget>[
            ToggleSwitch(
              checked: state.enabled,
              onChange: () {
                state.enabled = !state.enabled;
                onChanged();
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: tokens.text.bodyMd,
                  fontWeight: FontWeight.w600,
                  color: cs.hentai.textPrimary,
                ),
              ),
            ),
            if (state.mixedValues)
              Text(
                mixedLabel,
                style: TextStyle(
                  fontSize: tokens.text.labelXs,
                  color: cs.hentai.textTertiary,
                ),
              ),
          ],
        ),
        if (state.enabled) ...<Widget>[
          DropdownButtonFormField<ComicMetadataBulkMultiValueOp>(
            value: state.op,
            decoration: InputDecoration(
              labelText: context.l10n.bulkEditMetadataOperationLabel,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(tokens.radius.xs),
              ),
            ),
            items: ComicMetadataBulkMultiValueOp.values
                .map(
                  (ComicMetadataBulkMultiValueOp op) =>
                      DropdownMenuItem<ComicMetadataBulkMultiValueOp>(
                        value: op,
                        child: Text(opLabels[op] ?? op.name),
                      ),
                )
                .toList(),
            onChanged: (ComicMetadataBulkMultiValueOp? op) {
              if (op == null) {
                return;
              }
              state.op = op;
              onChanged();
            },
          ),
          child,
        ],
      ],
    );
  }
}

class _BulkScalarFieldEditor extends StatelessWidget {
  const _BulkScalarFieldEditor({
    required this.label,
    required this.state,
    required this.mixedLabel,
    required this.opLabels,
    required this.child,
    required this.onChanged,
  });

  final String label;
  final _BulkScalarFieldState state;
  final String mixedLabel;
  final Map<ComicMetadataBulkScalarOp, String> opLabels;
  final Widget child;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: tokens.spacing.sm,
      children: <Widget>[
        Row(
          children: <Widget>[
            ToggleSwitch(
              checked: state.enabled,
              onChange: () {
                state.enabled = !state.enabled;
                onChanged();
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: tokens.text.bodyMd,
                  fontWeight: FontWeight.w600,
                  color: cs.hentai.textPrimary,
                ),
              ),
            ),
            if (state.mixedValues)
              Text(
                mixedLabel,
                style: TextStyle(
                  fontSize: tokens.text.labelXs,
                  color: cs.hentai.textTertiary,
                ),
              ),
          ],
        ),
        if (state.enabled) ...<Widget>[
          DropdownButtonFormField<ComicMetadataBulkScalarOp>(
            value: state.op,
            decoration: InputDecoration(
              labelText: context.l10n.bulkEditMetadataOperationLabel,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(tokens.radius.xs),
              ),
            ),
            items: ComicMetadataBulkScalarOp.values
                .map(
                  (ComicMetadataBulkScalarOp op) =>
                      DropdownMenuItem<ComicMetadataBulkScalarOp>(
                        value: op,
                        child: Text(opLabels[op] ?? op.name),
                      ),
                )
                .toList(),
            onChanged: (ComicMetadataBulkScalarOp? op) {
              if (op == null) {
                return;
              }
              state.op = op;
              onChanged();
            },
          ),
          child,
        ],
      ],
    );
  }
}

class _BulkContentRatingFieldEditor extends StatelessWidget {
  const _BulkContentRatingFieldEditor({
    required this.label,
    required this.state,
    required this.mixedLabel,
    required this.allAgesLabel,
    required this.onChanged,
  });

  final String label;
  final _BulkContentRatingFieldState state;
  final String mixedLabel;
  final String allAgesLabel;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: tokens.spacing.sm,
      children: <Widget>[
        Row(
          children: <Widget>[
            ToggleSwitch(
              checked: state.enabled,
              onChange: () {
                state.enabled = !state.enabled;
                onChanged();
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: tokens.text.bodyMd,
                  fontWeight: FontWeight.w600,
                  color: cs.hentai.textPrimary,
                ),
              ),
            ),
            if (state.mixedValues)
              Text(
                mixedLabel,
                style: TextStyle(
                  fontSize: tokens.text.labelXs,
                  color: cs.hentai.textTertiary,
                ),
              ),
          ],
        ),
        if (state.enabled)
          FluentToggleField(
            labelText: label,
            value: state.isR18,
            onChanged: (bool value) {
              state.isR18 = value;
              onChanged();
            },
            checkedLabel: 'R18',
            uncheckedLabel: allAgesLabel,
          ),
      ],
    );
  }
}
