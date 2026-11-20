import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_catalog_query.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_browse_providers.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

const double _kSectionInset = 16;
const double _kSortIconSlotWidth = 20;
const double _kSortIconLabelGap = 8;
const Duration _kFilterAccordionDuration = Duration(milliseconds: 200);
const Curve _kFilterAccordionCurve = Curves.easeOutCubic;

/// Adaptive filter/sort sheet for Image set browse (owner query; not Comic facade).
abstract final class ImageSetLibraryFilterSheet {
  ImageSetLibraryFilterSheet._();

  static Future<void> show(BuildContext context, {required String libraryId}) {
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final AppLocalizations l10n = context.l10n;
    final OverlayRouteScopeSnapshot scope = OverlayRouteScopeSnapshot.capture(
      context,
    );
    final M3EThemeData m3e = withAppFontFamily(M3ETheme.of(context));
    // Align sheet chrome title with comic library browse filter sheet.
    final String title = l10n.libraryFilterSortTooltip;
    final Widget body = OverlayRouteScope(
      scope: scope,
      child: M3ETheme(
        data: m3e,
        child: _ImageSetFilterSortBody(libraryId: libraryId),
      ),
    );

    if (libraryFilterSortPrefersBottomSheetForViewport(viewportWidth)) {
      return M3EBottomSheet.show<void>(
        context,
        useRootNavigator: true,
        expandToFullScreen: true,
        initialValue: M3EBottomSheetValue.fullScreen,
        fullScreenTitle: title,
        theme: m3e.bottomSheetTheme,
        builder: (BuildContext sheetContext) {
          return PrimaryScrollController.none(
            child: SingleChildScrollView(child: body),
          );
        },
      );
    }

    return M3ESideSheet.show<void>(
      context,
      title: title,
      width: libraryFilterSortSideSheetWidthForViewport(viewportWidth),
      detached: libraryFilterSortSideSheetDetachedForViewport(viewportWidth),
      theme: libraryFilterSortSideSheetTheme(m3e),
      scrollable: true,
      useRootNavigator: true,
      body: body,
    );
  }
}

class _ImageSetFilterSortBody extends ConsumerStatefulWidget {
  const _ImageSetFilterSortBody({required this.libraryId});

  final String libraryId;

  @override
  ConsumerState<_ImageSetFilterSortBody> createState() =>
      _ImageSetFilterSortBodyState();
}

