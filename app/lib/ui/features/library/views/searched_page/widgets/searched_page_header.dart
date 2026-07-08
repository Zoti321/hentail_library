import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/chip/meta_chip.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_layout_constants.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SearchedPageHeaderSection extends StatelessWidget {
  const SearchedPageHeaderSection({
    super.key,
    required this.layoutTier,
    required this.horizontalPadding,
    required this.query,
    required this.resultCount,
    this.showQuotes = true,
  });

  final LibraryLayoutTier layoutTier;
  final double horizontalPadding;
  final String query;
  final int resultCount;
  final bool showQuotes;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final String title = showQuotes ? '"$query"的搜索结果' : query;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        kLibraryHeaderVerticalPadding,
        horizontalPadding,
        kLibraryHeaderVerticalPadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Flexible(
            child: Text(
              title,
              style: libraryPageTitleStyle(cs, layoutTier),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          MetaChip(icon: LucideIcons.search, label: '$resultCount'),
        ],
      ),
    );
  }
}
