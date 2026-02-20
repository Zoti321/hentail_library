part of 'library_page_widgets.dart';

class LibraryPageHeader extends ConsumerWidget {
  const LibraryPageHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final int comicCount = ref.watch(
      libraryPageProvider.select((LibraryPageState s) => s.rawList.length),
    );
    final LibrarySeriesViewData seriesView = ref.watch(librarySeriesViewDataProvider);
    final int seriesCount = seriesView.seriesWithItemsCount;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          AppStrings.libraryTitle,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.borderSubtle),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.library,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                AppStrings.comicCount(comicCount),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.borderSubtle),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.bookMarked,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                '$seriesCount 个系列',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.textSecondary,
                ),
              ),
            ],
          ),
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
      style: TextStyle(
        fontSize: 13,
        color: theme.colorScheme.textTertiary,
      ),
    );
  }
}
