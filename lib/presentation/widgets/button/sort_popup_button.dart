import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/config/app_fluent_color_scheme.dart';
import 'package:hentai_library/domain/value_objects/v2/library_comic_sort_option.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SortPopupButton extends StatefulHookConsumerWidget {
  const SortPopupButton({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _SortPopupButtonState();
}

class _SortPopupButtonState extends ConsumerState<SortPopupButton> {
  final CustomPopupMenuController _controller = CustomPopupMenuController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomPopupMenu(
      controller: _controller,
      barrierColor: Colors.transparent,
      pressType: PressType.singleClick,
      showArrow: false,
      verticalMargin: -16,
      menuBuilder: () => _SortMenu(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _controller.showMenu(),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(6),
            child: Icon(
              LucideIcons.arrowDownWideNarrow,
              size: 16,
              color: theme.colorScheme.iconDefault,
            ),
          ),
        ),
      ),
    );
  }
}

class _SortMenu extends HookConsumerWidget {
  const _SortMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final sortOption = ref.watch(comicSortOptionProvider);

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 24,
            children: [
              // header
              Row(
                children: [
                  Icon(
                    Icons.swap_vert,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "排序与视图",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.textPrimary,
                    ),
                  ),
                  Spacer(),
                  Material(
                    color: theme.colorScheme.inputBackgroundDisabled,
                    borderRadius: BorderRadius.circular(6),
                    child: InkWell(
                      onTap: () {
                        ref.read(comicSortOptionProvider.notifier).reset();
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          "重置",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // body
              _SortSection(option: sortOption),
            ],
          ),
        ),
      ),
    );
  }
}

class _SortSection extends HookConsumerWidget {
  const _SortSection({required this.option});

  final LibraryComicSortOption option;

  bool get isAsc => !option.descending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '主要规则',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 0.5,
              ),
            ),
            Material(
              color: isAsc ? Colors.blue.shade50 : Colors.orange.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(
                  color: isAsc ? Colors.blue.shade100 : Colors.orange.shade100,
                  width: 1,
                ),
              ),
              child: InkWell(
                onTap: () {
                  ref.read(comicSortOptionProvider.notifier).toggleDescenging(
                        !option.descending,
                      );
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 4,
                    children: [
                      Icon(
                        isAsc ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12,
                        color: isAsc
                            ? Colors.blue.shade600
                            : Colors.orange.shade600,
                      ),
                      Text(
                        isAsc ? "升序" : "降序",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isAsc
                              ? Colors.blue.shade600
                              : Colors.orange.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        Row(
          spacing: 8,
          children: [
            Flexible(
              child: _SortOption(
                key: Key(LibraryComicSortField.title.toString()),
                field: LibraryComicSortField.title,
                label: "标题",
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SortOption extends HookConsumerWidget {
  const _SortOption({super.key, required this.field, required this.label});

  final LibraryComicSortField field;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    final isSelected = ref.watch(comicSortOptionProvider).field == field;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primary : colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? colorScheme.primary : colorScheme.borderSubtle,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => {
            ref.read(comicSortOptionProvider.notifier).updateSortField(field),
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.textTertiary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
