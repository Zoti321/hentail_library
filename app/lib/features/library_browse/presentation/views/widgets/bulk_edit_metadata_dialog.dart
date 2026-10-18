import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/domain/library/comic_metadata_bulk_patch_types.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/value_objects/comic_language.dart';
import 'package:hentai_library/shared/ui/layout/app_layout_breakpoints.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hentai_library/shared/ui/widgets/chrome/capsule_tab_bar.dart';
import 'package:hentai_library/shared/ui/widgets/element/chip/outlined_meta_chip.dart';
import 'package:hentai_library/features/library_browse/presentation/views/widgets/form/author_library_multi_select_field.dart';
import 'package:hentai_library/features/library_browse/presentation/views/widgets/form/character_library_multi_select_field.dart';
import 'package:hentai_library/shared/ui/widgets/form/fluent_date_picker_field.dart';
import 'package:hentai_library/shared/ui/widgets/form/fluent_text_field.dart';
import 'package:hentai_library/shared/ui/widgets/form/fluent_toggle_field.dart';
import 'package:hentai_library/features/library_browse/presentation/views/widgets/form/parody_library_multi_select_field.dart';
import 'package:hentai_library/features/library_browse/presentation/views/widgets/form/tag_library_multi_select_field.dart';
import 'package:hentai_library/shared/ui/widgets/overlays/dialog/adaptive_form_surface.dart';
import 'package:hentai_library/shared/ui/widgets/overlays/dialog/dialog_side_tab_bar.dart';
import 'package:hentai_library/features/library_browse/domain/bulk_metadata_edit_session.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/comic_metadata_smart_facet_providers.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_page_comics_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

part 'bulk_edit_metadata_panels.dart';

const double _kBulkEditDialogWidth = 720;
const double _kBulkEditDialogRadius = 4;
const double _kBulkEditShellChromeReserve = 120;
const double _kBulkEditBodyMinHeight = 240;
const double _kBulkEditFieldListWidth = 200;

enum _BulkEditTab { general, authorsAndTags }

extension _BulkEditTabFields on _BulkEditTab {
  List<BulkMetadataEditFieldKind> get fields => switch (this) {
    _BulkEditTab.general => <BulkMetadataEditFieldKind>[
      BulkMetadataEditFieldKind.description,
      BulkMetadataEditFieldKind.publishedAt,
      BulkMetadataEditFieldKind.contentRating,
      BulkMetadataEditFieldKind.languages,
    ],
    _BulkEditTab.authorsAndTags => <BulkMetadataEditFieldKind>[
      BulkMetadataEditFieldKind.authors,
      BulkMetadataEditFieldKind.tags,
      BulkMetadataEditFieldKind.parodies,
      BulkMetadataEditFieldKind.characters,
    ],
  };
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
  final BulkMetadataEditSession _session = BulkMetadataEditSession();
  _BulkEditTab _selectedTab = _BulkEditTab.general;
  BulkMetadataEditFieldKind? _selectedField;
  bool _loading = true;
  ComicMetadataSmartFacetScope? _scope;

  @override
  void initState() {
    super.initState();
    _loadMixedHints();
  }

  Future<void> _loadMixedHints() async {
    final List<Comic> comics = await ref.read(
      bulkEditComicsByIdsProvider(widget.comicIds).future,
    );
    if (!mounted) {
      return;
    }
    final Comic? anchor = comics.isNotEmpty ? comics.first : null;
    setState(() {
      _session.applyMixedHintsFromComics(comics);
      if (anchor != null) {
        _scope = (
          comicId: anchor.comicId,
          title: anchor.title,
          resourcePath: anchor.path,
          seriesId: null,
        );
      }
      _selectedField = BulkMetadataEditFieldKind.description;
      _loading = false;
    });
  }

  void _markDirty(BulkMetadataEditFieldKind kind) {
    if (!_session.isFieldDirty(kind)) {
      _session.markDirty(kind);
      setState(() {});
    }
  }

  bool _isFieldDirty(BulkMetadataEditFieldKind kind) =>
      _session.isFieldDirty(kind);

  BulkMetadataEditFieldKind _defaultFieldForTab(_BulkEditTab tab) => tab.fields.first;

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

  void _selectField(BulkMetadataEditFieldKind kind) {
    if (_selectedField == kind) {
      return;
    }
    setState(() => _selectedField = kind);
  }

