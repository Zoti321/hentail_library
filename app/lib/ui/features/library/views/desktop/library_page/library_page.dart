import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_pagination_providers.dart';
import 'package:hentai_library/ui/features/library/views/desktop/library_page/widgets/widgets.dart';
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
    ref.listen<int>(libraryComicsPageIndexProvider, (
      int? previous,
      int next,
    ) {
      if (previous == null || previous == next) {
        return;
      }
      _scrollToContentTop();
    });
    ref.listen<int>(librarySeriesPageIndexProvider, (
      int? previous,
      int next,
    ) {
      if (previous == null || previous == next) {
        return;
      }
      _scrollToContentTop();
    });

    final Widget headerSection = LibraryPageHeaderSection(
      onOpenFilterSort: _openFilterSortDrawer,
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
              const LibraryContentSearchSliver(),
              const LibraryBlocksSliverGroup(
                seriesBlock: LibrarySeriesBlock(),
                comicsBlock: LibraryComicsBlock(),
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
  }
}
