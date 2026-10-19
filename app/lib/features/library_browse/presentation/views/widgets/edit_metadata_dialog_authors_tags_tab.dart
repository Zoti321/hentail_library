part of 'edit_metadata_dialog.dart';

class _EditMetadataAuthorsTagsTab extends ConsumerWidget {
  const _EditMetadataAuthorsTagsTab({
    required this.scope,
    required this.authors,
    required this.tags,
    required this.parodies,
    required this.characters,
    required this.locks,
    required this.lockBusy,
    required this.onAddAuthor,
    required this.onRemoveAuthor,
    required this.onAddTag,
    required this.onRemoveTag,
    required this.onAddParody,
    required this.onRemoveParody,
    required this.onAddCharacter,
    required this.onRemoveCharacter,
    required this.onLockChanged,
  });

  final ComicMetadataSmartFacetScope scope;
  final List<Author> authors;
  final List<Tag> tags;
  final List<String> parodies;
  final List<String> characters;
  final ComicMetaLocks locks;
  final bool lockBusy;
  final ValueChanged<String> onAddAuthor;
  final ValueChanged<String> onRemoveAuthor;
  final ValueChanged<String> onAddTag;
  final ValueChanged<String> onRemoveTag;
  final ValueChanged<String> onAddParody;
  final ValueChanged<String> onRemoveParody;
  final ValueChanged<String> onAddCharacter;
  final ValueChanged<String> onRemoveCharacter;
  final _MetaLockChanged onLockChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final AppThemeTokens tokens = context.tokens;
    final bool smartMatchEnabled =
        ref.watch(smartFacetMatchPreferenceProvider).asData?.value ??
        SmartFacetMatchPreference.defaultValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.lg,
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                ref
                    .read(smartFacetMatchPreferenceProvider.notifier)
                    .setEnabled(!smartMatchEnabled);
              },
              borderRadius: BorderRadius.circular(tokens.radius.sm),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.spacing.sm,
                  vertical: tokens.spacing.xs,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      l10n.smartFacetMatchToggleLabel,
                      style: TextStyle(
                        fontSize: tokens.text.bodySm,
                        fontWeight: FontWeight.w500,
                        color: context.hentai.textPrimary,
                      ),
                    ),
                    SizedBox(width: tokens.spacing.sm),
                    IgnorePointer(
                      child: ToggleSwitch(checked: smartMatchEnabled),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        AuthorLibraryMultiSelectField(
          label: l10n.comicDetailAuthors,
          labelTrailing: MetadataLockButton(
            locked: locks.authors,
            enabled: !lockBusy,
            onChanged: (bool locked) => onLockChanged(authors: locked),
          ),
          icon: LucideIcons.penTool,
          selectedNames: authors.map((Author a) => a.name).toList(),
          onAdd: onAddAuthor,
          onRemove: onRemoveAuthor,
          scope: scope,
        ),
        TagLibraryMultiSelectField(
          label: l10n.comicDetailTags,
          labelTrailing: MetadataLockButton(
            locked: locks.tags,
            enabled: !lockBusy,
            onChanged: (bool locked) => onLockChanged(tags: locked),
          ),
          icon: LucideIcons.tag,
          selectedNames: tags.map((Tag t) => t.name).toList(),
          onAdd: onAddTag,
          onRemove: onRemoveTag,
          scope: scope,
        ),
        ParodyLibraryMultiSelectField(
          label: l10n.comicDetailParodies,
          labelTrailing: MetadataLockButton(
            locked: locks.parodies,
            enabled: !lockBusy,
            onChanged: (bool locked) => onLockChanged(parodies: locked),
          ),
          icon: LucideIcons.bookMarked,
          selectedNames: parodies,
          onAdd: onAddParody,
          onRemove: onRemoveParody,
          scope: scope,
        ),
        CharacterLibraryMultiSelectField(
          label: l10n.comicDetailCharacters,
          labelTrailing: MetadataLockButton(
            locked: locks.characters,
            enabled: !lockBusy,
            onChanged: (bool locked) => onLockChanged(characters: locked),
          ),
          icon: LucideIcons.userRound,
          selectedNames: characters,
          onAdd: onAddCharacter,
          onRemove: onRemoveCharacter,
          scope: scope,
        ),
      ],
    );
  }
}
