part of 'library_page_widgets.dart';

class _LibraryCatalogEmptySliver extends StatelessWidget {
  const _LibraryCatalogEmptySliver({
    required this.entity,
    required this.isTableEmpty,
  });

  final LibraryDisplayTarget entity;
  final bool isTableEmpty;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final LibraryEmptyStateContent content = resolveLibraryEmptyStateContent(
      entity: entity,
      isTableEmpty: isTableEmpty,
    );
    final IconData icon = switch (content.icon) {
      LibraryEmptyStateIcon.library => LucideIcons.library,
      LibraryEmptyStateIcon.listFilter => LucideIcons.listFilter,
    };
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 80, bottom: 48),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: <Widget>[
              Icon(
                icon,
                size: 56,
                color: theme.colorScheme.hentai.textTertiary,
              ),
              Text(
                content.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.hentai.textPrimary,
                ),
              ),
              Text(
                content.hint,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.hentai.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (content.showManagePathsEntry)
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
                      side: BorderSide(
                        color: theme.colorScheme.hentai.borderSubtle,
                      ),
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
