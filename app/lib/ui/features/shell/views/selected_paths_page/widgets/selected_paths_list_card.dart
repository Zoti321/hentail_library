import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/features/shell/views/selected_paths_page/widgets/path_tile.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SelectedPathsListCard extends ConsumerWidget {
  const SelectedPathsListCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final l10n = context.l10n;

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
        border: Border.all(color: theme.colorScheme.hentai.borderSubtle),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: theme.colorScheme.hentai.cardShadow,
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
                  bottom: BorderSide(
                    color: theme.colorScheme.hentai.borderSubtle,
                  ),
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
                    l10n.pathsSavedHeading,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.hentai.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    l10n.pathsTotalCount(paths.length),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.hentai.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (paths.isEmpty)
              _EmptyPaths(l10n: l10n)
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: paths.length,
                separatorBuilder: (_, int index) => Divider(
                  height: 1,
                  color: theme.colorScheme.hentai.borderSubtle,
                ),
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
  const _EmptyPaths({required this.l10n});

  final AppLocalizations l10n;

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
              l10n.pathsEmptyHint,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.hentai.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
