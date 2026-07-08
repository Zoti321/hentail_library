import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_prefetch_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_state.dart';
import 'package:hentai_library/ui/features/library/view_models/library_comics_catalog_controller.dart';
import 'package:hentai_library/ui/features/library/view_models/library_series_catalog_controller.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_page_size_providers.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_layout_constants.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/widgets.dart';
import 'package:hentai_library/ui/features/shell/views/responsive_app_shell.dart';
import 'package:hentai_library/ui/core/widgets/responsive_layout/library_blocks_layout.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _headerMeasureKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  double? _headerExtent;
  bool _isEndDrawerOpen = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_measureHeaderExtent);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
    ref.watch(libraryCatalogPrefetchProvider);
    ref.listen<LibraryDisplayTarget>(libraryDisplayTargetProvider, (
      LibraryDisplayTarget? previous,
      LibraryDisplayTarget next,
    ) {
      if (previous == null || previous == next) {
        return;
      }
      _scrollToContentTop();
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
    });
    ref.listen<int>(librarySeriesTabPageSizeProvider, (
      int? previous,
      int next,
    ) {
      if (previous == null || previous == next) {
        return;
      }
      _scrollToContentTop();
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
          onOpenNavigation: layoutTier == LibraryLayoutTier.compact
              ? openAppShellNavigationDrawer
              : null,
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
