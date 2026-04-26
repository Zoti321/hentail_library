import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/theme/theme.dart';
import 'package:hentai_library/domain/value_objects/library_display_target.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/actions/ghost_button.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/actions/popup_menu_panel_shell.dart';
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
        foregroundColor: cs.iconDefault,
        hoverColor: Theme.of(context).hoverColor,
        overlayColor: Theme.of(context).hoverColor,
        delayTooltipThreeSeconds: true,
        onPressed: () => controller.toggleMenu(),
      ),
    );
  }
}

class _FilterMenu extends HookConsumerWidget {
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
      LibraryDisplayTarget.all => displayedComicCount + displayedSeriesCount,
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
                bottom: BorderSide(color: colorScheme.borderSubtle),
              ),
            ),
            child: Text(
              '高级筛选',
              style: TextStyle(
                fontSize: context.tokens.text.bodySm,
                fontWeight: FontWeight.w600,
                color: colorScheme.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '显示目标',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _DisplayTargetChip(
                      label: '全部',
                      isSelected: displayTarget == LibraryDisplayTarget.all,
                      onTap: () => ref
                          .read(libraryQueryIntentProvider.notifier)
                          .setDisplayTarget(LibraryDisplayTarget.all),
                    ),
                    const SizedBox(width: 6),
                    _DisplayTargetChip(
                      label: '漫画',
                      isSelected: displayTarget == LibraryDisplayTarget.comics,
                      onTap: () => ref
                          .read(libraryQueryIntentProvider.notifier)
                          .setDisplayTarget(LibraryDisplayTarget.comics),
                    ),
                    const SizedBox(width: 6),
                    _DisplayTargetChip(
                      label: '系列',
                      isSelected: displayTarget == LibraryDisplayTarget.series,
                      onTap: () => ref
                          .read(libraryQueryIntentProvider.notifier)
                          .setDisplayTarget(LibraryDisplayTarget.series),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: colorScheme.borderSubtle),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
            color: colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Text(
                  '$resultCount 个结果',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.textSecondary,
                  ),
                ),
                const Spacer(),
                GhostButton.iconText(
                  icon: LucideIcons.rotateCcw,
                  text: '重置',
                  tooltip: '重置所有筛选',
                  semanticLabel: '重置所有筛选',
                  iconSize: 14,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  borderRadius: 7,
                  foregroundColor: colorScheme.primary,
                  hoverColor: colorScheme.primary.withAlpha(10),
                  overlayColor: colorScheme.primary.withAlpha(14),
                  delayTooltipThreeSeconds: false,
                  onPressed: () {
                    ref.read(libraryQueryIntentProvider.notifier).resetFilter();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DisplayTargetChip extends StatelessWidget {
  const _DisplayTargetChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Material(
        color: isSelected ? cs.primary : cs.surface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? cs.primary : cs.borderSubtle,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? cs.onPrimary : cs.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
