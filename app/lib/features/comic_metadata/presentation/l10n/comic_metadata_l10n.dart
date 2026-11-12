import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/features/comic_metadata/domain/managed_named_facet_kind.dart';

/// comic_metadata 领域枚举 → 展示文案（owner extension；ARB 源仍在 `core/l10n`）。
extension ComicMetadataL10nX on AppLocalizations {
  String managedNamedFacetCountLabel(ManagedNamedFacetKind kind, int count) {
    return switch (kind) {
      ManagedNamedFacetKind.author => metadataAuthorCount(count),
      ManagedNamedFacetKind.tag => metadataTagCount(count),
      ManagedNamedFacetKind.parody => metadataParodyCount(count),
      ManagedNamedFacetKind.character => metadataCharacterCount(count),
    };
  }

  String metadataTabLabel(ManagedNamedFacetKind kind) {
    return switch (kind) {
      ManagedNamedFacetKind.author => metadataTabAuthors,
      ManagedNamedFacetKind.tag => metadataTabTags,
      ManagedNamedFacetKind.parody => metadataTabParodies,
      ManagedNamedFacetKind.character => metadataTabCharacters,
    };
  }

  String metadataAddLabel(ManagedNamedFacetKind kind) {
    return switch (kind) {
      ManagedNamedFacetKind.author => metadataAddAuthor,
      ManagedNamedFacetKind.tag => metadataAddTag,
      ManagedNamedFacetKind.parody => metadataAddParody,
      ManagedNamedFacetKind.character => metadataAddCharacter,
    };
  }

  String metadataRenameTitle(ManagedNamedFacetKind kind) {
    return switch (kind) {
      ManagedNamedFacetKind.author => metadataRenameAuthor,
      ManagedNamedFacetKind.tag => metadataRenameTag,
      ManagedNamedFacetKind.parody => metadataRenameParody,
      ManagedNamedFacetKind.character => metadataRenameCharacter,
    };
  }

  String metadataAddHint(ManagedNamedFacetKind kind) {
    return switch (kind) {
      ManagedNamedFacetKind.author => metadataAddAuthorHint,
      ManagedNamedFacetKind.tag => metadataAddTagHint,
      ManagedNamedFacetKind.parody => metadataAddParodyHint,
      ManagedNamedFacetKind.character => metadataAddCharacterHint,
    };
  }

  String metadataEmptyTitle(ManagedNamedFacetKind kind) {
    return switch (kind) {
      ManagedNamedFacetKind.author => metadataAuthorsEmptyTitle,
      ManagedNamedFacetKind.tag => metadataTagsEmptyTitle,
      ManagedNamedFacetKind.parody => metadataParodiesEmptyTitle,
      ManagedNamedFacetKind.character => metadataCharactersEmptyTitle,
    };
  }

  String metadataEmptyHint(ManagedNamedFacetKind kind) {
    return switch (kind) {
      ManagedNamedFacetKind.author => metadataAuthorsEmptyHint,
      ManagedNamedFacetKind.tag => metadataTagsEmptyHint,
      ManagedNamedFacetKind.parody => metadataParodiesEmptyHint,
      ManagedNamedFacetKind.character => metadataCharactersEmptyHint,
    };
  }

  String metadataNoMatchTitle(ManagedNamedFacetKind kind) {
    return switch (kind) {
      ManagedNamedFacetKind.author => metadataAuthorsNoMatchTitle,
      ManagedNamedFacetKind.tag => metadataTagsNoMatchTitle,
      ManagedNamedFacetKind.parody => metadataParodiesNoMatchTitle,
      ManagedNamedFacetKind.character => metadataCharactersNoMatchTitle,
    };
  }

  String metadataDeletedToast(ManagedNamedFacetKind kind) {
    return switch (kind) {
      ManagedNamedFacetKind.author => metadataAuthorDeletedToast,
      ManagedNamedFacetKind.tag => metadataTagDeletedToast,
      ManagedNamedFacetKind.parody => metadataParodyDeletedToast,
      ManagedNamedFacetKind.character => metadataCharacterDeletedToast,
    };
  }
}
