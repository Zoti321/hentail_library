import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/data/adapters/reader_frb_mapper.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_controller.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_floating_panel.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hentai_library/ui/providers/comic_cover_providers.dart';
import 'package:hentai_library/ui/providers/series_cover_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ReaderOverflowMenuButton extends HookConsumerWidget {
  const ReaderOverflowMenuButton({
    super.key,
    required this.comicId,
    this.seriesId,
    this.incognito = false,
  });

  final String comicId;
  final String? seriesId;
  final bool incognito;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final CustomPopupMenuController menuController = useMemoized(
      CustomPopupMenuController.new,
    );
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool isSeriesRead = seriesId != null && seriesId!.trim().isNotEmpty;

    return CustomPopupMenu(
      controller: menuController,
      barrierColor: Colors.transparent,
      pressType: PressType.singleClick,
      showArrow: false,
      verticalMargin: -14,
      menuBuilder: () => ReaderFloatingMenuPanel(
        width: 240,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _ReaderOverflowMenuItem(
              icon: LucideIcons.image,
              label: l10n.readerSetComicCover,
              onTap: () {
                menuController.hideMenu();
                _setComicCover(context, ref, l10n);
              },
            ),
            if (isSeriesRead)
              _ReaderOverflowMenuItem(
                icon: LucideIcons.images,
                label: l10n.readerSetSeriesCover,
                onTap: () {
                  menuController.hideMenu();
                  _setSeriesCover(context, ref, l10n);
                },
              ),
          ],
        ),
      ),
      child: GhostButton.icon(
        icon: LucideIcons.ellipsisVertical,
        tooltip: l10n.readerMore,
        semanticLabel: l10n.readerMoreSemantic,
        iconSize: 16,
        size: 32,
        borderRadius: 8,
        foregroundColor: cs.hentai.readerTextIconPrimary,
        hoverColor: cs.hentai.readerPanelSubtle,
        overlayColor: cs.hentai.readerPanelSubtle,
        onPressed: () => menuController.toggleMenu(),
      ),
    );
  }

  Future<void> _setComicCover(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final ReaderState? state = _readerState(ref);
    if (state == null) {
      if (context.mounted) {
        showCustomToast(context, message: l10n.readerStateNotReady);
      }
      return;
    }
    try {
      final Comic comic = state.comic;
      final int pageIndex = (state.currentIndex - 1).clamp(0, 1 << 30);
      await ref
          .read(comicThumbnailRepoProvider)
          .setComicCoverFromPage(
            comicId: comic.comicId,
            path: comic.path,
            resourceType: mapResourceType(comic.resourceType),
            pageIndex: pageIndex,
          );
      final bytes =
          (await ref
                  .read(comicThumbnailRepoProvider)
                  .findByComicId(comic.comicId))
              ?.thumbnail;
      if (bytes != null && bytes.isNotEmpty) {
        ref.read(comicCoverProvider(comic.comicId).notifier).setReady(bytes);
      }
      if (context.mounted) {
        showCustomToast(context, message: l10n.readerComicCoverSet);
      }
    } on Object catch (error) {
      if (context.mounted) {
        showCustomToast(
          context,
          message: l10n.readerComicCoverSetFailed('$error'),
        );
      }
    }
  }

  Future<void> _setSeriesCover(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final String? sid = seriesId?.trim();
    if (sid == null || sid.isEmpty) {
      return;
    }
    final ReaderState? state = _readerState(ref);
    if (state == null) {
      if (context.mounted) {
        showCustomToast(context, message: l10n.readerStateNotReady);
      }
      return;
    }
    try {
      final Comic comic = state.comic;
      final int pageIndex = (state.currentIndex - 1).clamp(0, 1 << 30);
      await ref
          .read(comicThumbnailRepoProvider)
          .setSeriesCoverFromPage(
            seriesId: sid,
            comicId: comic.comicId,
            path: comic.path,
            resourceType: mapResourceType(comic.resourceType),
            pageIndex: pageIndex,
          );
      ref.invalidate(seriesCoverSourceProvider(sid));
      if (context.mounted) {
        showCustomToast(context, message: l10n.readerSeriesCoverSet);
      }
    } on Object catch (error) {
      if (context.mounted) {
        showCustomToast(
          context,
          message: l10n.readerSeriesCoverSetFailed('$error'),
        );
      }
    }
  }

  ReaderState? _readerState(WidgetRef ref) {
    return ref
        .read(
          readerControllerProvider(
            readerControllerKey(comicId, incognito: incognito),
          ),
        )
        .asData
        ?.value;
  }
}

class _ReaderOverflowMenuItem extends StatelessWidget {
  const _ReaderOverflowMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            spacing: 10,
            children: <Widget>[
              Icon(icon, size: 16, color: cs.hentai.readerTextIconPrimary),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.hentai.readerTextIconPrimary,
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
