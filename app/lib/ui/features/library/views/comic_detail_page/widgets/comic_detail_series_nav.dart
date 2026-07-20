import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/core/logging/app_log.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/widgets/actions/popup_menu_panel_shell.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/features/library/view_models/comic_detail_series_nav_provider.dart';
import 'package:hentai_library/ui/features/shell/state/library_series_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const double kComicDetailSeriesMenuWidth = 320;
const double kComicDetailSeriesMenuMaxHeight = 360;
const double kComicDetailSeriesNavPlaceholderWidth = 104;
const double kComicDetailSeriesNavPlaceholderHeight = 32;

void goToComicDetailPage(BuildContext context, String comicId) {
  final String encoded = Uri.encodeComponent(comicId);
  context.go('/comic/$encoded');
}

class ComicDetailSeriesNav extends ConsumerStatefulWidget {
  const ComicDetailSeriesNav({super.key, required this.comicId});

  final String comicId;

  @override
  ConsumerState<ComicDetailSeriesNav> createState() =>
      _ComicDetailSeriesNavState();
}

class _ComicDetailSeriesNavState extends ConsumerState<ComicDetailSeriesNav> {
  final CustomPopupMenuController _menuController = CustomPopupMenuController();

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<Series>>>(allSeriesProvider, (
      AsyncValue<List<Series>>? previous,
      AsyncValue<List<Series>> next,
    ) {
      final List<Series>? allSeries = next.asData?.value;
      if (allSeries == null) {
        return;
      }
      final List<Series> matches = findSeriesListContainingComic(
        allSeries,
        widget.comicId,
      );
      if (matches.length <= 1) {
        return;
      }
      final List<Series>? previousSeries = previous?.asData?.value;
      if (previousSeries != null) {
        final List<Series> previousMatches = findSeriesListContainingComic(
          previousSeries,
          widget.comicId,
        );
        if (previousMatches.length > 1) {
          return;
        }
      }
      final String seriesList = matches.map((Series s) => s.name).join('、');
      AppLog.ui(
        'comic_detail',
      ).warning('漫画详情系列导航冲突：comicId=${widget.comicId}，系列=[$seriesList]');
      if (!context.mounted) {
        return;
      }
      showErrorToast(
        context,
        AppException(context.l10n.comicDetailSeriesNavConflict),
      );
    });

    final AsyncValue<List<Series>> allSeriesAsync = ref.watch(
      allSeriesProvider,
    );
    return allSeriesAsync.when(
      data: (List<Series> allSeries) => _buildForSeriesList(allSeries),
      loading: () => const _ComicDetailSeriesNavPlaceholder(),
      error: (Object _, StackTrace _) => const SizedBox.shrink(),
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
    );
  }

  Widget _buildForSeriesList(List<Series> allSeries) {
    final List<Series> matches = findSeriesListContainingComic(
      allSeries,
      widget.comicId,
    );
    if (matches.isEmpty || matches.length > 1) {
      return const SizedBox.shrink();
    }

    final AsyncValue<ComicDetailSeriesNavSeriesData?> seriesNavAsync = ref
        .watch(comicDetailSeriesNavForSeriesProvider(matches.single.id));
    return seriesNavAsync.when(
      data: (ComicDetailSeriesNavSeriesData? seriesData) {
        if (seriesData == null) {
          return const SizedBox.shrink();
        }
        final int currentIndex = seriesData.items.indexWhere(
          (ComicDetailSeriesNavItem item) => item.comicId == widget.comicId,
        );
        if (currentIndex < 0) {
          return const SizedBox.shrink();
        }
        return _ComicDetailSeriesNavControls(
          data: ComicDetailSeriesNavData(
            seriesId: seriesData.seriesId,
            seriesName: seriesData.seriesName,
            items: seriesData.items,
            currentIndex: currentIndex,
          ),
          menuController: _menuController,
        );
      },
      loading: () => const _ComicDetailSeriesNavPlaceholder(),
      error: (Object _, StackTrace _) => const SizedBox.shrink(),
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
    );
  }
}

class _ComicDetailSeriesNavPlaceholder extends StatelessWidget {
  const _ComicDetailSeriesNavPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: kComicDetailSeriesNavPlaceholderWidth,
      height: kComicDetailSeriesNavPlaceholderHeight,
    );
  }
}

