import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/widgets/actions/popup_menu_panel_shell.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class FilterPopupButton extends ConsumerStatefulWidget {
  const FilterPopupButton({super.key});

  @override
  ConsumerState<FilterPopupButton> createState() => _FilterPopupButtonState();
}

class _FilterPopupButtonState extends ConsumerState<FilterPopupButton> {
  final CustomPopupMenuController controller = CustomPopupMenuController();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return CustomPopupMenu(
      controller: controller,
      barrierColor: Colors.transparent,
      pressType: PressType.singleClick,
      showArrow: false,
      verticalMargin: -16,
      menuBuilder: () => _FilterMenu(menuController: controller),
      child: GhostButton.icon(
        icon: LucideIcons.funnel,
        tooltip: '筛选',
        semanticLabel: '打开筛选',
        iconSize: 16,
        size: 28,
        borderRadius: 6,
        foregroundColor: cs.hentai.iconDefault,
        hoverColor: Theme.of(context).hoverColor,
        overlayColor: Theme.of(context).hoverColor,
        delayTooltipThreeSeconds: true,
        onPressed: () => controller.toggleMenu(),
      ),
    );
  }
}

class _FilterMenu extends ConsumerWidget {
  const _FilterMenu({required this.menuController});

  final CustomPopupMenuController menuController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final int displayedComicCount = ref.watch(
      libraryDisplayedComicCountProvider,
    );
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryDisplayTargetProvider,
    );
    final int displayedSeriesCount = ref.watch(
      librarySeriesViewDataProvider.select(
        (LibrarySeriesViewData data) => data.seriesWithItemsCount,
      ),
    );
    final int resultCount = switch (displayTarget) {
      LibraryDisplayTarget.comics => displayedComicCount,
      LibraryDisplayTarget.series => displayedSeriesCount,
    };

    return PopupMenuPanelShell(
      width: 256,
      blurRadius: 4,
      shadowOffset: const Offset(0, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(color: colorScheme.hentai.borderSubtle),
              ),
            ),
            child: Text(
              '高级筛选',
              style: TextStyle(
                fontSize: context.tokens.text.bodySm,
                fontWeight: FontWeight.w600,
                color: colorScheme.hentai.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            color: colorScheme.surfaceContainerHighest,
            child: Text(
              '$resultCount 个结果',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.hentai.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
