import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/chip/meta_chip.dart';
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
    this.onOpenNavigation,
  });

  final LibraryLayoutTier layoutTier;
  final double horizontalPadding;
  final String query;
  final int resultCount;
  final bool showQuotes;
  final VoidCallback? onOpenNavigation;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
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
          if (onOpenNavigation != null) ...<Widget>[
            GhostButton.icon(
              icon: LucideIcons.menu,
              semanticLabel: '打开导航菜单',
              tooltip: '',
              iconSize: 16,
              size: 32,
              borderRadius: 8,
              foregroundColor: cs.hentai.iconDefault,
              hoverColor: Theme.of(context).hoverColor,
              overlayColor: Theme.of(context).hoverColor,
              onPressed: onOpenNavigation,
            ),
            const SizedBox(width: 8),
          ],
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
