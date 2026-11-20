import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_facets.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_facets_patch.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_named_facet_kind.dart';
import 'package:hentai_library/features/image_set_library/presentation/patterns/metadata_edit/image_set_metadata_edit_draft.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_library_providers.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_facet_multi_select_field.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/application/errors/error_message.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Image set 元数据编辑表（名称、名称锁、四类 facet 绑定）。
class ImageSetMetadataEditSheet extends ConsumerStatefulWidget {
  const ImageSetMetadataEditSheet({
    super.key,
    required this.imageSet,
    required this.initialFacets,
  });

  final ImageSet imageSet;
  final ImageSetFacets initialFacets;

  @override
  ConsumerState<ImageSetMetadataEditSheet> createState() =>
      _ImageSetMetadataEditSheetState();
}

class _ImageSetMetadataEditSheetState
    extends ConsumerState<ImageSetMetadataEditSheet> {
  late ImageSetMetadataEditDraft _draft;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _draft = ImageSetMetadataEditDraft.from(
      imageSet: widget.imageSet,
      facets: widget.initialFacets,
    );
  }

  bool get _nameChanged => _draft.name.trim() != widget.imageSet.name;

  bool get _lockChanged => _draft.nameLocked != widget.imageSet.nameLocked;

  bool get _facetsChanged {
    final ImageSetFacets baseline = widget.initialFacets;
    bool listEq(List<String> a, List<String> b) {
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

    return !listEq(_draft.authors, baseline.authors) ||
        !listEq(_draft.tags, baseline.tags) ||
        !listEq(_draft.parodies, baseline.parodies) ||
        !listEq(_draft.characters, baseline.characters);
  }

  bool get _dirty => _nameChanged || _lockChanged || _facetsChanged;

  Future<void> _save() async {
    if (_saving || !_dirty) {
      return;
    }
    final String trimmedName = _draft.name.trim();
    if (trimmedName.isEmpty) {
      return;
    }
    setState(() => _saving = true);
    try {
      if (_nameChanged) {
        await ref.read(imageSetUpdateNameCommandProvider)(
          widget.imageSet.imageSetId,
          trimmedName,
        );
      } else if (_lockChanged) {
        await ref.read(imageSetSetNameLockedCommandProvider)(
          widget.imageSet.imageSetId,
          locked: _draft.nameLocked,
        );
      }
      if (_facetsChanged) {
        await ref.read(imageSetUpdateFacetsCommandProvider)(
          widget.imageSet.imageSetId,
          ImageSetFacetsPatch(
            authors: List<String>.from(_draft.authors),
            tags: List<String>.from(_draft.tags),
            parodies: List<String>.from(_draft.parodies),
            characters: List<String>.from(_draft.characters),
          ),
        );
      }
      if (!mounted) {
        return;
      }
      final bool nameLocked = _nameChanged ? true : _draft.nameLocked;
      Navigator.of(context).pop(
        widget.imageSet.copyWith(name: trimmedName, nameLocked: nameLocked),
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appErrorMessage(error))),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _addFacet(ImageSetNamedFacetKind kind, String name) {
    final List<String> next = switch (kind) {
      ImageSetNamedFacetKind.author => _draft.authors,
      ImageSetNamedFacetKind.tag => _draft.tags,
      ImageSetNamedFacetKind.parody => _draft.parodies,
      ImageSetNamedFacetKind.character => _draft.characters,
    };
    if (next.contains(name)) {
      return;
    }
    setState(() {
      _draft = switch (kind) {
        ImageSetNamedFacetKind.author => _draft.copyWith(
          authors: <String>[...next, name]..sort(),
        ),
        ImageSetNamedFacetKind.tag => _draft.copyWith(
          tags: <String>[...next, name]..sort(),
        ),
        ImageSetNamedFacetKind.parody => _draft.copyWith(
          parodies: <String>[...next, name]..sort(),
        ),
        ImageSetNamedFacetKind.character => _draft.copyWith(
          characters: <String>[...next, name]..sort(),
        ),
      };
    });
  }

  void _removeFacet(ImageSetNamedFacetKind kind, String name) {
    setState(() {
      _draft = switch (kind) {
        ImageSetNamedFacetKind.author => _draft.copyWith(
          authors: _draft.authors.where((String n) => n != name).toList(),
        ),
        ImageSetNamedFacetKind.tag => _draft.copyWith(
          tags: _draft.tags.where((String n) => n != name).toList(),
        ),
        ImageSetNamedFacetKind.parody => _draft.copyWith(
          parodies: _draft.parodies.where((String n) => n != name).toList(),
        ),
        ImageSetNamedFacetKind.character => _draft.copyWith(
          characters: _draft.characters.where((String n) => n != name).toList(),
        ),
      };
    });
  }

  void _clearFacet(ImageSetNamedFacetKind kind) {
    setState(() {
      _draft = switch (kind) {
        ImageSetNamedFacetKind.author => _draft.copyWith(authors: <String>[]),
        ImageSetNamedFacetKind.tag => _draft.copyWith(tags: <String>[]),
        ImageSetNamedFacetKind.parody => _draft.copyWith(parodies: <String>[]),
        ImageSetNamedFacetKind.character => _draft.copyWith(
          characters: <String>[],
        ),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final double gap = theme.spacing.lg;

    return MetadataEditSurface(
      title: l10n.imageSetMetadataEditTitle,
      saving: _saving,
      saveEnabled: _dirty && _draft.name.trim().isNotEmpty,
      onCancel: () => Navigator.of(context).maybePop(),
      onSave: _save,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
            OutlinedTextField(
              label: l10n.imageSetMetadataEditNameLabel,
              initialValue: _draft.name,
              onChanged: (String value) =>
                  setState(() => _draft = _draft.copyWith(name: value)),
            ),
            SizedBox(height: gap),
            Material(
              type: MaterialType.transparency,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.imageSetMetadataEditNameLockLabel),
                subtitle: Text(
                  l10n.imageSetMetadataEditNameLockHint,
                  style: theme.typeScale.bodySmall.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                value: _draft.nameLocked,
                onChanged: (bool value) =>
                    setState(() => _draft = _draft.copyWith(nameLocked: value)),
              ),
            ),
            SizedBox(height: gap),
            ImageSetFacetMultiSelectField(
              kind: ImageSetNamedFacetKind.author,
              label: l10n.comicDetailAuthors,
              selectedNames: _draft.authors,
              onAdd: (String name) =>
                  _addFacet(ImageSetNamedFacetKind.author, name),
              onRemove: (String name) =>
                  _removeFacet(ImageSetNamedFacetKind.author, name),
              onClearAll: () => _clearFacet(ImageSetNamedFacetKind.author),
            ),
            SizedBox(height: gap),
            ImageSetFacetMultiSelectField(
              kind: ImageSetNamedFacetKind.tag,
              label: l10n.metadataTabTags,
              selectedNames: _draft.tags,
              onAdd: (String name) => _addFacet(ImageSetNamedFacetKind.tag, name),
              onRemove: (String name) =>
                  _removeFacet(ImageSetNamedFacetKind.tag, name),
              onClearAll: () => _clearFacet(ImageSetNamedFacetKind.tag),
            ),
            SizedBox(height: gap),
            ImageSetFacetMultiSelectField(
              kind: ImageSetNamedFacetKind.parody,
              label: l10n.metadataTabParodies,
              selectedNames: _draft.parodies,
              onAdd: (String name) =>
                  _addFacet(ImageSetNamedFacetKind.parody, name),
              onRemove: (String name) =>
                  _removeFacet(ImageSetNamedFacetKind.parody, name),
              onClearAll: () => _clearFacet(ImageSetNamedFacetKind.parody),
            ),
            SizedBox(height: gap),
            ImageSetFacetMultiSelectField(
              kind: ImageSetNamedFacetKind.character,
              label: l10n.metadataTabCharacters,
              selectedNames: _draft.characters,
              onAdd: (String name) =>
                  _addFacet(ImageSetNamedFacetKind.character, name),
              onRemove: (String name) =>
                  _removeFacet(ImageSetNamedFacetKind.character, name),
              onClearAll: () => _clearFacet(ImageSetNamedFacetKind.character),
            ),
        ],
      ),
    );
  }
}

Future<ImageSet?> showImageSetMetadataEditSheet({
  required BuildContext context,
  required ImageSet imageSet,
  required ImageSetFacets initialFacets,
}) {
  return Navigator.of(context).push<ImageSet>(
    MaterialPageRoute<ImageSet>(
      fullscreenDialog: true,
      builder: (BuildContext context) => ImageSetMetadataEditSheet(
        imageSet: imageSet,
        initialFacets: initialFacets,
      ),
    ),
  );
}