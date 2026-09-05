import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_cover_viewport_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_inactive_subscription.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_state.dart';
import 'package:hentai_library/ui/features/library/view_models/library_comics_catalog_controller.dart';
import 'package:hentai_library/ui/features/library/view_models/library_series_catalog_controller.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_page_size_providers.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/widgets.dart';
import 'package:hentai_library/ui/features/shell/views/responsive_app_shell.dart';
import 'package:hentai_library/ui/core/widgets/responsive_layout/library_blocks_layout.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  static const Duration _coverViewportMinInterval = Duration(milliseconds: 75);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _headerMeasureKey = GlobalKey();
  final GlobalKey _catalogBlocksKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  double? _headerExtent;
  double? _catalogGridContentStartOffset;
  bool _isEndDrawerOpen = false;
  bool _coverViewportUpdateScheduled = false;
  DateTime? _lastCoverViewportUpdateAt;
  Timer? _coverViewportThrottleTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_measureHeaderExtent);
    _scrollController.addListener(_scheduleCoverViewportUpdate);
  }

  @override
  void dispose() {
    _coverViewportThrottleTimer?.cancel();
    _scrollController.removeListener(_scheduleCoverViewportUpdate);
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleCoverViewportUpdate() {
    if (_coverViewportUpdateScheduled) {
      return;
    }
    final DateTime now = DateTime.now();
    final DateTime? last = _lastCoverViewportUpdateAt;
    if (last != null) {
      final Duration elapsed = now.difference(last);
      if (elapsed < _coverViewportMinInterval) {
        _coverViewportUpdateScheduled = true;
        _coverViewportThrottleTimer?.cancel();
        _coverViewportThrottleTimer = Timer(
          _coverViewportMinInterval - elapsed,
          () {
            _coverViewportUpdateScheduled = false;
            if (!mounted) {
              return;
            }
            _scheduleCoverViewportUpdate();
          },
        );
        return;
      }
    }

    _coverViewportUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _coverViewportUpdateScheduled = false;
      if (!mounted) {
        return;
      }
      _lastCoverViewportUpdateAt = DateTime.now();
      _updateCoverViewport();
    });
  }

  void _measureCatalogGridStartOffset() {
    _catalogGridContentStartOffset = measureScrollableKeyedContentOffset(
      _catalogBlocksKey,
    );
  }

  void _updateCoverViewport() {
    if (_catalogGridContentStartOffset == null) {
      _measureCatalogGridStartOffset();
    }
    final double? gridStart = _catalogGridContentStartOffset;
    if (gridStart == null || !_scrollController.hasClients) {
      return;
    }

    final LibraryDisplayTarget target = ref.read(libraryDisplayTargetProvider);
    final int itemCount = switch (target) {
      LibraryDisplayTarget.comics =>
        ref.read(libraryComicsCatalogContentProvider).value?.items.length ?? 0,
      LibraryDisplayTarget.series =>
        ref.read(librarySeriesCatalogContentProvider).value?.items.length ?? 0,
    };
    if (itemCount <= 0) {
      ref.read(libraryCatalogCoverViewportProvider.notifier).clear();
      return;
    }

    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final double viewportHeight = MediaQuery.sizeOf(context).height;
    final LibraryLayoutTier layoutTier = libraryLayoutTierForWidth(
      viewportWidth,
    );
    final AppThemeTokens tokens = context.tokens;
    final double? gridContentOffset = measureScrollableKeyedContentOffset(
      _catalogBlocksKey,
    );
    if (gridContentOffset == null) {
      return;
    }
    final int crossAxisCount = libraryGridCrossAxisCount(
      viewportWidth,
      layoutTier,
    );
    final double rowExtent = libraryCatalogGridRowExtent(tokens, layoutTier);
    final double rowSpacing = libraryGridSpacing(layoutTier);
    final ({int startIndex, int endIndex}) range = visibleCatalogGridIndexRange(
      scrollPixels: gridContentOffset,
      viewportHeight: viewportHeight,
      gridStartScrollOffset: gridStart,
      itemCount: itemCount,
      rowExtent: rowExtent - rowSpacing,
      rowSpacing: rowSpacing,
      crossAxisCount: crossAxisCount,
    );
    ref
        .read(libraryCatalogCoverViewportProvider.notifier)
        .updateRange(startIndex: range.startIndex, endIndex: range.endIndex);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback(_measureHeaderExtent);
  }

  void _measureHeaderExtent(Duration _) {
    final RenderBox? box =
        _headerMeasureKey.currentContext?.findRenderObject() as RenderBox?;
    if (!mounted || box == null) {
      return;
    }
    final double height = box.size.height;
    if (_headerExtent != height) {
      setState(() => _headerExtent = height);
      _catalogGridContentStartOffset = null;
      _scheduleCoverViewportUpdate();
    }
  }

  void _openFilterSortDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _scrollToContentTop() {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      0,
      duration: kLibraryScrollToTopScrollDuration,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Keep inactive-tab catalog warm; do not watch revision coordinator here —
    // catalog controllers already select watchRevision leaves.
    ref.watch(libraryCatalogInactiveSubscriptionProvider);
    ref.listen<LibraryDisplayTarget>(libraryDisplayTargetProvider, (
      LibraryDisplayTarget? previous,
      LibraryDisplayTarget next,
    ) {
      if (previous == null || previous == next) {
        return;
      }
      _scrollToContentTop();
      _catalogGridContentStartOffset = null;
      _scheduleCoverViewportUpdate();
      if (_isEndDrawerOpen) {
        _scaffoldKey.currentState?.closeEndDrawer();
      }
    });
    ref.listen<int?>(
      libraryComicsCatalogControllerProvider.select(
        (AsyncValue<LibraryComicsCatalogState> async) =>
            async.value?.pagination.page,
      ),
      (int? previous, int? next) {
        if (previous == null || next == null || previous == next) {
          return;
        }
        _scrollToContentTop();
        _catalogGridContentStartOffset = null;
        _scheduleCoverViewportUpdate();
      },
    );
    ref.listen<int?>(
      librarySeriesCatalogControllerProvider.select(
        (AsyncValue<LibrarySeriesCatalogState> async) =>
            async.value?.pagination.page,
      ),
      (int? previous, int? next) {
        if (previous == null || next == null || previous == next) {
          return;
        }
        _scrollToContentTop();
        _catalogGridContentStartOffset = null;
        _scheduleCoverViewportUpdate();
      },
    );
    ref.listen<int>(libraryComicsTabPageSizeProvider, (
      int? previous,
      int next,
    ) {
      if (previous == null || previous == next) {
        return;
      }
      _scrollToContentTop();
      _catalogGridContentStartOffset = null;
      _scheduleCoverViewportUpdate();
    });
    ref.listen<int>(librarySeriesTabPageSizeProvider, (
      int? previous,
      int next,
    ) {
      if (previous == null || previous == next) {
        return;
      }
      _scrollToContentTop();
      _catalogGridContentStartOffset = null;
      _scheduleCoverViewportUpdate();
    });

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final LibraryLayoutTier layoutTier = libraryLayoutTierForWidth(
          constraints.maxWidth,
        );
        final double horizontalPadding = libraryContentHorizontalPadding(
          layoutTier,
        );
        final Widget headerSection = LibraryPageHeaderSection(
          layoutTier: layoutTier,
          horizontalPadding: horizontalPadding,
          onOpenFilterSort: _openFilterSortDrawer,
          onOpenNavigation: appShellPageNavigationOpener(context),
        );
        final Widget header = KeyedSubtree(
          key: _headerMeasureKey,
          child: headerSection,
        );

        return Scaffold(
          key: _scaffoldKey,
          endDrawer: const LibraryFilterSortDrawer(),
          onEndDrawerChanged: (bool isOpen) {
            if (_isEndDrawerOpen != isOpen) {
              setState(() => _isEndDrawerOpen = isOpen);
            }
          },
          bottomNavigationBar: libraryUsesContentSwitcherBottomBar(layoutTier)
              ? const LibraryDisplayTargetBottomBar()
              : null,
          body: Stack(
            children: <Widget>[
              CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: <Widget>[
                  if (_headerExtent == null)
                    SliverToBoxAdapter(child: header)
                  else
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: LibraryPinnedHeaderDelegate(
                        extent: _headerExtent!,
                        child: header,
                      ),
                    ),
                  LibraryContentSearchSliver(
                    layoutTier: layoutTier,
                    horizontalPadding: horizontalPadding,
                  ),
                  LibraryBlocksSliverGroup(
                    key: _catalogBlocksKey,
                    seriesBlock: LibrarySeriesBlock(
                      layoutTier: layoutTier,
                      horizontalPadding: horizontalPadding,
                    ),
                    comicsBlock: LibraryComicsBlock(
                      layoutTier: layoutTier,
                      horizontalPadding: horizontalPadding,
                    ),
                  ),
                ],
              ),
              LibraryScrollToTopButton(
                scrollController: _scrollController,
                isDrawerOpen: _isEndDrawerOpen,
              ),
            ],
          ),
        );
      },
    );
  }
}
