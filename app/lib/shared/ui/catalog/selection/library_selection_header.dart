import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/catalog/selection/catalog_selection_notifier.dart';
import 'package:hentai_library/design-system/components/scaffold/pinned_toolbar_chrome.dart';

/// 多选批量编辑命令（owner 注入；壳不持业务规则）。
typedef CatalogSelectionEditMetadataAction = Future<void> Function(
  BuildContext context,
  WidgetRef ref,
  List<String> ids,
);

/// 库页 / 系列详情选择模式页头（MD3E）：退出 / 全选本页 / 清空 / 批量编辑 / 已选数量。
class LibrarySelectionHeader extends ConsumerWidget {
  const LibrarySelectionHeader({
    super.key,
    required this.pageComicIds,
    required this.onEditMetadata,
  });

  /// 当前页可见漫画 id，供「全选本页」使用。
  final List<String> pageComicIds;

  /// 批量编辑元数据入口（comic owner 命令）。
  final CatalogSelectionEditMetadataAction onEditMetadata;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CatalogSelectionState selection = ref.watch(catalogSelectionProvider);
    final CatalogSelectionNotifier notifier = ref.read(
      catalogSelectionProvider.notifier,
    );
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool showClear = selection.selectedIds.isNotEmpty;

    return PinnedToolbarChrome(
      child: Row(
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: l10n.catalogSelectionExit,
            onPressed: notifier.exit,
          ),
          TextButton(
            onPressed: showClear
                ? notifier.clearSelection
                : pageComicIds.isEmpty
                ? null
                : () => notifier.selectPage(pageComicIds),
            child: Text(
              showClear
                  ? l10n.catalogSelectionClear
                  : l10n.catalogSelectionSelectPage,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.catalogSelectionEditMetadata,
            onPressed: selection.count == 0
                ? null
                : () => onEditMetadata(
                    context,
                    ref,
                    selection.selectedIds.toList(growable: false),
                  ),
          ),
          const Spacer(),
          Text(
            l10n.catalogSelectionSelectedCount(selection.count),
            style: textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}