class _ComicDetailSeriesNavControls extends StatelessWidget {
  const _ComicDetailSeriesNavControls({
    required this.data,
    required this.menuController,
  });

  final ComicDetailSeriesNavData data;
  final CustomPopupMenuController menuController;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ThemeData theme = Theme.of(context);
    final ComicDetailSeriesNavItem? previous = data.previousItem;
    final ComicDetailSeriesNavItem? next = data.nextItem;
    final AppLocalizations l10n = context.l10n;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: <Widget>[
        GhostButton.icon(
          icon: LucideIcons.chevronLeft,
          tooltip: l10n.comicDetailSeriesPrev,
          semanticLabel: l10n.comicDetailSeriesPrevSemantic,
          iconSize: 16,
          size: 32,
          borderRadius: 8,
          foregroundColor: cs.hentai.iconDefault,
          hoverColor: theme.hoverColor,
          overlayColor: theme.hoverColor,
          onPressed: previous == null
              ? null
              : () => goToComicDetailPage(context, previous.comicId),
        ),
        CustomPopupMenu(
          controller: menuController,
          barrierColor: Colors.transparent,
          pressType: PressType.longPress,
          showArrow: false,
          verticalMargin: -32,
          menuBuilder: () => _ComicDetailSeriesMenu(
            data: data,
            onSelect: (String targetComicId) {
              menuController.hideMenu();
              if (targetComicId == data.items[data.currentIndex].comicId) {
                return;
              }
              goToComicDetailPage(context, targetComicId);
            },
          ),
          child: GhostButton.icon(
            icon: LucideIcons.menu,
            tooltip: l10n.comicDetailSeriesCatalog,
            semanticLabel: l10n.comicDetailSeriesCatalog,
            iconSize: 16,
            size: 32,
            borderRadius: 8,
            foregroundColor: cs.hentai.iconDefault,
            hoverColor: theme.hoverColor,
            overlayColor: theme.hoverColor,
            onPressed: () => menuController.toggleMenu(),
          ),
        ),
        GhostButton.icon(
          icon: LucideIcons.chevronRight,
          tooltip: l10n.comicDetailSeriesNext,
          semanticLabel: l10n.comicDetailSeriesNextSemantic,
          iconSize: 16,
          size: 32,
          borderRadius: 8,
          foregroundColor: cs.hentai.iconDefault,
          hoverColor: theme.hoverColor,
          overlayColor: theme.hoverColor,
          onPressed: next == null
              ? null
              : () => goToComicDetailPage(context, next.comicId),
        ),
      ],
    );
  }
}

class _ComicDetailSeriesMenu extends StatelessWidget {
  const _ComicDetailSeriesMenu({required this.data, required this.onSelect});

  final ComicDetailSeriesNavData data;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    return PopupMenuPanelShell(
      width: kComicDetailSeriesMenuWidth,
      blurRadius: 6,
      shadowOffset: const Offset(0, 4),
      borderRadius: tokens.radius.xs,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: kComicDetailSeriesMenuMaxHeight,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: data.items
                .map(
                  (ComicDetailSeriesNavItem item) => _ComicDetailSeriesMenuItem(
                    item: item,
                    isCurrent:
                        item.comicId == data.items[data.currentIndex].comicId,
                    onTap: () => onSelect(item.comicId),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _ComicDetailSeriesMenuItem extends StatelessWidget {
  const _ComicDetailSeriesMenuItem({
    required this.item,
    required this.isCurrent,
    required this.onTap,
  });

  final ComicDetailSeriesNavItem item;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final TextStyle textStyle = TextStyle(
      fontSize: tokens.text.bodySm,
      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
      color: isCurrent ? cs.primary : cs.hentai.textPrimary,
      height: 1.35,
    );
    final Widget label = Text(
      item.menuLabel,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: textStyle,
    );
    return Material(
      color: isCurrent ? cs.primary.withAlpha(14) : Colors.transparent,
      child: InkWell(
        onTap: isCurrent ? null : onTap,
        hoverColor: isCurrent ? Colors.transparent : cs.primary.withAlpha(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Tooltip(
            message: item.menuLabel,
            waitDuration: const Duration(milliseconds: 500),
            child: label,
          ),
        ),
      ),
    );
  }
}
