import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/config/app_fluent_color_scheme.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
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
    return CustomPopupMenu(
      controller: controller,
      barrierColor: Colors.transparent,
      pressType: PressType.singleClick,
      showArrow: false,
      verticalMargin: -16,
      menuBuilder: () => _FilterMenu(menuController: controller),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => controller.toggleMenu(),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(6),
            child: Icon(LucideIcons.funnel, size: 16, color: Colors.grey[600]),
          ),
        ),
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

    final resultCount = ref.watch(
      libraryPageProvider.select((s) => s.displayedComics.length),
    );

    return Container(
      width: 256,
      padding: const .all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: .circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: .start,
        mainAxisSize: .min,
        spacing: 16,
        children: [
          // header 菜单标题栏
          Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              const Text(
                "高级筛选",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                onPressed: () {
                  menuController.hideMenu();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(LucideIcons.x, size: 14),
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: Colors.grey.shade400,
                ),
              ),
            ],
          ),

          // body
          Row(
            spacing: 8,
            children: [
              Icon(LucideIcons.funnel, size: 16, color: Colors.grey.shade400),
              Text(
                "显示 R18 内容",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: .w400,
                  color: Colors.black87,
                ),
              ),
              Spacer(),
              MyToggleSwitch(
                checked: ref.watch(
                  libraryPageProvider.select((s) => s.effectiveFilter.showR18),
                ),
                onChange: () =>
                    ref.read(libraryPageProvider.notifier).toggleR18(),
              ),
            ],
          ),
          Divider(thickness: 1, color: colorScheme.borderSubtle),
          // footer 底部操作栏
          Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              Text(
                "$resultCount 个结果",
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              TextButton(
                onPressed: () {
                  ref.read(libraryPageProvider.notifier).resetFilter();
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: colorScheme.primary,
                  disabledForegroundColor: colorScheme.primary.withOpacity(0.5),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                child: const Text("重置所有"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
