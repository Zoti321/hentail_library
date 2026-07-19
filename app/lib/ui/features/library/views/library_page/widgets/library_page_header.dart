part of 'library_page_widgets.dart';

const double kLibrarySearchMaxWidth = 480;
const double kLibrarySearchToGridSpacing = 16;
const double kLibraryHeaderVerticalPadding = 10;

TextStyle libraryPageTitleStyle(
  ColorScheme colorScheme,
  LibraryLayoutTier layoutTier,
) {
  return TextStyle(
    fontSize: libraryPageTitleFontSize(layoutTier),
    fontWeight: FontWeight.w600,
    color: colorScheme.hentai.textPrimary,
    letterSpacing: -0.4,
  );
}

class LibraryPageHeader extends ConsumerWidget {
  const LibraryPageHeader({
    super.key,
    required this.layoutTier,
    this.showCountChips = true,
  });

  final LibraryLayoutTier layoutTier;
  final bool showCountChips;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = context.l10n;
    final int comicCount = ref.watch(libraryDisplayedComicCountProvider);
    final int seriesCount = ref.watch(libraryDisplayedSeriesCountProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          l10n.libraryTitle,
          style: libraryPageTitleStyle(theme.colorScheme, layoutTier),
        ),
        if (showCountChips) ...<Widget>[
          const SizedBox(width: 12),
          MetaChip(
            icon: LucideIcons.library,
            label: l10n.comicCount(comicCount),
          ),
          const SizedBox(width: 8),
          MetaChip(
            icon: LucideIcons.bookMarked,
            label: l10n.librarySeriesCount(seriesCount),
          ),
        ],
      ],
    );
  }
}
