import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/core/util/shell_file_explorer.dart';
import 'package:hentai_library/features/library_browse/presentation/integrations/comic_presentation_bridge.dart';
import 'package:hentai_library/features/library_browse/presentation/catalog/views/metadata_edit/metadata_edit_presenters.dart';
import 'package:hentai_library/shared/ui/widgets/menu/anchored_menu.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/app_snackbar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 包裹 MD3E 漫画卡片：仅桌面端鼠标右键弹出 [M3EMenu]（与详情页顶栏 ⋮ 同款
/// 宽度与样式：阅读、编辑元数据、在资源管理器中显示、删除）；移动端无上下文菜单。
class ComicCardActions extends ConsumerWidget {
  const ComicCardActions({
    super.key,
    required this.comic,
    required this.child,
    this.enabled = true,
  });

  final Comic comic;
  final Widget child;

  /// 选择模式下设为 false，桌面端右键不弹出操作菜单。
  final bool enabled;

  static bool _isDesktop(BuildContext context) {
    return switch (Theme.of(context).platform) {
      TargetPlatform.windows ||
      TargetPlatform.linux ||
      TargetPlatform.macOS => true,
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.fuchsia => false,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!enabled || !_isDesktop(context)) {
      return child;
    }
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onSecondaryTapUp: (TapUpDetails details) {
        _showMenu(context, ref, details.globalPosition);
      },
      child: child,
    );
  }

  void _showMenu(BuildContext context, WidgetRef ref, Offset globalPosition) {
    final AppLocalizations l10n = context.l10n;
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    showPointerContextMenu<void>(
      context: context,
      globalPosition: globalPosition,
      children: <M3EMenuNode>[
        M3EMenuEntry(
          label: l10n.comicDetailRead,
          leading: const Icon(LucideIcons.bookOpen),
          onPressed: () => ComicCardHost.openReader(ref, comic.comicId),
        ),
        M3EMenuEntry(
          label: l10n.comicDetailEditMetadata,
          leading: const Icon(LucideIcons.squarePen),
          onPressed: () =>
              showComicMetadataEdit(context: context, comic: comic),
        ),
        M3EMenuEntry(
          label: l10n.comicDetailShowInExplorer,
          leading: const Icon(LucideIcons.folderOpen),
          onPressed: () => _showInExplorer(context, comic),
        ),
        M3EMenuEntry(
          label: l10n.comicDetailDelete,
          leading: Icon(LucideIcons.trash2, color: scheme.error),
          isDestructive: true,
          onPressed: () => ComicCardHost.confirmTrash(context, ref, comic),
        ),
      ],
    );
  }

  Future<void> _showInExplorer(BuildContext context, Comic comic) async {
    try {
      await showInFileExplorer(comic.path);
    } on Object catch (error, stackTrace) {
      debugPrint('showInFileExplorer failed for "${comic.path}": $error');
      if (!context.mounted) {
        return;
      }
      final AppException failure = error is AppException
          ? error
          : AppException(
              context.l10n.comicDetailShowInExplorerFailed,
              cause: error,
              stackTrace: stackTrace,
            );
      showErrorSnackbar(context, failure);
    }
  }
}
