import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/core/util/shell_file_explorer.dart';
import 'package:hentai_library/features/library_browse/presentation/comic_card_host.dart';
import 'package:hentai_library/features/library_browse/presentation/views/widgets/edit_metadata_dialog.dart';
import 'package:hentai_library/md3e/widgets/menu/md3e_anchored_menu.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/custom_toast.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 包裹 MD3E 漫画卡片：右键 / 长按弹出与 Baseline 卡片一致的操作菜单
/// （阅读、编辑元数据、在资源管理器中显示、删除）。
class Md3eComicCardActions extends ConsumerWidget {
  const Md3eComicCardActions({
    super.key,
    required this.comic,
    required this.child,
  });

  final Comic comic;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onSecondaryTapUp: (TapUpDetails details) {
        _showMenu(context, ref, details.globalPosition);
      },
      onLongPressStart: (LongPressStartDetails details) {
        _showMenu(context, ref, details.globalPosition);
      },
      child: child,
    );
  }

  void _showMenu(BuildContext context, WidgetRef ref, Offset globalPosition) {
    final AppLocalizations l10n = context.l10n;
    md3eShowAnchoredMenu<void>(
      context: context,
      anchor: Rect.fromLTWH(globalPosition.dx, globalPosition.dy, 0, 0),
      children: <M3EMenuNode>[
        M3EMenuEntry(
          label: l10n.comicDetailRead,
          onPressed: () => ComicCardHost.openReader(ref, comic.comicId),
        ),
        M3EMenuEntry(
          label: l10n.comicDetailEditMetadata,
          onPressed: () =>
              showEditMetadataDialog(context: context, comic: comic),
        ),
        M3EMenuEntry(
          label: l10n.comicDetailShowInExplorer,
          onPressed: () => _showInExplorer(context, comic),
        ),
        M3EMenuEntry(
          label: l10n.comicDetailDelete,
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
      showErrorToast(context, failure);
    }
  }
}
