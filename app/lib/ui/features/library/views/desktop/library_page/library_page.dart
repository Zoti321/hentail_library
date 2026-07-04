import 'package:flutter/material.dart';
import 'package:hentai_library/ui/features/library/views/desktop/library_page/widgets/widgets.dart';
import 'package:hentai_library/ui/core/widgets/responsive_layout/library_blocks_layout.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _headerMeasureKey = GlobalKey();
  double? _headerExtent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_measureHeaderExtent);
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

  @override
  Widget build(BuildContext context) {
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
      body: CustomScrollView(
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
    );
  }
}