  String _fieldLabel(AppLocalizations l10n, BulkMetadataEditFieldKind kind) {
    return switch (kind) {
      BulkMetadataEditFieldKind.tags => l10n.bulkEditMetadataFieldTags,
      BulkMetadataEditFieldKind.authors => l10n.bulkEditMetadataFieldAuthors,
      BulkMetadataEditFieldKind.languages => l10n.bulkEditMetadataFieldLanguages,
      BulkMetadataEditFieldKind.parodies => l10n.bulkEditMetadataFieldParodies,
      BulkMetadataEditFieldKind.characters => l10n.bulkEditMetadataFieldCharacters,
      BulkMetadataEditFieldKind.contentRating => l10n.bulkEditMetadataFieldContentRating,
      BulkMetadataEditFieldKind.description => l10n.bulkEditMetadataFieldDescription,
      BulkMetadataEditFieldKind.publishedAt => l10n.bulkEditMetadataFieldPublishedAt,
    };
  }

  String? _fieldSummary(AppLocalizations l10n, BulkMetadataEditFieldKind kind) {
    if (!_isFieldDirty(kind)) {
      return null;
    }
    return switch (kind) {
      BulkMetadataEditFieldKind.languages ||
      BulkMetadataEditFieldKind.authors ||
      BulkMetadataEditFieldKind.tags ||
      BulkMetadataEditFieldKind.parodies ||
      BulkMetadataEditFieldKind.characters => () {
        final BulkMetadataEditMultiValueFieldState state = _session.multiFields[kind]!;
        return l10n.bulkEditMetadataFieldSummaryCount(
          _multiOpLabels(l10n)[state.op] ?? state.op.name,
          state.values.length,
        );
      }(),
      BulkMetadataEditFieldKind.description || BulkMetadataEditFieldKind.publishedAt => () {
        final BulkMetadataEditScalarFieldState state = switch (kind) {
          BulkMetadataEditFieldKind.description => _session.descriptionField,
          BulkMetadataEditFieldKind.publishedAt => _session.publishedAtField,
          _ => throw StateError('$kind'),
        };
        return state.op == ComicMetadataBulkScalarOp.clear
            ? l10n.bulkEditMetadataFieldSummaryClear
            : l10n.bulkEditMetadataFieldSummaryReplace;
      }(),
      BulkMetadataEditFieldKind.contentRating =>
        _session.contentRatingField.isR18 ? 'R18' : l10n.filterAgeAllAges,
    };
  }

