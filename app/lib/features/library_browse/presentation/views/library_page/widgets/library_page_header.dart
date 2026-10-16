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
    this.showActiveCountChipOnly = false,
  });

  final LibraryLayoutTier layoutTier;
  final bool showCountChips;
  final bool showActiveCountChipOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = context.l10n;
    final int comicCount = ref.watch(libraryDisplayedComicCountProvider);
    final int seriesCount = ref.watch(libraryDisplayedSeriesCountProvider);
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryDisplayTargetProvider,
    );

    final List<Widget> countChips = <Widget>[];
    if (showCountChips) {
      final bool showComicsChip =
          !showActiveCountChipOnly ||
          displayTarget == LibraryDisplayTarget.comics;
      final bool showSeriesChip =
          !showActiveCountChipOnly ||
          displayTarget == LibraryDisplayTarget.series;
      if (showActiveCountChipOnly) {
        if (showComicsChip) {
          countChips.add(
            CountDigitChip(
              count: comicCount,
              semanticLabel: l10n.comicCount(comicCount),
            ),
          );
        } else if (showSeriesChip) {
          countChips.add(
            CountDigitChip(
              count: seriesCount,
              semanticLabel: l10n.librarySeriesCount(seriesCount),
            ),
          );
        }
      } else {
        if (showComicsChip) {
          countChips.add(
            MetaChip(
              icon: LucideIcons.library,
              label: l10n.comicCount(comicCount),
            ),
          );
        }
        if (showSeriesChip) {
          if (countChips.isNotEmpty) {
            countChips.add(const SizedBox(width: 8));
          }
          countChips.add(
            MetaChip(
              icon: LucideIcons.bookMarked,
              label: l10n.librarySeriesCount(seriesCount),
            ),
          );
        }
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          l10n.libraryTitle,
          style: libraryPageTitleStyle(theme.colorScheme, layoutTier),
        ),
        if (countChips.isNotEmpty) ...<Widget>[
          const SizedBox(width: 12),
          ...countChips,
        ],
      ],
    );
  }
}
