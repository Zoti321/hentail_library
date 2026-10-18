part of 'multi_select.dart';

class _MultiSelectMenuPanel<T> extends ConsumerWidget {
  const _MultiSelectMenuPanel({
    super.key,
    required this.width,
    required this.itemsProvider,
    required this.selectedNames,
    required this.filterQuery,
    required this.scrollController,
    required this.highlightedIndexListenable,
    required this.highlightedRowKey,
    required this.onVisibleRemainingChanged,
    required this.onHighlightIndex,
    required this.onAdd,
    required this.onRetry,
    required this.resolveName,
    required this.copy,
    this.resolveSmartMatched,
    this.smartMatchedTooltip,
  });

  final double width;
  final ProviderListenable<AsyncValue<List<T>>> itemsProvider;
  final List<String> selectedNames;
  final String filterQuery;
  final ScrollController scrollController;
  final ValueListenable<int?> highlightedIndexListenable;
  final GlobalKey highlightedRowKey;
  final ValueChanged<List<String>> onVisibleRemainingChanged;
  final void Function(int index, {bool scrollIntoView}) onHighlightIndex;
  final ValueChanged<String> onAdd;
  final VoidCallback onRetry;
  final String Function(T item) resolveName;
  final MultiSelectCopy copy;
  final bool Function(T item)? resolveSmartMatched;
  final String? smartMatchedTooltip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final AsyncValue<List<T>> asyncItems = ref.watch(itemsProvider);
    return asyncItems.when(
      loading: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onVisibleRemainingChanged(const <String>[]);
        });
        return _MultiSelectMenuSizedShell(
          width: width,
          maxHeight: 108,
          child: const Center(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        );
      },
      error: (Object err, StackTrace? st) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onVisibleRemainingChanged(const <String>[]);
        });
        return _MultiSelectMenuSizedShell(
          width: width,
          maxHeight: 148,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.commonLoadFailed,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.hentai.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
              ],
            ),
          ),
        );
      },
      data: (List<T> items) {
        final Set<String> selected = selectedNames.toSet();
        final List<T> remaining = items
            .where((T item) => !selected.contains(resolveName(item)))
            .where(
              (T item) => nameMatchesPinyinAssistedFilter(
                resolveName(item),
                filterQuery,
              ),
            )
            .toList();
        final List<String> remainingNames = remaining
            .map(resolveName)
            .toList(growable: false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onVisibleRemainingChanged(remainingNames);
        });
        return _MultiSelectMenuList<T>(
          width: width,
          items: remaining,
          allCatalogEmpty: items.isEmpty,
          scrollController: scrollController,
          highlightedIndexListenable: highlightedIndexListenable,
          highlightedRowKey: highlightedRowKey,
          onHighlightIndex: onHighlightIndex,
          onAdd: onAdd,
          resolveName: resolveName,
          resolveSmartMatched: resolveSmartMatched,
          smartMatchedTooltip: smartMatchedTooltip,
          copy: copy,
        );
      },
    );
  }
}

class _MultiSelectMenuSizedShell extends StatelessWidget {
  const _MultiSelectMenuSizedShell({
    required this.width,
    required this.maxHeight,
    required this.child,
  });

  final double width;
  final double maxHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return Container(
      key: MultiSelect.menuPanelKey,
      width: width > 0 ? width : 240,
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(tokens.radius.xs),
        border: Border.all(color: cs.hentai.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: cs.hentai.cardShadowHover,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radius.xs),
        child: child,
      ),
    );
  }
}

class _MultiSelectMenuList<T> extends StatelessWidget {
  const _MultiSelectMenuList({
    required this.width,
    required this.items,
    required this.allCatalogEmpty,
    required this.scrollController,
    required this.highlightedIndexListenable,
    required this.highlightedRowKey,
    required this.onHighlightIndex,
    required this.onAdd,
    required this.resolveName,
    required this.copy,
    this.resolveSmartMatched,
    this.smartMatchedTooltip,
  });

  final double width;
  final List<T> items;
  final bool allCatalogEmpty;
  final ScrollController scrollController;
  final ValueListenable<int?> highlightedIndexListenable;
  final GlobalKey highlightedRowKey;
  final void Function(int index, {bool scrollIntoView}) onHighlightIndex;
  final ValueChanged<String> onAdd;
  final String Function(T item) resolveName;
  final MultiSelectCopy copy;
  final bool Function(T item)? resolveSmartMatched;
  final String? smartMatchedTooltip;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final double panelMaxHeight = math.min(
      _kMultiSelectMenuMaxHeight,
      MediaQuery.sizeOf(context).height * 0.45,
    );

