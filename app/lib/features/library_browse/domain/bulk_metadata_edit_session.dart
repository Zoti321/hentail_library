import 'package:hentai_library/shared/domain/library/comic_metadata_bulk_patch_types.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';

enum BulkMetadataEditFieldKind {
  description,
  publishedAt,
  contentRating,
  languages,
  authors,
  tags,
  parodies,
  characters,
}

class BulkMetadataEditMultiValueFieldState {
  ComicMetadataBulkMultiValueOp op = ComicMetadataBulkMultiValueOp.add;
  List<String> values = const <String>[];
  bool mixedValues = false;
}

class BulkMetadataEditScalarFieldState {
  ComicMetadataBulkScalarOp op = ComicMetadataBulkScalarOp.replace;
  bool mixedValues = false;
  String description = '';
  DateTime? publishedAt;
}

class BulkMetadataEditContentRatingFieldState {
  bool isR18 = false;
  bool mixedValues = false;
}

/// Draft state for Comic metadata bulk patch; merge semantics remain in Rust core.
class BulkMetadataEditSession {
  BulkMetadataEditSession();

  final Map<BulkMetadataEditFieldKind, BulkMetadataEditMultiValueFieldState>
  multiFields = <BulkMetadataEditFieldKind, BulkMetadataEditMultiValueFieldState>{
    for (final BulkMetadataEditFieldKind kind in <BulkMetadataEditFieldKind>[
      BulkMetadataEditFieldKind.tags,
      BulkMetadataEditFieldKind.authors,
      BulkMetadataEditFieldKind.languages,
      BulkMetadataEditFieldKind.parodies,
      BulkMetadataEditFieldKind.characters,
    ])
      kind: BulkMetadataEditMultiValueFieldState(),
  };

  final BulkMetadataEditScalarFieldState descriptionField =
      BulkMetadataEditScalarFieldState();
  final BulkMetadataEditScalarFieldState publishedAtField =
      BulkMetadataEditScalarFieldState();
  final BulkMetadataEditContentRatingFieldState contentRatingField =
      BulkMetadataEditContentRatingFieldState();

  final Set<BulkMetadataEditFieldKind> dirtyFields =
      <BulkMetadataEditFieldKind>{};

  void applyMixedHintsFromComics(List<Comic> comics) {
    multiFields[BulkMetadataEditFieldKind.tags]!.mixedValues = _isMixed(
      comics.map((Comic c) => c.tags.map((t) => t.name).toList()),
    );
    multiFields[BulkMetadataEditFieldKind.authors]!.mixedValues = _isMixed(
      comics.map((Comic c) => c.authors.map((a) => a.name).toList()),
    );
    multiFields[BulkMetadataEditFieldKind.languages]!.mixedValues = _isMixed(
      comics.map((Comic c) => List<String>.from(c.languages)),
    );
    multiFields[BulkMetadataEditFieldKind.parodies]!.mixedValues = _isMixed(
      comics.map((Comic c) => List<String>.from(c.parodies)),
    );
    multiFields[BulkMetadataEditFieldKind.characters]!.mixedValues = _isMixed(
      comics.map((Comic c) => List<String>.from(c.characters)),
    );
    contentRatingField.mixedValues = _isMixed(
      comics.map(
        (Comic c) => <String>[
          c.contentRating == ContentRating.r18 ? 'r18' : 'safe',
        ],
      ),
    );
    descriptionField.mixedValues = _isMixed(
      comics.map((Comic c) => <String>[c.description ?? '']),
    );
    publishedAtField.mixedValues = _isMixed(
      comics.map(
        (Comic c) => <String>[
          c.publishedAt?.millisecondsSinceEpoch.toString() ?? '',
        ],
      ),
    );
  }

  void markDirty(BulkMetadataEditFieldKind kind) {
    dirtyFields.add(kind);
  }

  bool isFieldDirty(BulkMetadataEditFieldKind kind) => dirtyFields.contains(kind);

  ComicMetadataBulkPatch? buildPatch() {
    if (dirtyFields.isEmpty) {
      return null;
    }
    final BulkMetadataEditMultiValueFieldState tags =
        multiFields[BulkMetadataEditFieldKind.tags]!;
    final BulkMetadataEditMultiValueFieldState authors =
        multiFields[BulkMetadataEditFieldKind.authors]!;
    final BulkMetadataEditMultiValueFieldState languages =
        multiFields[BulkMetadataEditFieldKind.languages]!;
    final BulkMetadataEditMultiValueFieldState parodies =
        multiFields[BulkMetadataEditFieldKind.parodies]!;
    final BulkMetadataEditMultiValueFieldState characters =
        multiFields[BulkMetadataEditFieldKind.characters]!;

    return ComicMetadataBulkPatch(
      tags: dirtyFields.contains(BulkMetadataEditFieldKind.tags)
          ? ComicMetadataBulkMultiValuePatch(op: tags.op, values: tags.values)
          : null,
      authors: dirtyFields.contains(BulkMetadataEditFieldKind.authors)
          ? ComicMetadataBulkMultiValuePatch(
              op: authors.op,
              values: authors.values,
            )
          : null,
      languages: dirtyFields.contains(BulkMetadataEditFieldKind.languages)
          ? ComicMetadataBulkMultiValuePatch(
              op: languages.op,
              values: languages.values,
            )
          : null,
      parodies: dirtyFields.contains(BulkMetadataEditFieldKind.parodies)
          ? ComicMetadataBulkMultiValuePatch(
              op: parodies.op,
              values: parodies.values,
            )
          : null,
      characters: dirtyFields.contains(BulkMetadataEditFieldKind.characters)
          ? ComicMetadataBulkMultiValuePatch(
              op: characters.op,
              values: characters.values,
            )
          : null,
      contentRating: dirtyFields.contains(BulkMetadataEditFieldKind.contentRating)
          ? (contentRatingField.isR18 ? 'r18' : 'safe')
          : null,
      description: dirtyFields.contains(BulkMetadataEditFieldKind.description)
          ? (descriptionField.op == ComicMetadataBulkScalarOp.clear
                ? const ComicMetadataBulkDescriptionPatch.clear()
                : ComicMetadataBulkDescriptionPatch.replace(
                    descriptionField.description,
                  ))
          : null,
      publishedAt: dirtyFields.contains(BulkMetadataEditFieldKind.publishedAt)
          ? (publishedAtField.op == ComicMetadataBulkScalarOp.clear
                ? const ComicMetadataBulkPublishedAtPatch.clear()
                : ComicMetadataBulkPublishedAtPatch.replace(
                    publishedAtField.publishedAt?.millisecondsSinceEpoch ?? 0,
                  ))
          : null,
    );
  }

  static bool _isMixed(Iterable<List<String>> lists) {
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

  static bool _listEquals(List<String> a, List<String> b) {
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
}
