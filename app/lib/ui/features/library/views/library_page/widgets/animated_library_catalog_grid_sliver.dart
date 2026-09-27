part of 'library_page_widgets.dart';

class AnimatedLibraryCatalogGridSliver extends StatefulWidget {
  const AnimatedLibraryCatalogGridSliver({
    super.key,
    required this.layoutTier,
    required this.itemCount,
    required this.itemBuilder,
    required this.positionAnimationKey,
    required this.suppressAnimationKey,
    required this.sortFlipEnabled,
  });

  final LibraryLayoutTier layoutTier;
  final int itemCount;

  /// 每个格子根节点必须带唯一 [ValueKey]（传给 [ReorderableBuilder] 的外层 widget）。
  final Widget Function(BuildContext context, int index) itemBuilder;
  final Object positionAnimationKey;
  final LibraryCatalogGridSuppressAnimationKey suppressAnimationKey;
  final bool sortFlipEnabled;

  @override
  State<AnimatedLibraryCatalogGridSliver> createState() =>
      _AnimatedLibraryCatalogGridSliverState();
}

class _AnimatedLibraryCatalogGridSliverState
    extends State<AnimatedLibraryCatalogGridSliver>
    with SingleTickerProviderStateMixin {
  final GlobalKey _gridViewKey = GlobalKey();
  bool _enableSortFlipAnimation = false;
  AppThemeTokens? _lastTokens;
  LibraryLayoutTier? _lastLayoutTier;
  SliverGridDelegate? _cachedDelegate;
  Timer? _returnToVirtualizedTimer;
  int _flipEpoch = 0;
  late final AnimationController _pageTransitionController =
      AnimationController(vsync: this);
  Animation<double>? _pageOpacity;
  Animation<Offset>? _pageSlide;
  LibraryCatalogPageTransitionDirection _pageDirection =
      LibraryCatalogPageTransitionDirection.none;
  bool _pageTransitionActive = false;
  int _pageTransitionGeneration = 0;

  static const Offset _kPageTransitionSlideForward = Offset(0.028, 0);
  static const Offset _kPageTransitionSlideBackward = Offset(-0.028, 0);

  @override
  void initState() {
    super.initState();
    _pageTransitionController.addStatusListener(_onPageTransitionStatus);
    _pageTransitionController.value = 1;
  }

  @override
  void dispose() {
    _returnToVirtualizedTimer?.cancel();
    _pageTransitionController.removeStatusListener(_onPageTransitionStatus);
    _pageTransitionController.dispose();
    super.dispose();
  }

  void _onPageTransitionStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) {
      return;
    }
    setState(() {
      _pageTransitionActive = false;
      _pageTransitionGeneration++;
    });
  }

  void _rebuildPageTransitionAnimations() {
    final AnimationController controller = _pageTransitionController;
    _pageOpacity = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    );
    final Offset slideBegin = switch (_pageDirection) {
      LibraryCatalogPageTransitionDirection.forward =>
        _kPageTransitionSlideForward,
      LibraryCatalogPageTransitionDirection.backward =>
        _kPageTransitionSlideBackward,
      LibraryCatalogPageTransitionDirection.none => Offset.zero,
    };
    _pageSlide = Tween<Offset>(begin: slideBegin, end: Offset.zero).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
    );
  }

  void _maybeStartPageTransition(
    LibraryCatalogGridSuppressAnimationKey previous,
    LibraryCatalogGridSuppressAnimationKey next,
  ) {
    if (!libraryCatalogGridPageOnlyChanged(previous: previous, next: next)) {
      return;
    }
    if (_enableSortFlipAnimation) {
      return;
    }
    _pageDirection = libraryCatalogPageTransitionDirection(
      previousPage: previous.page,
      nextPage: next.page,
    );
    _rebuildPageTransitionAnimations();
    final Duration duration = motionDurationOf(
      context,
      kLibraryCatalogPageTransitionDuration,
    );
    _pageTransitionController.duration = duration;
    if (duration == Duration.zero) {
      _pageTransitionActive = false;
      _pageTransitionController.value = 1;
      return;
    }
    setState(() {
      _pageTransitionActive = true;
    });
    _pageTransitionController.forward(from: 0);
  }

  Widget _wrapGridItem(Widget child) {
    if (!_pageTransitionActive ||
        _pageOpacity == null ||
        _pageSlide == null) {
      return child;
    }
    return AnimatedBuilder(
      animation: _pageTransitionController,
      builder: (BuildContext context, Widget? builtChild) {
        if (_pageTransitionController.isCompleted) {
          return builtChild!;
        }
        return FadeTransition(
          opacity: _pageOpacity!,
          child: SlideTransition(position: _pageSlide!, child: builtChild!),
        );
      },
      child: child,
    );
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

    if (!widget.sortFlipEnabled && _enableSortFlipAnimation) {
      _returnToVirtualizedTimer?.cancel();
      _enableSortFlipAnimation = false;
    }

    _enableSortFlipAnimation = nextLibraryCatalogSortFlipAnimationEnabled(
      userEnabled: widget.sortFlipEnabled,
      current: _enableSortFlipAnimation,
      sortChanged: sortChanged,
      suppressChanged: suppressChanged,
    );

    if (suppressChanged) {
      _maybeStartPageTransition(
        oldWidget.suppressAnimationKey,
        widget.suppressAnimationKey,
      );
    }

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
        key: ValueKey<int>(_pageTransitionGeneration),
        gridDelegate: gridDelegate,
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            return _wrapGridItem(widget.itemBuilder(context, index));
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