    return _MultiSelectMenuSizedShell(
      width: width,
      maxHeight: panelMaxHeight,
      child: items.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.spacing.lg,
                  vertical: tokens.spacing.md,
                ),
                child: Text(
                  allCatalogEmpty ? copy.emptyCatalog : copy.emptyRemaining,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: tokens.text.bodySm,
                    color: cs.hentai.textTertiary,
                  ),
                ),
              ),
            )
          : ValueListenableBuilder<int?>(
              valueListenable: highlightedIndexListenable,
              builder:
                  (BuildContext context, int? highlightedIndex, Widget? _) {
                    return ListView.builder(
                      controller: scrollController,
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.only(
                        top: tokens.spacing.sm,
                        bottom: tokens.spacing.md + 2,
                      ),
                      itemCount: items.length,
                      itemBuilder: (BuildContext context, int index) {
                        final T item = items[index];
                        final String name = resolveName(item);
                        final bool smartMatched =
                            resolveSmartMatched?.call(item) ?? false;
                        final bool isHighlighted = highlightedIndex == index;
                        return _MultiSelectDropdownRow(
                          key: isHighlighted ? highlightedRowKey : null,
                          displayName: name,
                          isHighlighted: isHighlighted,
                          smartMatched: smartMatched,
                          smartMatchedTooltip: smartMatchedTooltip,
                          onHover: () => onHighlightIndex(index),
                          onSelect: () => onAdd(name),
                        );
                      },
                    );
                  },
            ),
    );
  }
}

class _MultiSelectDropdownRow extends StatelessWidget {
  const _MultiSelectDropdownRow({
    super.key,
    required this.displayName,
    required this.onSelect,
    required this.onHover,
    this.isHighlighted = false,
    this.smartMatched = false,
    this.smartMatchedTooltip,
  });

  final String displayName;
  final VoidCallback onSelect;
  final VoidCallback onHover;
  final bool isHighlighted;
  final bool smartMatched;
  final String? smartMatchedTooltip;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final Color selectedFill = cs.primary.withAlpha(14);
    final Color hoverFill = cs.primary.withAlpha(10);

    final Widget nameText = Text(
      displayName,
      style: TextStyle(
        fontSize: 14,
        fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
        color: isHighlighted ? cs.primary : cs.hentai.textPrimary,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );

    final Widget rowChild;
    if (smartMatched) {
      final Widget hint = Icon(
        LucideIcons.sparkles,
        key: MultiSelect.smartMatchedHintKey,
        size: 14,
        color: cs.hentai.textTertiary,
      );
      final String? tip = smartMatchedTooltip;
      rowChild = Row(
        children: <Widget>[
          Expanded(child: nameText),
          SizedBox(width: tokens.spacing.sm),
          if (tip == null || tip.isEmpty)
            hint
          else
            Tooltip(message: tip, child: hint),
        ],
      );
    } else {
      rowChild = nameText;
    }

    return Theme(
      data: theme.copyWith(
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: isHighlighted ? Colors.transparent : hoverFill,
      ),
      child: Semantics(
        selected: isHighlighted,
        button: true,
        label: displayName,
        child: Material(
          color: isHighlighted ? selectedFill : Colors.transparent,
          child: InkWell(
            onTap: onSelect,
            onHover: (bool hovering) {
              if (hovering) {
                onHover();
              }
            },
            hoverColor: isHighlighted ? Colors.transparent : hoverFill,
            splashFactory: NoSplash.splashFactory,
            overlayColor: WidgetStateProperty.resolveWith((
              Set<WidgetState> states,
            ) {
              if (states.contains(WidgetState.pressed)) {
                return selectedFill;
              }
              if (states.contains(WidgetState.hovered) && !isHighlighted) {
                return hoverFill;
              }
              return Colors.transparent;
            }),
            child: Padding(
              padding: _MultiSelectDropdownListStyles.rowPadding,
              child: rowChild,
            ),
          ),
        ),
      ),
    );
  }
}
