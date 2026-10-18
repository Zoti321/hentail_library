part of 'library_page_widgets.dart';

// 库页显示目标切换（系列 / 漫画标签页与底栏）：#311 part 拆分。
class LibraryDisplayTargetTabs extends ConsumerWidget {
  const LibraryDisplayTargetTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryPageFacadeProvider.select(
        (LibraryPageFacadeState state) => state.displayTarget,
      ),
    );
    final LibraryPageFacadeNotifier facade = ref.read(
      libraryPageFacadeProvider.notifier,
    );
    final AppLocalizations l10n = context.l10n;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _UnderlineTab(
          label: l10n.libraryTabComics,
          isSelected: displayTarget == LibraryDisplayTarget.comics,
          onTap: () => facade.selectDisplayTarget(LibraryDisplayTarget.comics),
        ),
        const SizedBox(width: 16),
        _UnderlineTab(
          label: l10n.libraryTabSeries,
          isSelected: displayTarget == LibraryDisplayTarget.series,
          onTap: () => facade.selectDisplayTarget(LibraryDisplayTarget.series),
        ),
      ],
    );
  }
}

class LibraryDisplayTargetBottomBar extends ConsumerWidget {
  const LibraryDisplayTargetBottomBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryPageFacadeProvider.select(
        (LibraryPageFacadeState state) => state.displayTarget,
      ),
    );
    final AppLocalizations l10n = context.l10n;
    return ContentSwitcherBottomBar(
      items: <ContentSwitcherBottomBarItem>[
        (icon: LucideIcons.bookImage, label: l10n.libraryTabComics),
        (icon: LucideIcons.bookMarked, label: l10n.libraryTabSeries),
      ],
      selectedIndex: displayTarget == LibraryDisplayTarget.comics ? 0 : 1,
      onSelected: (int index) {
        ref
            .read(libraryPageFacadeProvider.notifier)
            .selectDisplayTarget(
              index == 0
                  ? LibraryDisplayTarget.comics
                  : LibraryDisplayTarget.series,
            );
      },
    );
  }
}

class _UnderlineTab extends StatelessWidget {
  const _UnderlineTab({
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      splashFactory: NoSplash.splashFactory,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? cs.primary : cs.hentai.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 2,
              width: label.length * 14.0,
              decoration: BoxDecoration(
                color: isSelected ? cs.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
