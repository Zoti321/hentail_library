part of 'edit_metadata_dialog.dart';

typedef _MetaLockChanged =
    Future<void> Function({
      bool? title,
      bool? description,
      bool? publishedAt,
      bool? contentRating,
      bool? authors,
      bool? tags,
      bool? languages,
      bool? parodies,
      bool? characters,
    });

class _EditMetadataGeneralTab extends StatelessWidget {
  const _EditMetadataGeneralTab({
    required this.title,
    required this.titleError,
    required this.description,
    required this.publishedAt,
    required this.isR18,
    required this.languages,
    required this.locks,
    required this.lockBusy,
    required this.showSeriesSort,
    required this.sortOrderText,
    required this.sortOrderLocked,
    required this.sortOrderError,
    required this.onTitleChanged,
    required this.onDescriptionChanged,
    required this.onPublishedAtChanged,
    required this.onIsR18Changed,
    required this.onAddLanguage,
    required this.onRemoveLanguage,
    required this.onSortOrderChanged,
    required this.onSortOrderLockedChanged,
    required this.onLockChanged,
  });

  final String title;
  final String? titleError;
  final String description;
  final DateTime? publishedAt;
  final bool isR18;
  final List<String> languages;
  final ComicMetaLocks locks;
  final bool lockBusy;
  final bool showSeriesSort;
  final String sortOrderText;
  final bool sortOrderLocked;
  final String? sortOrderError;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onDescriptionChanged;
  final ValueChanged<DateTime?> onPublishedAtChanged;
  final ValueChanged<bool> onIsR18Changed;
  final ValueChanged<String> onAddLanguage;
  final ValueChanged<String> onRemoveLanguage;
  final ValueChanged<String> onSortOrderChanged;
  final ValueChanged<bool> onSortOrderLockedChanged;
  final _MetaLockChanged onLockChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool compact = AppLayoutBreakpoints.isCompact(
      MediaQuery.sizeOf(context).width,
    );

    final Widget publishedAtField = FluentDatePickerField(
      labelText: l10n.formPublishedDateLabel,
      labelTrailing: MetadataLockButton(
        locked: locks.publishedAt,
        enabled: !lockBusy,
        onChanged: (bool locked) => onLockChanged(publishedAt: locked),
      ),
      value: publishedAt,
      onChanged: onPublishedAtChanged,
    );
    final Widget contentRatingField = FluentToggleField(
      labelText: l10n.formAgeRestrictionLabel,
      labelTrailing: MetadataLockButton(
        locked: locks.contentRating,
        enabled: !lockBusy,
        onChanged: (bool locked) => onLockChanged(contentRating: locked),
      ),
      value: isR18,
      onChanged: onIsR18Changed,
      checkedLabel: 'R18',
      uncheckedLabel: l10n.filterAgeAllAges,
    );

    final List<String> languageChoices = <String>[
      ...ComicLanguageNames.closedSet,
      ...languages.where(
        (String name) => !ComicLanguageNames.closedSet.contains(name),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.lg,
      children: <Widget>[
        FluentTextField(
          labelText: l10n.formComicTitleLabel,
          labelTrailing: MetadataLockButton(
            locked: locks.title,
            enabled: !lockBusy,
            onChanged: (bool locked) => onLockChanged(title: locked),
          ),
          initialValue: title,
          errorText: titleError,
          onChanged: onTitleChanged,
          hintText: l10n.formComicTitleHint,
        ),
        FluentTextField(
          labelText: l10n.formComicDescriptionLabel,
          labelTrailing: MetadataLockButton(
            locked: locks.description,
            enabled: !lockBusy,
            onChanged: (bool locked) => onLockChanged(description: locked),
          ),
          initialValue: description,
          maxLines: 4,
          onChanged: onDescriptionChanged,
          hintText: l10n.formComicDescriptionHint,
        ),
        if (compact)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: tokens.spacing.lg,
            children: <Widget>[publishedAtField, contentRatingField],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: tokens.spacing.md,
            children: <Widget>[
              Expanded(flex: 3, child: publishedAtField),
              Expanded(flex: 2, child: contentRatingField),
            ],
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: tokens.spacing.sm,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    l10n.formLanguagesLabel,
                    style: TextStyle(
                      fontSize: tokens.text.bodySm,
                      color: context.hentai.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                MetadataLockButton(
                  locked: locks.languages,
                  enabled: !lockBusy,
                  onChanged: (bool locked) => onLockChanged(languages: locked),
                ),
              ],
            ),
            Wrap(
              spacing: tokens.spacing.sm,
              runSpacing: tokens.spacing.sm,
              children: languageChoices.map((String canonical) {
                final bool selected = languages.contains(canonical);
                return OutlinedMetaChip(
                  text: l10n.comicLanguageLabel(canonical),
                  compact: true,
                  borderColor: selected ? cs.primary : null,
                  textColor: selected ? cs.primary : null,
                  onTap: () {
                    if (selected) {
                      onRemoveLanguage(canonical);
                    } else {
                      onAddLanguage(canonical);
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
        if (showSeriesSort)
          FluentNumberStepperField(
            initialValue: sortOrderText,
            labelText: l10n.formSeriesItemSortOrderLabel,
            labelTrailing: MetadataLockButton(
              locked: sortOrderLocked,
              enabled: !lockBusy,
              onChanged: onSortOrderLockedChanged,
            ),
            errorText: sortOrderError,
            hintText: l10n.formSeriesItemSortOrderHint,
            isDense: true,
            onChanged: onSortOrderChanged,
          ),
      ],
    );
  }
}

String _formatSortOrder(double value) {
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toString();
}
