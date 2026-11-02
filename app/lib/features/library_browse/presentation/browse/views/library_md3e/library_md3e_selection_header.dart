import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_browse/presentation/catalog/view_models/catalog_selection_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/views/widgets/catalog_selection_actions.dart';
import 'package:hentai_library/shared/ui/patterns/shared/pinned_toolbar_chrome.dart';

/// 库页选择模式页头（MD3E）：替换普通页头；退出 / 全选本页 / 清空 / 批量编辑元数据 / 已选数量。
///
/// 选择状态与批量修改入口复用 [catalogSelectionProvider] 与 [openCatalogSelectionMetadataEditor]。
class Md3eLibrarySelectionHeader extends ConsumerWidget {
  const Md3eLibrarySelectionHeader({super.key, required this.pageComicIds});

  /// 当前页可见漫画 id，供「全选本页」使用。
  final List<String> pageComicIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CatalogSelectionState selection = ref.watch(catalogSelectionProvider);
    final CatalogSelectionNotifier notifier = ref.read(
      catalogSelectionProvider.notifier,
    );
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool showClear = selection.selectedIds.isNotEmpty;

    return Md3ePinnedToolbarChrome(
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
                : () => openCatalogSelectionMetadataEditor(context, ref),
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
