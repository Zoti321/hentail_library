import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/widgets/button/ghost_button.dart';
import 'package:hentai_library/presentation/widgets/my_toggle_switch.dart';
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
    final tokens = context.tokens;

    final resultCount = ref.watch(
      libraryPageProvider.select((s) => s.displayedComics.length),
    );

    return Container(
      width: 256,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(tokens.radius.lg),
        border: Border.all(color: colorScheme.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: colorScheme.cardShadowHover,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radius.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                border: Border(
                  bottom: BorderSide(color: colorScheme.borderSubtle),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '高级筛选',
                    style: TextStyle(
                      fontSize: tokens.text.bodySm,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.textPrimary,
                    ),
                  ),
                  GhostButton.icon(
                    icon: LucideIcons.x,
                    tooltip: '关闭',
                    semanticLabel: '关闭筛选面板',
                    iconSize: 14,
                    size: 26,
                    borderRadius: 7,
                    foregroundColor: colorScheme.iconSecondary,
                    hoverColor: colorScheme.primary.withAlpha(10),
                    overlayColor: colorScheme.primary.withAlpha(14),
                    delayTooltipThreeSeconds: false,
                    onPressed: menuController.hideMenu,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.funnel,
                    size: 15,
                    color: colorScheme.iconSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '显示 R18 内容',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  MyToggleSwitch(
                    checked: ref.watch(
                      libraryPageProvider.select((s) => s.effectiveFilter.showR18),
                    ),
                    onChange: () =>
                        ref.read(libraryPageProvider.notifier).toggleR18(),
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
                      ref.read(libraryPageProvider.notifier).resetFilter();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
