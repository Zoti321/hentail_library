import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/domain/value_objects/library_comic_sort_option.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/widgets/button/ghost_button.dart';
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
    final tokens = context.tokens;
    return CustomPopupMenu(
      controller: _controller,
      barrierColor: Colors.transparent,
      pressType: PressType.singleClick,
      showArrow: false,
      verticalMargin: -16,
      menuBuilder: () => _SortMenu(),
      child: GhostButton.icon(
        icon: LucideIcons.arrowDownWideNarrow,
        tooltip: '排序',
        semanticLabel: '打开排序',
        iconSize: 16,
        size: 28,
        borderRadius: tokens.radius.sm,
        foregroundColor: theme.colorScheme.iconDefault,
        hoverColor: theme.hoverColor,
        overlayColor: theme.hoverColor,
        delayTooltipThreeSeconds: true,
        onPressed: () => _controller.showMenu(),
      ),
    );
  }
}

class _SortMenu extends HookConsumerWidget {
  const _SortMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = context.tokens;

    final sortOption = ref.watch(
      libraryPageProvider.select((s) => s.effectiveSortOption),
    );

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(tokens.radius.lg),
        border: Border.all(color: theme.colorScheme.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.cardShadowHover,
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radius.lg),
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
                        ref.read(libraryPageProvider.notifier).resetSortOption();
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
                            color: theme.colorScheme.textSecondary,
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
    final colorScheme = Theme.of(context).colorScheme;
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
                color: colorScheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            Material(
              color: isAsc
                  ? colorScheme.primaryContainer
                  : colorScheme.warning.withAlpha(24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(
                  color: isAsc
                      ? colorScheme.primary.withAlpha(70)
                      : colorScheme.warning.withAlpha(90),
                  width: 1,
                ),
              ),
              child: InkWell(
                onTap: () {
                  ref
                      .read(libraryPageProvider.notifier)
                      .toggleSortDescending(!option.descending);
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 4,
                    children: [
                      Icon(
                        isAsc ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12,
                        color: isAsc
                            ? colorScheme.primary
                            : colorScheme.warning,
                      ),
                      Text(
                        isAsc ? "升序" : "降序",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isAsc
                              ? colorScheme.primary
                              : colorScheme.warning,
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

    final isSelected =
        ref.watch(libraryPageProvider.select((s) => s.effectiveSortOption.field)) ==
        field;

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
            ref.read(libraryPageProvider.notifier).updateSortField(field),
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
