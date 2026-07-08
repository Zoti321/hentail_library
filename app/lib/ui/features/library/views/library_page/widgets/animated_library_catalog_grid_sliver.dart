part of 'library_page_widgets.dart';

class AnimatedLibraryCatalogGridSliver extends StatefulWidget {
  const AnimatedLibraryCatalogGridSliver({
    super.key,
    required this.layoutTier,
    required this.itemCount,
    required this.itemBuilder,
    required this.positionAnimationKey,
    required this.suppressAnimationKey,
  });

  final LibraryLayoutTier layoutTier;
  final int itemCount;

  /// 每个格子根节点必须带唯一 [ValueKey]（传给 [ReorderableBuilder] 的外层 widget）。
  final Widget Function(BuildContext context, int index) itemBuilder;
  final Object positionAnimationKey;
  final LibraryCatalogGridSuppressAnimationKey suppressAnimationKey;

  @override
  State<AnimatedLibraryCatalogGridSliver> createState() =>
      _AnimatedLibraryCatalogGridSliverState();
}

class _AnimatedLibraryCatalogGridSliverState
    extends State<AnimatedLibraryCatalogGridSliver> {
  final GlobalKey _gridViewKey = GlobalKey();
  bool _enableSortFlipAnimation = false;
  AppThemeTokens? _lastTokens;
  LibraryLayoutTier? _lastLayoutTier;
  SliverGridDelegate? _cachedDelegate;

  @override
  void didUpdateWidget(AnimatedLibraryCatalogGridSliver oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool sortChanged =
        widget.positionAnimationKey != oldWidget.positionAnimationKey;
    final bool suppressChanged =
        widget.suppressAnimationKey != oldWidget.suppressAnimationKey;
    if (widget.layoutTier != oldWidget.layoutTier) {
      _cachedDelegate = null;
    }

    _enableSortFlipAnimation = nextLibraryCatalogSortFlipAnimationEnabled(
      current: _enableSortFlipAnimation,
      sortChanged: sortChanged,
      suppressChanged: suppressChanged,
    );
  }

  SliverGridDelegate _delegateFor(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    if (_cachedDelegate != null &&
        _lastTokens == tokens &&
        _lastLayoutTier == widget.layoutTier) {
      return _cachedDelegate!;
    }
    _lastTokens = tokens;
    _lastLayoutTier = widget.layoutTier;
    return _cachedDelegate = libraryGridDelegateForTokens(
      tokens,
      widget.layoutTier,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: ReorderableBuilder<void>.builder(
        enableDraggable: false,
        itemCount: widget.itemCount,
        animationConfig: libraryCatalogSortFlipAnimationConfig(
          enableAnimations: _enableSortFlipAnimation,
        ),
        childBuilder: (Widget Function(Widget child, int index) wrapGridChild) {
          return GridView.builder(
            key: _gridViewKey,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: _delegateFor(context),
            itemCount: widget.itemCount,
            itemBuilder: (BuildContext context, int index) {
              return wrapGridChild(widget.itemBuilder(context, index), index);
            },
          );
        },
      ),
    );
  }
}
