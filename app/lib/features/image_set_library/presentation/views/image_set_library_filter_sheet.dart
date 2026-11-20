import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_catalog_query.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_browse_providers.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

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
    final String title = l10n.imageSetFilterSortTitle;
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
  late ImageSetBrowsePreferences _draft;
  late TextEditingController _authors;
  late TextEditingController _tags;
  late TextEditingController _parodies;
  late TextEditingController _characters;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _draft = ImageSetBrowsePreferences.defaults;
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
    setState(() {
      _draft = loaded;
      _authors.text = loaded.authors.any.join(', ');
      _tags.text = loaded.tags.any.join(', ');
      _parodies.text = loaded.parodies.any.join(', ');
      _characters.text = loaded.characters.any.join(', ');
      _ready = true;
    });
  }

  @override
  void dispose() {
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

  ImageSetBrowsePreferences _compose() => _draft.copyWith(
    authors: ImageSetFacetFilter(
      any: _parseNames(_authors.text),
      unassigned: _draft.authors.unassigned,
    ),
    tags: ImageSetFacetFilter(
      any: _parseNames(_tags.text),
      unassigned: _draft.tags.unassigned,
    ),
    parodies: ImageSetFacetFilter(
      any: _parseNames(_parodies.text),
      unassigned: _draft.parodies.unassigned,
    ),
    characters: ImageSetFacetFilter(
      any: _parseNames(_characters.text),
      unassigned: _draft.characters.unassigned,
    ),
  );

  Future<void> _apply() async {
    final ImageSetBrowsePreferences next = _compose();
    await ref.read(imageSetBrowsePreferencesProvider.notifier).replace(next);
    ref
        .read(imageSetCatalogPageIndexProvider.notifier)
        .setPage(widget.libraryId, 1);
    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _reset() async {
    await ref.read(imageSetBrowsePreferencesProvider.notifier).reset();
    ref
        .read(imageSetCatalogPageIndexProvider.notifier)
        .setPage(widget.libraryId, 1);
    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    if (!_ready) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Padding(
      padding: EdgeInsets.all(theme.spacing.md),
      child: Column(
        key: const ValueKey<String>('imageSetFilterSortBody'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.imageSetFilterRequireImages),
            value: _draft.requireImages,
            onChanged: (bool value) =>
                setState(() => _draft = _draft.copyWith(requireImages: value)),
          ),
          Text(l10n.imageSetFilterCarrierShape, style: theme.typeScale.titleSmall),
          SizedBox(height: theme.spacing.xs),
          SegmentedButton<ImageSetCarrierShape?>(
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
            selected: <ImageSetCarrierShape?>{_draft.carrierShape},
            onSelectionChanged: (Set<ImageSetCarrierShape?> next) {
              final ImageSetCarrierShape? shape = next.first;
              setState(() {
                _draft = shape == null
                    ? _draft.copyWith(clearCarrierShape: true)
                    : _draft.copyWith(carrierShape: shape);
              });
            },
          ),
          SizedBox(height: theme.spacing.md),
          Text(l10n.imageSetFilterSortField, style: theme.typeScale.titleSmall),
          DropdownButton<ImageSetSortField>(
            isExpanded: true,
            value: _draft.sort.field,
            items: <DropdownMenuItem<ImageSetSortField>>[
              DropdownMenuItem(
                value: ImageSetSortField.name,
                child: Text(l10n.imageSetFilterSortName),
              ),
              DropdownMenuItem(
                value: ImageSetSortField.imageCount,
                child: Text(l10n.imageSetFilterSortImageCount),
              ),
              DropdownMenuItem(
                value: ImageSetSortField.createdAt,
                child: Text(l10n.imageSetFilterSortCreatedAt),
              ),
              DropdownMenuItem(
                value: ImageSetSortField.relativePath,
                child: Text(l10n.imageSetFilterSortRelativePath),
              ),
            ],
            onChanged: (ImageSetSortField? field) {
              if (field == null) {
                return;
              }
              setState(
                () => _draft = _draft.copyWith(
                  sort: _draft.sort.copyWith(field: field),
                ),
              );
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.imageSetFilterSortDescending),
            value: _draft.sort.descending,
            onChanged: (bool value) => setState(
              () => _draft = _draft.copyWith(
                sort: _draft.sort.copyWith(descending: value),
              ),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.imageSetFilterGroupByAuthor),
            value: _draft.grouping == ImageSetGrouping.byAuthor,
            onChanged: (bool value) => setState(
              () => _draft = _draft.copyWith(
                grouping: value
                    ? ImageSetGrouping.byAuthor
                    : ImageSetGrouping.none,
              ),
            ),
          ),
          SizedBox(height: theme.spacing.md),
          _FacetField(
            label: l10n.imageSetFilterAuthors,
            controller: _authors,
            unassignedLabel: l10n.imageSetFilterAuthorsUnassigned,
            unassigned: _draft.authors.unassigned,
            onUnassignedChanged: (bool value) => setState(
              () => _draft = _draft.copyWith(
                authors: _draft.authors.copyWith(unassigned: value),
              ),
            ),
          ),
          _FacetField(
            label: l10n.imageSetFilterTags,
            controller: _tags,
            unassignedLabel: l10n.imageSetFilterTagsUnassigned,
            unassigned: _draft.tags.unassigned,
            onUnassignedChanged: (bool value) => setState(
              () => _draft = _draft.copyWith(
                tags: _draft.tags.copyWith(unassigned: value),
              ),
            ),
          ),
          _FacetField(
            label: l10n.imageSetFilterParodies,
            controller: _parodies,
            unassignedLabel: l10n.imageSetFilterParodiesUnassigned,
            unassigned: _draft.parodies.unassigned,
            onUnassignedChanged: (bool value) => setState(
              () => _draft = _draft.copyWith(
                parodies: _draft.parodies.copyWith(unassigned: value),
              ),
            ),
          ),
          _FacetField(
            label: l10n.imageSetFilterCharacters,
            controller: _characters,
            unassignedLabel: l10n.imageSetFilterCharactersUnassigned,
            unassigned: _draft.characters.unassigned,
            onUnassignedChanged: (bool value) => setState(
              () => _draft = _draft.copyWith(
                characters: _draft.characters.copyWith(unassigned: value),
              ),
            ),
          ),
          SizedBox(height: theme.spacing.lg),
          Row(
            children: <Widget>[
              TextButton(onPressed: _reset, child: Text(l10n.imageSetFilterReset)),
              const Spacer(),
              FilledButton(
                key: const ValueKey<String>('imageSetFilterApply'),
                onPressed: _apply,
                child: Text(l10n.imageSetFilterApply),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FacetField extends StatelessWidget {
  const _FacetField({
    required this.label,
    required this.controller,
    required this.unassignedLabel,
    required this.unassigned,
    required this.onUnassignedChanged,
  });

  final String label;
  final TextEditingController controller;
  final String unassignedLabel;
  final bool unassigned;
  final ValueChanged<bool> onUnassignedChanged;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: theme.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            controller: controller,
            decoration: InputDecoration(labelText: label),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(unassignedLabel),
            value: unassigned,
            onChanged: (bool? value) => onUnassignedChanged(value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }
}
