part of 'library_page_widgets.dart';

const double kLibraryHeaderCompactBreakpoint = 768;
const double kLibrarySearchMaxWidth = 480;
const double kLibrarySearchToGridSpacing = 16;
const double kLibraryHeaderVerticalPadding = 10;

bool libraryHeaderShowsCountChips(BuildContext context) {
  return MediaQuery.sizeOf(context).width >= kLibraryHeaderCompactBreakpoint;
}

TextStyle _buildLibraryPageTitleStyle(ColorScheme colorScheme) {
  return TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w600,
    color: colorScheme.hentai.textPrimary,
    letterSpacing: -0.4,
  );
}

class LibraryPageHeader extends ConsumerWidget {
  const LibraryPageHeader({super.key, this.showCountChips = true});

  final bool showCountChips;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final int comicCount = ref.watch(libraryDisplayedComicCountProvider);
    final int seriesCount = ref.watch(libraryDisplayedSeriesCountProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          AppStrings.libraryTitle,
          style: _buildLibraryPageTitleStyle(theme.colorScheme),
        ),
        if (showCountChips) ...<Widget>[
          const SizedBox(width: 12),
          MetaChip(
            icon: LucideIcons.library,
            label: AppStrings.comicCount(comicCount),
          ),
          const SizedBox(width: 8),
          MetaChip(icon: LucideIcons.bookMarked, label: '$seriesCount 个系列'),
        ],
      ],
    );
  }
}
