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
  Timer? _returnToVirtualizedTimer;
  int _flipEpoch = 0;

  @override
  void dispose() {
    _returnToVirtualizedTimer?.cancel();
    super.dispose();
  }

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

    if (sortChanged && _enableSortFlipAnimation) {
      _scheduleReturnToVirtualizedGrid();
    }
  }

  void _scheduleReturnToVirtualizedGrid() {
    _returnToVirtualizedTimer?.cancel();
    final int epoch = ++_flipEpoch;
    _returnToVirtualizedTimer = Timer(kLibraryCatalogSortFlipDuration, () {
      if (!mounted || epoch != _flipEpoch || !_enableSortFlipAnimation) {
        return;
      }
      setState(() {
        _enableSortFlipAnimation = false;
      });
    });
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
    final SliverGridDelegate gridDelegate = _delegateFor(context);

    // Steady-state path: true SliverGrid so CustomScrollView virtualizes.
    // Sort FLIP briefly uses shrinkWrap ReorderableBuilder, then returns.
    if (!_enableSortFlipAnimation) {
      return SliverGrid(
        gridDelegate: gridDelegate,
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            return widget.itemBuilder(context, index);
          },
          childCount: widget.itemCount,
          addAutomaticKeepAlives: false,
        ),
      );
    }

    return SliverToBoxAdapter(
      child: ReorderableBuilder<void>.builder(
        enableDraggable: false,
        itemCount: widget.itemCount,
        animationConfig: libraryCatalogSortFlipAnimationConfig(
          enableAnimations: !reduceMotionOf(context),
        ),
        childBuilder: (Widget Function(Widget child, int index) wrapGridChild) {
          return GridView.builder(
            key: _gridViewKey,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: gridDelegate,
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
