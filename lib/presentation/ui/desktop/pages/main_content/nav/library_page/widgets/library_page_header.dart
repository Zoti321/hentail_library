part of 'library_page_widgets.dart';

TextStyle _buildLibraryPageTitleStyle(ColorScheme colorScheme) {
  return TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w600,
    color: colorScheme.textPrimary,
    letterSpacing: -0.4,
  );
}

class LibraryPageHeader extends ConsumerWidget {
  const LibraryPageHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final int comicCount = ref.watch(libraryDisplayedComicCountProvider);
    final int seriesCount = ref.watch(libraryDisplayedSeriesCountProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          AppStrings.libraryTitle,
          style: _buildLibraryPageTitleStyle(theme.colorScheme),
        ),
        const SizedBox(width: 12),
        MetaChip(
          icon: LucideIcons.library,
          label: AppStrings.comicCount(comicCount),
        ),
        const SizedBox(width: 8),
        MetaChip(
          icon: LucideIcons.bookMarked,
          label: '$seriesCount 个系列',
        ),
      ],
    );
  }
}

class LibraryPageSubtitle extends StatelessWidget {
  const LibraryPageSubtitle({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Text(
      '浏览、搜索与筛选本地漫画',
      style: TextStyle(fontSize: 13, color: theme.colorScheme.textTertiary),
    );
  }
}
