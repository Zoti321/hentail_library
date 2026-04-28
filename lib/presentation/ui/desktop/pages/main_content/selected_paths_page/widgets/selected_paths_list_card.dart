import 'package:flutter/material.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/selected_paths_page/widgets/path_tile.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hentai_library/theme/theme.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SelectedPathsListCard extends ConsumerWidget {
  const SelectedPathsListCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);

    final List<String> paths = ref.watch(
      selectedPathsPageProvider.select(
        (AsyncValue<SelectedPathsPageState> async) =>
            async.asData?.value.paths ?? const <String>[],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.borderSubtle),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: theme.colorScheme.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                border: Border(
                  bottom: BorderSide(color: theme.colorScheme.borderSubtle),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    LucideIcons.folderTree,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '已保存路径',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '共 ${paths.length} 项',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (paths.isEmpty)
              const _EmptyPaths()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: paths.length,
                separatorBuilder: (_, int index) =>
                    Divider(height: 1, color: theme.colorScheme.borderSubtle),
                itemBuilder: (BuildContext context, int index) {
                  final String path = paths[index];
                  return PathTile(path: path);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPaths extends StatelessWidget {
  const _EmptyPaths();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 36),
        child: Column(
          children: <Widget>[
            Icon(
              LucideIcons.folderSearch2,
              size: 28,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              '暂无路径，请添加文件或文件夹',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
