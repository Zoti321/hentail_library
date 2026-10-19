part of 'bulk_edit_metadata_dialog.dart';

class _BulkEditFieldList extends StatelessWidget {
  const _BulkEditFieldList({
    required this.fields,
    required this.selectedField,
    required this.labelFor,
    required this.isDirty,
    required this.isMixed,
    required this.summaryFor,
    required this.mixedLabel,
    required this.onSelect,
  });

  final List<BulkMetadataEditFieldKind> fields;
  final BulkMetadataEditFieldKind? selectedField;
  final String Function(BulkMetadataEditFieldKind kind) labelFor;
  final bool Function(BulkMetadataEditFieldKind kind) isDirty;
  final bool Function(BulkMetadataEditFieldKind kind) isMixed;
  final String? Function(BulkMetadataEditFieldKind kind) summaryFor;
  final String mixedLabel;
  final ValueChanged<BulkMetadataEditFieldKind> onSelect;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: tokens.spacing.xs,
      children: fields
          .map(
            (BulkMetadataEditFieldKind kind) => _BulkEditFieldListRow(
              label: labelFor(kind),
              dirty: isDirty(kind),
              selected: selectedField == kind,
              mixed: isMixed(kind),
              summary: summaryFor(kind),
              mixedLabel: mixedLabel,
              onSelect: () => onSelect(kind),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _BulkEditFieldListRow extends StatelessWidget {
  const _BulkEditFieldListRow({
    required this.label,
    required this.dirty,
    required this.selected,
    required this.mixed,
    required this.summary,
    required this.mixedLabel,
    required this.onSelect,
  });

  final String label;
  final bool dirty;
  final bool selected;
  final bool mixed;
  final String? summary;
  final String mixedLabel;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color? background = selected
        ? cs.primary.withAlpha(20)
        : dirty
        ? context.hentai.hoverBackground.withAlpha(80)
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(tokens.radius.sm),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(tokens.radius.sm),
            border: Border(
              left: BorderSide(
                color: selected ? cs.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spacing.sm,
              vertical: tokens.spacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spacing.xs,
              children: <Widget>[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: tokens.text.bodySm,
                    fontWeight: FontWeight.w600,
                    color: context.hentai.textPrimary,
                  ),
                ),
                if (summary != null || mixed)
                  Row(
                    children: <Widget>[
                      if (summary != null)
                        Flexible(
                          child: Text(
                            summary!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: tokens.text.labelXs,
                              color: context.hentai.textSecondary,
                            ),
                          ),
                        ),
                      if (mixed) ...<Widget>[
                        if (summary != null) SizedBox(width: tokens.spacing.xs),
                        Text(
                          mixedLabel,
                          style: TextStyle(
                            fontSize: tokens.text.labelXs,
                            color: context.hentai.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BulkEditFieldDetail extends StatelessWidget {
  const _BulkEditFieldDetail({
    required this.selectedField,
    required this.selectHint,
    required this.child,
  });

  final BulkMetadataEditFieldKind? selectedField;
  final String selectHint;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (selectedField == null || child == null) {
      return _BulkEditDetailPlaceholder(message: selectHint);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: context.tokens.spacing.md,
      children: <Widget>[child!],
    );
  }
}

class _BulkEditDetailPlaceholder extends StatelessWidget {
  const _BulkEditDetailPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(tokens.spacing.xl),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: tokens.text.bodySm,
            color: context.hentai.textTertiary,
          ),
        ),
      ),
    );
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

class _BulkMultiValueFieldDetail extends StatelessWidget {
  const _BulkMultiValueFieldDetail({
    required this.state,
    required this.opLabels,
    required this.child,
    required this.onChanged,
  });

  final BulkMetadataEditMultiValueFieldState state;
  final Map<ComicMetadataBulkMultiValueOp, String> opLabels;
  final Widget child;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: context.tokens.spacing.sm,
      children: <Widget>[
        _BulkEditOperationSelector(
          label: context.l10n.bulkEditMetadataOperationLabel,
          items: ComicMetadataBulkMultiValueOp.values
              .map(
                (ComicMetadataBulkMultiValueOp op) =>
                    CapsuleTabItem(label: opLabels[op] ?? op.name),
              )
              .toList(growable: false),
          selectedIndex: ComicMetadataBulkMultiValueOp.values.indexOf(state.op),
          onSelected: (int index) {
            state.op = ComicMetadataBulkMultiValueOp.values[index];
            onChanged();
          },
        ),
        child,
      ],
    );
  }
}

class _BulkScalarFieldDetail extends StatelessWidget {
  const _BulkScalarFieldDetail({
    required this.state,
    required this.opLabels,
    required this.child,
    required this.onChanged,
  });

  final BulkMetadataEditScalarFieldState state;
  final Map<ComicMetadataBulkScalarOp, String> opLabels;
  final Widget child;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: context.tokens.spacing.sm,
      children: <Widget>[
        _BulkEditOperationSelector(
          label: context.l10n.bulkEditMetadataOperationLabel,
          items: ComicMetadataBulkScalarOp.values
              .map(
                (ComicMetadataBulkScalarOp op) =>
                    CapsuleTabItem(label: opLabels[op] ?? op.name),
              )
              .toList(growable: false),
          selectedIndex: ComicMetadataBulkScalarOp.values.indexOf(state.op),
          onSelected: (int index) {
            state.op = ComicMetadataBulkScalarOp.values[index];
            onChanged();
          },
        ),
        child,
      ],
    );
  }
}

class _BulkContentRatingFieldDetail extends StatelessWidget {
  const _BulkContentRatingFieldDetail({
    required this.label,
    required this.state,
    required this.allAgesLabel,
    required this.onChanged,
  });

  final String label;
  final BulkMetadataEditContentRatingFieldState state;
  final String allAgesLabel;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return FluentToggleField(
      labelText: label,
      value: state.isR18,
      onChanged: (bool value) {
        state.isR18 = value;
        onChanged();
      },
      checkedLabel: 'R18',
      uncheckedLabel: allAgesLabel,
    );
  }
}

class _BulkEditOperationSelector extends StatelessWidget {
  const _BulkEditOperationSelector({
    required this.label,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final String label;
  final List<CapsuleTabItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.xs,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            fontSize: tokens.text.bodySm,
            fontWeight: FontWeight.w500,
            color: context.hentai.textPrimary,
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: CapsuleTabBar(
            items: items,
            selectedIndex: selectedIndex,
            onSelected: onSelected,
          ),
        ),
      ],
    );
  }
}
