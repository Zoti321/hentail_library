import 'package:flutter/material.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/nav/library_page/widgets/widgets.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/responsive_layout/library_blocks_layout.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LibraryPageHeader(),
                SizedBox(height: 8),
                LibraryPageSubtitle(),
                SizedBox(height: 12),
                LibrarySearchToolbarRow(),
              ],
            ),
          ),
        ),
        const LibraryBlocksSliverGroup(
          seriesBlock: LibrarySeriesBlock(),
          comicsBlock: LibraryComicsBlock(),
        ),
      ],
    );
  }
}