class _ImageSetFilterSortBodyState
    extends ConsumerState<_ImageSetFilterSortBody> {
  late TextEditingController _authors;
  late TextEditingController _tags;
  late TextEditingController _parodies;
  late TextEditingController _characters;
  Timer? _facetDebounce;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _authors = TextEditingController();
    _tags = TextEditingController();
    _parodies = TextEditingController();
    _characters = TextEditingController();
    unawaited(_hydrate());
  }

  Future<void> _hydrate() async {
    final ImageSetBrowsePreferences loaded = await ref.read(
      imageSetBrowsePreferencesProvider.future,
    );
    if (!mounted) {
      return;
    }
    _syncFacetControllers(loaded);
    setState(() => _ready = true);
  }

  void _syncFacetControllers(ImageSetBrowsePreferences prefs) {
    _authors.text = prefs.authors.any.join(', ');
    _tags.text = prefs.tags.any.join(', ');
    _parodies.text = prefs.parodies.any.join(', ');
    _characters.text = prefs.characters.any.join(', ');
  }

  @override
  void dispose() {
    _facetDebounce?.cancel();
    _authors.dispose();
    _tags.dispose();
    _parodies.dispose();
    _characters.dispose();
    super.dispose();
  }

  Set<String> _parseNames(String raw) => raw
      .split(RegExp(r'[,，]'))
      .map((String s) => s.trim())
      .where((String s) => s.isNotEmpty)
      .toSet();

  ImageSetBrowsePreferences _composeFacets(
    ImageSetBrowsePreferences base,
  ) => base.copyWith(
    authors: ImageSetFacetFilter(
      any: _parseNames(_authors.text),
      unassigned: base.authors.unassigned,
    ),
    tags: ImageSetFacetFilter(
      any: _parseNames(_tags.text),
      unassigned: base.tags.unassigned,
    ),
    parodies: ImageSetFacetFilter(
      any: _parseNames(_parodies.text),
      unassigned: base.parodies.unassigned,
    ),
    characters: ImageSetFacetFilter(
      any: _parseNames(_characters.text),
      unassigned: base.characters.unassigned,
    ),
  );

  Future<void> _replace(ImageSetBrowsePreferences next) async {
    await ref.read(imageSetBrowsePreferencesProvider.notifier).replace(next);
    ref
        .read(imageSetCatalogPageIndexProvider.notifier)
        .setPage(widget.libraryId, 1);
  }

  Future<void> _replaceFromFacets(ImageSetBrowsePreferences base) async {
    await _replace(_composeFacets(base));
  }

  void _scheduleFacetCommit() {
    _facetDebounce?.cancel();
    _facetDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) {
        return;
      }
      final ImageSetBrowsePreferences base = ref
          .read(imageSetBrowsePreferencesProvider)
          .requireValue;
      unawaited(_replaceFromFacets(base));
    });
  }

  Future<void> _reset() async {
    await ref.read(imageSetBrowsePreferencesProvider.notifier).reset();
    ref
        .read(imageSetCatalogPageIndexProvider.notifier)
        .setPage(widget.libraryId, 1);
    if (!mounted) {
      return;
    }
    setState(
      () => _syncFacetControllers(ImageSetBrowsePreferences.defaults),
    );
  }

  void _setSortField(
    ImageSetBrowsePreferences prefs,
    ImageSetSortField field,
  ) {
    final ImageSetSortOption existing = prefs.sort;
    final ImageSetSortOption next = existing.field == field
        ? existing.copyWith(descending: !existing.descending)
        : ImageSetSortOption(field: field, descending: false);
    unawaited(_replace(prefs.copyWith(sort: next)));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AsyncValue<ImageSetBrowsePreferences> prefsAsync = ref.watch(
      imageSetBrowsePreferencesProvider,
    );

    if (!_ready || prefsAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final ImageSetBrowsePreferences prefs =
        prefsAsync.asData?.value ?? ImageSetBrowsePreferences.defaults;
    final bool isDefault = prefs == ImageSetBrowsePreferences.defaults;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        key: const ValueKey<String>('imageSetFilterSortBody'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _kSectionInset),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    l10n.libraryFilterSection,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                M3EIconButton(
                  key: const ValueKey<String>('imageSetFilterReset'),
                  icon: const Icon(Symbols.settings_backup_restore, size: 20),
                  tooltip: l10n.libraryResetAllFilters,
                  semanticLabel: l10n.libraryResetAllFilters,
                  onPressed: isDefault ? null : _reset,
                  variant: M3EIconButtonVariant.standard,
                  size: M3EIconButtonSize.sm,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _ImageSetFilterFields(
            prefs: prefs,
            authors: _authors,
            tags: _tags,
            parodies: _parodies,
            characters: _characters,
            onFacetTextChanged: _scheduleFacetCommit,
            onPrefsChanged: _replace,
            onFacetPrefsChanged: _replaceFromFacets,
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(left: _kSectionInset),
            child: Text(
              l10n.libraryGroupSection,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _ImageSetGroupingSection(
            grouping: prefs.grouping,
            onSelected: (ImageSetGrouping grouping) =>
                unawaited(_replace(prefs.copyWith(grouping: grouping))),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(left: _kSectionInset),
            child: Text(
              l10n.librarySortSection,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final ImageSetSortField field in ImageSetSortField.values)
                _ImageSetSortRow(
                  field: field,
                  sort: prefs.sort,
                  onTap: () => _setSortField(prefs, field),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImageSetFilterFields extends StatelessWidget {
  const _ImageSetFilterFields({
    required this.prefs,
    required this.authors,
    required this.tags,
    required this.parodies,
    required this.characters,
    required this.onFacetTextChanged,
    required this.onPrefsChanged,
    required this.onFacetPrefsChanged,
  });

  final ImageSetBrowsePreferences prefs;
  final TextEditingController authors;
  final TextEditingController tags;
  final TextEditingController parodies;
  final TextEditingController characters;
  final VoidCallback onFacetTextChanged;
  final Future<void> Function(ImageSetBrowsePreferences next) onPrefsChanged;
  final Future<void> Function(ImageSetBrowsePreferences base)
  onFacetPrefsChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _FilterAccordion(
          title: l10n.imageSetFilterRequireImages,
          child: _CheckboxOptionRow(
            label: l10n.imageSetFilterRequireImages,
            selected: prefs.requireImages,
            onTap: () => unawaited(
              onPrefsChanged(
                prefs.copyWith(requireImages: !prefs.requireImages),
              ),
            ),
          ),
        ),
        _FilterAccordion(
          title: l10n.imageSetFilterCarrierShape,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              _kSectionInset,
              0,
              _kSectionInset,
              8,
            ),
            child: SegmentedButton<ImageSetCarrierShape?>(
              segments: <ButtonSegment<ImageSetCarrierShape?>>[
                ButtonSegment<ImageSetCarrierShape?>(
                  value: null,
                  label: Text(l10n.imageSetFilterCarrierAny),
                ),
                ButtonSegment<ImageSetCarrierShape?>(
                  value: ImageSetCarrierShape.directory,
                  label: Text(l10n.imageSetFilterCarrierDirectory),
                ),
                ButtonSegment<ImageSetCarrierShape?>(
                  value: ImageSetCarrierShape.rootArchive,
                  label: Text(l10n.imageSetFilterCarrierArchive),
                ),
              ],
              selected: <ImageSetCarrierShape?>{prefs.carrierShape},
              onSelectionChanged: (Set<ImageSetCarrierShape?> next) {
                final ImageSetCarrierShape? shape = next.first;
                unawaited(
                  onPrefsChanged(
                    shape == null
                        ? prefs.copyWith(clearCarrierShape: true)
                        : prefs.copyWith(carrierShape: shape),
                  ),
                );
              },
            ),
          ),
        ),
        _FilterAccordion(
          title: l10n.imageSetFilterAuthors,
          child: _FacetAccordionBody(
            controller: authors,
            fieldLabel: l10n.imageSetFilterAuthors,
            unassignedLabel: l10n.imageSetFilterAuthorsUnassigned,
            unassigned: prefs.authors.unassigned,
            spacing: theme.spacing,
            onChanged: onFacetTextChanged,
            onUnassignedChanged: (bool value) => unawaited(
              onFacetPrefsChanged(
                prefs.copyWith(
                  authors: prefs.authors.copyWith(unassigned: value),
                ),
              ),
            ),
          ),
        ),
        _FilterAccordion(
          title: l10n.imageSetFilterTags,
          child: _FacetAccordionBody(
            controller: tags,
            fieldLabel: l10n.imageSetFilterTags,
            unassignedLabel: l10n.imageSetFilterTagsUnassigned,
            unassigned: prefs.tags.unassigned,
            spacing: theme.spacing,
            onChanged: onFacetTextChanged,
            onUnassignedChanged: (bool value) => unawaited(
              onFacetPrefsChanged(
                prefs.copyWith(tags: prefs.tags.copyWith(unassigned: value)),
              ),
            ),
          ),
        ),
        _FilterAccordion(
          title: l10n.imageSetFilterParodies,
          child: _FacetAccordionBody(
            controller: parodies,
            fieldLabel: l10n.imageSetFilterParodies,
            unassignedLabel: l10n.imageSetFilterParodiesUnassigned,
            unassigned: prefs.parodies.unassigned,
            spacing: theme.spacing,
            onChanged: onFacetTextChanged,
            onUnassignedChanged: (bool value) => unawaited(
              onFacetPrefsChanged(
                prefs.copyWith(
                  parodies: prefs.parodies.copyWith(unassigned: value),
                ),
              ),
            ),
          ),
        ),
        _FilterAccordion(
          title: l10n.imageSetFilterCharacters,
          child: _FacetAccordionBody(
            controller: characters,
            fieldLabel: l10n.imageSetFilterCharacters,
            unassignedLabel: l10n.imageSetFilterCharactersUnassigned,
            unassigned: prefs.characters.unassigned,
            spacing: theme.spacing,
            onChanged: onFacetTextChanged,
            onUnassignedChanged: (bool value) => unawaited(
              onFacetPrefsChanged(
                prefs.copyWith(
                  characters: prefs.characters.copyWith(unassigned: value),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Comic-aligned collapsible filter group (title + chevron).
class _FilterAccordion extends StatefulWidget {
  const _FilterAccordion({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  State<_FilterAccordion> createState() => _FilterAccordionState();
}

class _FilterAccordionState extends State<_FilterAccordion> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          hoverColor: theme.hoverColor,
          splashColor: theme.splashColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _kSectionInset,
              vertical: 10,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: _kFilterAccordionDuration,
                  curve: _kFilterAccordionCurve,
                  child: Icon(
                    LucideIcons.chevronDown,
                    size: 16,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: _kFilterAccordionDuration,
          curve: _kFilterAccordionCurve,
          alignment: Alignment.topCenter,
          child: _expanded ? widget.child : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _FacetAccordionBody extends StatelessWidget {
  const _FacetAccordionBody({
    required this.controller,
    required this.fieldLabel,
    required this.unassignedLabel,
    required this.unassigned,
    required this.spacing,
    required this.onChanged,
    required this.onUnassignedChanged,
  });

  final TextEditingController controller;
  final String fieldLabel;
  final String unassignedLabel;
  final bool unassigned;
  final M3ESpacing spacing;
  final VoidCallback onChanged;
  final ValueChanged<bool> onUnassignedChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        _kSectionInset,
        0,
        _kSectionInset,
        spacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            controller: controller,
            decoration: InputDecoration(labelText: fieldLabel),
            onChanged: (_) => onChanged(),
          ),
          _CheckboxOptionRow(
            label: unassignedLabel,
            selected: unassigned,
            onTap: () => onUnassignedChanged(!unassigned),
            inset: false,
          ),
        ],
      ),
    );
  }
}

class _CheckboxOptionRow extends StatelessWidget {
  const _CheckboxOptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
    this.inset = true,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool inset;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      hoverColor: theme.hoverColor,
      splashColor: theme.splashColor,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: inset ? _kSectionInset : 0,
          vertical: 8,
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: selected,
                onChanged: (_) => onTap(),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          ],
        ),
      ),
    );
  }
}

class _ImageSetGroupingSection extends StatelessWidget {
  const _ImageSetGroupingSection({
    required this.grouping,
    required this.onSelected,
  });

  final ImageSetGrouping grouping;
  final ValueChanged<ImageSetGrouping> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _GroupingRow(
          label: l10n.libraryGroupNone,
          selected: grouping == ImageSetGrouping.none,
          onSelected: () => onSelected(ImageSetGrouping.none),
        ),
        _GroupingRow(
          label: l10n.imageSetFilterGroupByAuthor,
          selected: grouping == ImageSetGrouping.byAuthor,
          onSelected: () => onSelected(ImageSetGrouping.byAuthor),
        ),
      ],
    );
  }
}

class _GroupingRow extends StatelessWidget {
  const _GroupingRow({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return InkWell(
      onTap: onSelected,
      hoverColor: theme.hoverColor,
      splashColor: theme.splashColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _kSectionInset,
          vertical: 8,
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 24,
              height: 24,
              child: RadioGroup<bool>(
                groupValue: selected,
                onChanged: (_) => onSelected(),
                child: Radio<bool>(value: true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          ],
        ),
      ),
    );
  }
}

class _ImageSetSortRow extends StatelessWidget {
  const _ImageSetSortRow({
    required this.field,
    required this.sort,
    required this.onTap,
  });

  final ImageSetSortField field;
  final ImageSetSortOption sort;
  final VoidCallback onTap;

  String _label(AppLocalizations l10n) => switch (field) {
    ImageSetSortField.name => l10n.imageSetFilterSortName,
    ImageSetSortField.imageCount => l10n.imageSetFilterSortImageCount,
    ImageSetSortField.createdAt => l10n.imageSetFilterSortCreatedAt,
    ImageSetSortField.relativePath => l10n.imageSetFilterSortRelativePath,
  };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final bool isSelected = sort.field == field;
    final bool isAscending = !sort.descending;
    return InkWell(
      onTap: onTap,
      hoverColor: theme.hoverColor,
      splashColor: theme.splashColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _kSectionInset,
          vertical: 8,
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: _kSortIconSlotWidth,
              child: isSelected
                  ? Icon(
                      isAscending
                          ? LucideIcons.chevronUp
                          : LucideIcons.chevronDown,
                      size: 14,
                      color: cs.primary,
                    )
                  : null,
            ),
            const SizedBox(width: _kSortIconLabelGap),
            Expanded(
              child: Text(
                _label(context.l10n),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
