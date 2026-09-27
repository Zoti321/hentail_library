import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/library/comic_metadata_bulk_patch_types.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/form/author_library_multi_select_field.dart';
import 'package:hentai_library/ui/core/widgets/form/tag_library_multi_select_field.dart';
import 'package:hentai_library/ui/core/widgets/foundation/toggle_switch.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/adaptive_form_surface.dart';
import 'package:hentai_library/ui/features/library/view_models/comic_metadata_smart_facet_providers.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const double _kBulkEditDialogWidth = 720;

enum _BulkFieldKind { tags, authors }

class _BulkFieldEditorState {
  _BulkFieldEditorState({
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
  final Map<_BulkFieldKind, _BulkFieldEditorState> _fields =
      <_BulkFieldKind, _BulkFieldEditorState>{
        _BulkFieldKind.tags: _BulkFieldEditorState(),
        _BulkFieldKind.authors: _BulkFieldEditorState(),
      };
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
      _fields[_BulkFieldKind.tags]!.mixedValues = _isMixed(
        comics.map((Comic c) => c.tags.map((t) => t.name).toList()),
      );
      _fields[_BulkFieldKind.authors]!.mixedValues = _isMixed(
        comics.map((Comic c) => c.authors.map((a) => a.name).toList()),
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
    final _BulkFieldEditorState tags = _fields[_BulkFieldKind.tags]!;
    final _BulkFieldEditorState authors = _fields[_BulkFieldKind.authors]!;
    if (!tags.enabled && !authors.enabled) {
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
                  _BulkFieldEditor(
                    label: l10n.bulkEditMetadataFieldTags,
                    state: _fields[_BulkFieldKind.tags]!,
                    mixedLabel: l10n.bulkEditMetadataMixedValues,
                    opLabels: _opLabels(l10n),
                    child: TagLibraryMultiSelectField(
                      label: l10n.bulkEditMetadataFieldTags,
                      icon: LucideIcons.tag,
                      selectedNames: _fields[_BulkFieldKind.tags]!.values,
                      scope: scope,
                      onAdd: (String name) {
                        setState(() {
                          final _BulkFieldEditorState field =
                              _fields[_BulkFieldKind.tags]!;
                          if (!field.values.contains(name)) {
                            field.values = <String>[...field.values, name];
                          }
                        });
                      },
                      onRemove: (String name) {
                        setState(() {
                          _fields[_BulkFieldKind.tags]!.values = _fields[
                                  _BulkFieldKind.tags]!
                              .values
                              .where((String v) => v != name)
                              .toList();
                        });
                      },
                    ),
                    onChanged: () => setState(() {}),
                  ),
                  _BulkFieldEditor(
                    label: l10n.bulkEditMetadataFieldAuthors,
                    state: _fields[_BulkFieldKind.authors]!,
                    mixedLabel: l10n.bulkEditMetadataMixedValues,
                    opLabels: _opLabels(l10n),
                    child: AuthorLibraryMultiSelectField(
                      label: l10n.bulkEditMetadataFieldAuthors,
                      icon: LucideIcons.penTool,
                      selectedNames: _fields[_BulkFieldKind.authors]!.values,
                      scope: scope,
                      onAdd: (String name) {
                        setState(() {
                          final _BulkFieldEditorState field =
                              _fields[_BulkFieldKind.authors]!;
                          if (!field.values.contains(name)) {
                            field.values = <String>[...field.values, name];
                          }
                        });
                      },
                      onRemove: (String name) {
                        setState(() {
                          _fields[_BulkFieldKind.authors]!.values = _fields[
                                  _BulkFieldKind.authors]!
                              .values
                              .where((String v) => v != name)
                              .toList();
                        });
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

  Map<ComicMetadataBulkMultiValueOp, String> _opLabels(AppLocalizations l10n) {
    return <ComicMetadataBulkMultiValueOp, String>{
      ComicMetadataBulkMultiValueOp.add: l10n.bulkEditMetadataOpAdd,
      ComicMetadataBulkMultiValueOp.remove: l10n.bulkEditMetadataOpRemove,
      ComicMetadataBulkMultiValueOp.replace: l10n.bulkEditMetadataOpReplace,
    };
  }
}

class _BulkFieldEditor extends StatelessWidget {
  const _BulkFieldEditor({
    required this.label,
    required this.state,
    required this.mixedLabel,
    required this.opLabels,
    required this.child,
    required this.onChanged,
  });

  final String label;
  final _BulkFieldEditorState state;
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
