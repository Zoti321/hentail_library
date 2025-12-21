import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/config/app_fluent_color_scheme.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
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

    final resultCount = ref
        .watch(processLibraryComicsProvider)
        .when(
          data: (data) => data.length,
          error: (_, _) => 0,
          loading: () => 0,
          skipLoadingOnRefresh: true,
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
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: ref.watch(comicFilterProvider).showR18,
                  onChanged: (val) {
                    ref.read(comicFilterProvider.notifier).toggleR18(val);
                  },
                  activeColor: Colors.white,
                  activeTrackColor: Colors.red,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.grey.shade300,
                  overlayColor: MaterialStateProperty.all(Colors.transparent),
                  trackOutlineColor: MaterialStateProperty.all(
                    Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
          _BuildChapterCountSection(),
          _BuildFileFormateSection(),

          Divider(thickness: 1, color: colorScheme.borderSubtle),
          // footer 底部操作栏
          Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              Text(
                "$resultCount 个结果",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
              TextButton(
                onPressed: () {},
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

class _BuildChapterCountSection extends ConsumerWidget {
  const _BuildChapterCountSection();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      spacing: 6,
      crossAxisAlignment: .stretch,
      mainAxisSize: .min,
      children: [
        Text(
          "# 章节数量",
          style: TextStyle(
            fontSize: 11,
            fontWeight: .w500,
            color: Colors.grey.shade500,
            letterSpacing: 0.5,
          ),
        ),
        _FilterNumberInput(),
      ],
    );
  }
}

class _BuildFileFormateSection extends ConsumerWidget {
  const _BuildFileFormateSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      spacing: 6,
      crossAxisAlignment: .stretch,
      mainAxisSize: .min,
      children: [
        Text(
          "文件格式",
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        ListView(
          shrinkWrap: true,
          children: <Widget>[
            ImageSourceFormatOption(
              label: "CBZ/CBR",
              isActive: true,
              onTap: () {},
            ),
            ImageSourceFormatOption(
              label: "ZIP",
              isActive: false,
              onTap: () {},
            ),
            ImageSourceFormatOption(
              label: "EPUB",
              isActive: true,
              onTap: () {},
            ),
            ImageSourceFormatOption(label: "文件夹", isActive: true, onTap: () {}),
          ],
        ),
      ],
    );
  }
}

class ImageSourceFormatOption extends HookWidget {
  const ImageSourceFormatOption({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidFunction onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isHover = useState<bool>(false);

    return MouseRegion(
      onEnter: (_) => isHover.value = true,
      onExit: (_) => isHover.value = false,
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const .symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: .circular(8),
            color: isHover.value ? Colors.grey.shade100 : Colors.transparent,
          ),
          child: Row(
            spacing: 8,
            children: [
              Icon(
                isActive ? LucideIcons.squareCheckBig : LucideIcons.square,
                color: isActive
                    ? theme.colorScheme.primary
                    : Colors.grey.shade400,
                size: 14,
              ),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: .normal,
                    color: isActive
                        ? theme.colorScheme.primary
                        : Colors.grey.shade700,
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

class _FilterNumberInput extends HookWidget {
  const _FilterNumberInput();

  @override
  Widget build(BuildContext context) {
    final useNumber = useState<int>(1);

    return Container(
      padding: const .all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: .spaceBetween,
        children: [
          Padding(
            padding: .only(left: 4),
            child: Text(
              "最少章节",
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
          ),
          Row(
            mainAxisSize: .min,
            spacing: 16,
            children: [
              _buildNumberOprationBtn(context, LucideIcons.minus, () {
                if (useNumber.value > 1) {
                  useNumber.value--;
                }
              }),
              SizedBox(
                width: 24,
                child: Text(
                  useNumber.value.toString(),
                  textAlign: .center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              _buildNumberOprationBtn(context, LucideIcons.plus, () {
                useNumber.value++;
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberOprationBtn(
    BuildContext context,
    IconData icon,
    VoidCallback onTap,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          padding: .all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: .circular(6),
            border: Border.all(width: 1, color: Colors.grey.shade200),
          ),
          child: Icon(icon, size: 12, color: Colors.grey.shade600),
        ),
      ),
    );
  }
}
