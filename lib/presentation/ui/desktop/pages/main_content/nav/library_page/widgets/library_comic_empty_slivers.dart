part of 'library_page_widgets.dart';

class _NoMatchingComicsSliver extends StatelessWidget {
  const _NoMatchingComicsSliver({
    this.query = '',
    this.showManagePathsEntry = false,
  });
  final String query;
  final bool showManagePathsEntry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String q = query.trim();
    final bool hasQuery = q.isNotEmpty;
    final String message = hasQuery ? '无匹配漫画（可尝试调整搜索或筛选）' : '暂无漫画';
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 48),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: [
              Text(
                message,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.hentai.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
              if (showManagePathsEntry)
                OutlinedButton.icon(
                  onPressed: () => context.go('/paths'),
                  icon: Icon(
                    LucideIcons.folderTree,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  label: const Text('管理扫描路径'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(color: theme.colorScheme.hentai.borderSubtle),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyLibrarySliver extends StatelessWidget {
  const _EmptyLibrarySliver({
    this.query = '',
    this.showManagePathsEntry = false,
  });
  final String query;
  final bool showManagePathsEntry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String q = query.trim();
    final bool isSearching = q.isNotEmpty;
    final String title = isSearching
        ? AppStrings.libraryNoMatchTitle
        : AppStrings.libraryEmptyTitle;
    final String hint = isSearching
        ? AppStrings.libraryNoMatchHint(q)
        : AppStrings.libraryEmptyHint;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              Icon(
                LucideIcons.library,
                size: 56,
                color: theme.colorScheme.hentai.textTertiary,
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.hentai.textPrimary,
                ),
              ),
              Text(
                hint,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.hentai.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (showManagePathsEntry)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/paths'),
                    icon: Icon(
                      LucideIcons.folderTree,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    label: const Text('管理扫描路径'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(color: theme.colorScheme.hentai.borderSubtle),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
