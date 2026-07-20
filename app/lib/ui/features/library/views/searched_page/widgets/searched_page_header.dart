import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/chip/meta_chip.dart';
import 'package:hentai_library/ui/features/library/view_models/library_search_query_parser.dart';
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
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final String displayQuery =
        unwrapFullyQuotedLibrarySearchQuery(query) ?? query;
    final AppLocalizations l10n = context.l10n;
    final String title = showQuotes
        ? l10n.searchResultsForQuery(displayQuery)
        : query;
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
          GhostButton.icon(
            icon: LucideIcons.arrowLeft,
            tooltip: l10n.shellBack,
            semanticLabel: l10n.shellBack,
            iconSize: 16,
            size: 32,
            borderRadius: 8,
            foregroundColor: cs.hentai.iconDefault,
            hoverColor: theme.hoverColor,
            overlayColor: theme.hoverColor,
            onPressed: () => popOrGoLibrary(context),
          ),
          const SizedBox(width: 8),
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

  static void popOrGoLibrary(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/local');
  }
}
