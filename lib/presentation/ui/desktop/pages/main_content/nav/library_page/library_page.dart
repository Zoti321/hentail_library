import 'package:flutter/material.dart';
import 'package:hentai_library/presentation/theme/theme.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/nav/library_page/widgets/widgets.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/responsive_layout/library_blocks_layout.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: tokens.layout.contentAreaPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LibraryPageHeader(),
                const SizedBox(height: 8),
                const LibraryPageSubtitle(),
                const SizedBox(height: 12),
                const LibrarySearchToolbarRow(),
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