  ComicMetadataBulkPatch? _buildPatch() => _session.buildPatch();

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
            labelFor: (BulkMetadataEditFieldKind kind) => _fieldLabel(l10n, kind),
            isDirty: _isFieldDirty,
            isMixed: _isFieldMixed,
            summaryFor: (BulkMetadataEditFieldKind kind) => _fieldSummary(l10n, kind),
            mixedLabel: l10n.bulkEditMetadataMixedValues,
            onSelect: _selectField,
          ),
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

  bool _isFieldMixed(BulkMetadataEditFieldKind kind) {
    return switch (kind) {
      BulkMetadataEditFieldKind.description => _session.descriptionField.mixedValues,
      BulkMetadataEditFieldKind.publishedAt => _session.publishedAtField.mixedValues,
      BulkMetadataEditFieldKind.contentRating => _session.contentRatingField.mixedValues,
      BulkMetadataEditFieldKind.languages ||
      BulkMetadataEditFieldKind.authors ||
      BulkMetadataEditFieldKind.tags ||
      BulkMetadataEditFieldKind.parodies ||
      BulkMetadataEditFieldKind.characters => _session.multiFields[kind]!.mixedValues,
    };
  }

  Widget _buildFieldEditor(
    AppLocalizations l10n,
    ComicMetadataSmartFacetScope scope,
    BulkMetadataEditFieldKind kind,
  ) {
    return switch (kind) {
      BulkMetadataEditFieldKind.tags ||
      BulkMetadataEditFieldKind.authors ||
      BulkMetadataEditFieldKind.languages ||
      BulkMetadataEditFieldKind.parodies ||
      BulkMetadataEditFieldKind.characters => _BulkMultiValueFieldDetail(
        state: _session.multiFields[kind]!,
        opLabels: _multiOpLabels(l10n),
        onChanged: () {
          _markDirty(kind);
          setState(() {});
        },
        child: _buildMultiValueInput(l10n, scope, kind),
      ),
      BulkMetadataEditFieldKind.description || BulkMetadataEditFieldKind.publishedAt => () {
        final BulkMetadataEditScalarFieldState state = switch (kind) {
          BulkMetadataEditFieldKind.description => _session.descriptionField,
          BulkMetadataEditFieldKind.publishedAt => _session.publishedAtField,
          _ => throw StateError('$kind'),
        };
        return _BulkScalarFieldDetail(
          state: state,
          opLabels: _scalarOpLabels(l10n),
          onChanged: () {
            _markDirty(kind);
            setState(() {});
          },
          child: kind == BulkMetadataEditFieldKind.description
              ? FluentTextField(
                  labelText: l10n.bulkEditMetadataFieldDescription,
                  initialValue: _session.descriptionField.description,
                  maxLines: 4,
                  enabled:
                      _session.descriptionField.op == ComicMetadataBulkScalarOp.replace,
                  onChanged: (String value) {
                    _session.descriptionField.description = value;
                    _markDirty(BulkMetadataEditFieldKind.description);
                  },
                )
              : FluentDatePickerField(
                  labelText: l10n.bulkEditMetadataFieldPublishedAt,
                  value: _session.publishedAtField.publishedAt,
                  enabled:
                      _session.publishedAtField.op == ComicMetadataBulkScalarOp.replace,
                  onChanged: (DateTime? value) {
                    _session.publishedAtField.publishedAt = value;
                    _markDirty(BulkMetadataEditFieldKind.publishedAt);
                  },
                ),
        );
      }(),
      BulkMetadataEditFieldKind.contentRating => _BulkContentRatingFieldDetail(
        label: l10n.bulkEditMetadataFieldContentRating,
        state: _session.contentRatingField,
        allAgesLabel: l10n.filterAgeAllAges,
        onChanged: () {
          _markDirty(BulkMetadataEditFieldKind.contentRating);
          setState(() {});
        },
      ),
    };
  }

  Widget _buildMultiValueInput(
    AppLocalizations l10n,
    ComicMetadataSmartFacetScope scope,
    BulkMetadataEditFieldKind kind,
  ) {
    final BulkMetadataEditMultiValueFieldState state = _session.multiFields[kind]!;
    return switch (kind) {
      BulkMetadataEditFieldKind.tags => TagLibraryMultiSelectField(
        label: l10n.bulkEditMetadataFieldTags,
        icon: LucideIcons.tag,
        selectedNames: state.values,
        scope: scope,
        onAdd: (String name) => _addMultiValue(BulkMetadataEditFieldKind.tags, name),
        onRemove: (String name) => _removeMultiValue(BulkMetadataEditFieldKind.tags, name),
      ),
      BulkMetadataEditFieldKind.authors => AuthorLibraryMultiSelectField(
        label: l10n.bulkEditMetadataFieldAuthors,
        icon: LucideIcons.penTool,
        selectedNames: state.values,
        scope: scope,
        onAdd: (String name) => _addMultiValue(BulkMetadataEditFieldKind.authors, name),
        onRemove: (String name) =>
            _removeMultiValue(BulkMetadataEditFieldKind.authors, name),
      ),
      BulkMetadataEditFieldKind.languages => _LanguageChipField(
        l10n: l10n,
        selected: state.values,
        onAdd: (String name) => _addMultiValue(BulkMetadataEditFieldKind.languages, name),
        onRemove: (String name) =>
            _removeMultiValue(BulkMetadataEditFieldKind.languages, name),
      ),
      BulkMetadataEditFieldKind.parodies => ParodyLibraryMultiSelectField(
        label: l10n.bulkEditMetadataFieldParodies,
        icon: LucideIcons.bookMarked,
        selectedNames: state.values,
        scope: scope,
        onAdd: (String name) => _addMultiValue(BulkMetadataEditFieldKind.parodies, name),
        onRemove: (String name) =>
            _removeMultiValue(BulkMetadataEditFieldKind.parodies, name),
      ),
      BulkMetadataEditFieldKind.characters => CharacterLibraryMultiSelectField(
        label: l10n.bulkEditMetadataFieldCharacters,
        icon: LucideIcons.userRound,
        selectedNames: state.values,
        scope: scope,
        onAdd: (String name) => _addMultiValue(BulkMetadataEditFieldKind.characters, name),
        onRemove: (String name) =>
            _removeMultiValue(BulkMetadataEditFieldKind.characters, name),
      ),
      _ => throw StateError('$kind'),
    };
  }

  void _addMultiValue(BulkMetadataEditFieldKind kind, String name) {
    setState(() {
      final BulkMetadataEditMultiValueFieldState field = _session.multiFields[kind]!;
      if (!field.values.contains(name)) {
        field.values = <String>[...field.values, name];
      }
      _session.dirtyFields.add(kind);
    });
  }

  void _removeMultiValue(BulkMetadataEditFieldKind kind, String name) {
    setState(() {
      _session.multiFields[kind]!.values = _session.multiFields[kind]!.values
          .where((String v) => v != name)
          .toList();
      _session.dirtyFields.add(kind);
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
                    labelFor: (BulkMetadataEditFieldKind kind) => _fieldLabel(l10n, kind),
                    isDirty: _isFieldDirty,
                    isMixed: _isFieldMixed,
                    summaryFor: (BulkMetadataEditFieldKind kind) =>
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
