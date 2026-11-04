part of 'md3e_named_facet_multi_select_field.dart';

double _md3eNamedFacetMenuPanelMaxHeight(BuildContext context) {
  final M3EDropdownMenuTheme menuTheme = M3ETheme.of(context).dropdownMenuTheme;
  return math.min(
    _kMd3eNamedFacetMultiSelectMenuMaxHeight,
    math.min(
      menuTheme.panelMaxHeight,
      MediaQuery.sizeOf(context).height * 0.45,
    ),
  );
}

double _md3eNamedFacetMenuBodyMinHeight(double panelMaxHeight) {
  return math.min(
    panelMaxHeight,
    _kMd3eNamedFacetMultiSelectMenuEmptyMinHeight,
  );
}

class _Md3eNamedFacetMultiSelectMenuPanel<T> extends ConsumerWidget {
  const _Md3eNamedFacetMultiSelectMenuPanel({
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
  final Md3eNamedFacetMultiSelectCopy copy;
  final bool Function(T item)? resolveSmartMatched;
  final String? smartMatchedTooltip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<T>> asyncItems = ref.watch(itemsProvider);
    final double panelMaxHeight = _md3eNamedFacetMenuPanelMaxHeight(context);
    final double bodyMinHeight =
        _md3eNamedFacetMenuBodyMinHeight(panelMaxHeight);
    return asyncItems.when(
      loading: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onVisibleRemainingChanged(const <String>[]);
        });
        return _Md3eNamedFacetMenuShell(
          width: width,
          maxHeight: panelMaxHeight,
          minHeight: bodyMinHeight,
          child: SizedBox(
            width: double.infinity,
            height: bodyMinHeight,
            child: const Center(
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
        return _Md3eNamedFacetMenuShell(
          width: width,
          maxHeight: panelMaxHeight,
          minHeight: bodyMinHeight,
          child: SizedBox(
            width: double.infinity,
            height: bodyMinHeight,
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: M3ETheme.of(context).spacing.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      copy.listLoadFailed,
                      textAlign: TextAlign.center,
                      style: M3ETheme.of(context).typeScale.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: M3ETheme.of(context).spacing.sm),
                    M3EButton(
                      onPressed: onRetry,
                      style: M3EButtonStyle.text,
                      child: Text(copy.retryLabel),
                    ),
                  ],
                ),
              ),
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
        return _Md3eNamedFacetMenuList<T>(
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

class _Md3eNamedFacetMenuShell extends StatelessWidget {
  const _Md3eNamedFacetMenuShell({
    required this.width,
    required this.maxHeight,
    required this.child,
    this.minHeight = 0,
  });

  final double width;
  final double maxHeight;
  final double minHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EDropdownMenuTheme menuTheme = theme.dropdownMenuTheme;
    final BorderRadius optionRadius = theme.chipTheme.borderRadius;
    return Material(
      key: Md3eNamedFacetMultiSelectField.menuPanelKey,
      elevation: menuTheme.panelElevation,
      color: menuTheme.panelBackgroundColor(theme.colorScheme),
      shape: RoundedRectangleBorder(borderRadius: optionRadius),
      clipBehavior: Clip.antiAlias,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: width > 0 ? width : 280,
            maxHeight: maxHeight,
            minHeight: minHeight,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Md3eNamedFacetMenuList<T> extends StatelessWidget {
  const _Md3eNamedFacetMenuList({
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
  final Md3eNamedFacetMultiSelectCopy copy;
  final bool Function(T item)? resolveSmartMatched;
  final String? smartMatchedTooltip;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final double panelMaxHeight = _md3eNamedFacetMenuPanelMaxHeight(context);
    final double bodyMinHeight =
        _md3eNamedFacetMenuBodyMinHeight(panelMaxHeight);

    return _Md3eNamedFacetMenuShell(
      width: width,
      maxHeight: panelMaxHeight,
      minHeight: items.isEmpty ? bodyMinHeight : 0,
      child: items.isEmpty
          ? SizedBox(
              width: double.infinity,
              height: bodyMinHeight,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: theme.spacing.lg),
                  child: Text(
                    allCatalogEmpty ? copy.emptyCatalog : copy.emptyRemaining,
                    textAlign: TextAlign.center,
                    style: theme.typeScale.bodyMedium.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            )
          : ValueListenableBuilder<int?>(
              valueListenable: highlightedIndexListenable,
              builder: (BuildContext context, int? highlightedIndex, Widget? _) {
                return ListView.separated(
                  controller: scrollController,
                  padding: EdgeInsets.all(theme.spacing.sm),
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => SizedBox(height: theme.spacing.xs),
                  itemBuilder: (BuildContext context, int index) {
                    final T item = items[index];
                    final String name = resolveName(item);
                    final bool highlighted = highlightedIndex == index;
                    final bool smartMatched =
                        resolveSmartMatched?.call(item) ?? false;
                    return _Md3eNamedFacetMenuRow(
                      key: highlighted ? highlightedRowKey : null,
                      displayName: name,
                      isHighlighted: highlighted,
                      smartMatched: smartMatched,
                      smartMatchedTooltip: smartMatchedTooltip,
                      onSelect: () => onAdd(name),
                      onHover: () => onHighlightIndex(index),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _Md3eNamedFacetMenuRow extends StatelessWidget {
  const _Md3eNamedFacetMenuRow({
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
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final BorderRadius optionRadius = theme.chipTheme.borderRadius;

    final TextStyle nameStyle = theme.typeScale.bodyMedium.copyWith(
      fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
      color: isHighlighted ? scheme.primary : scheme.onSurface,
    );

    Widget nameText = Text(
      displayName,
      style: nameStyle,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );

    if (smartMatched) {
      final Widget hint = Icon(
        Symbols.auto_awesome,
        key: ValueKey<String>('md3e_named_facet_smart_matched_$displayName'),
        size: 16,
        color: scheme.onSurfaceVariant,
      );
      final String? tip = smartMatchedTooltip;
      nameText = Row(
        children: <Widget>[
          Expanded(child: Text(displayName, style: nameStyle, maxLines: 2)),
          SizedBox(width: theme.spacing.sm),
          if (tip == null || tip.isEmpty)
            hint
          else
            M3ETooltip(message: tip, child: hint),
        ],
      );
    }

    final Color fill = isHighlighted
        ? scheme.primary.withValues(alpha: 0.12)
        : Colors.transparent;

    return Material(
      color: fill,
      borderRadius: optionRadius,
      child: InkWell(
        onTap: onSelect,
        onHover: (bool hovering) {
          if (hovering) {
            onHover();
          }
        },
        borderRadius: optionRadius,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.md,
            vertical: theme.spacing.sm,
          ),
          child: nameText,
        ),
      ),
    );
  }
}
