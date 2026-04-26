part of 'library_page_widgets.dart';

class LibrarySearchToolbarRow extends ConsumerStatefulWidget {
  const LibrarySearchToolbarRow({super.key});

  @override
  ConsumerState<LibrarySearchToolbarRow> createState() =>
      _LibrarySearchToolbarRowState();
}

class _LibrarySearchToolbarRowState
    extends ConsumerState<LibrarySearchToolbarRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.25,
          ),
          child: CustomTextField(
            controller: _controller,
            hintText: '搜索…',
            onSubmitted: _handleSubmitSearch,
          ),
        ),
        const Spacer(),
        const _LibraryToolbar(),
      ],
    );
  }

  void _handleSubmitSearch(String value) {
    final String query = value.trim();
    if (query.isEmpty) {
      showInfoToast(context, '关键词不能为空');
      return;
    }
    final String encodedQuery = Uri.encodeQueryComponent(query);
    appRouter.go('/searched?q=$encodedQuery');
  }
}

class _LibraryToolbar extends ConsumerWidget {
  const _LibraryToolbar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final bool isGridView = ref.watch(libraryIsGridViewProvider);
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.borderSubtle),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          GhostButton.icon(
            icon: LucideIcons.rotateCw,
            tooltip: '刷新',
            semanticLabel: '刷新',
            iconSize: 16,
            size: 28,
            borderRadius: 6,
            foregroundColor: cs.iconDefault,
            hoverColor: theme.hoverColor,
            overlayColor: theme.hoverColor,
            delayTooltipThreeSeconds: true,
            onPressed: () {
              ref.read(libraryRefreshActionProvider).call();
            },
          ),
          const SizedBox(width: 8),
          const FilterPopupButton(),
          const SizedBox(width: 8),
          const SortPopupButton(),
          const SizedBox(width: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              color: cs.borderSubtle,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const SizedBox(width: 1, height: 22),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              _ViewToggleButton(
                icon: LucideIcons.layoutGrid,
                isActive: isGridView,
                onTap: () => ref
                    .read(libraryQueryIntentProvider.notifier)
                    .setIsGridView(true),
                activeColor: theme.colorScheme.primary,
              ),
              const SizedBox(width: 4),
              _ViewToggleButton(
                icon: LucideIcons.list,
                isActive: !isGridView,
                onTap: () => ref
                    .read(libraryQueryIntentProvider.notifier)
                    .setIsGridView(false),
                activeColor: theme.colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ViewToggleButton extends StatelessWidget {
  const _ViewToggleButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.activeColor,
  });
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: theme.hoverColor,
        splashFactory: NoSplash.splashFactory,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isActive ? cs.subtleTagBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? cs.borderSubtle : Colors.transparent,
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isActive ? activeColor : cs.iconSecondary,
          ),
        ),
      ),
    );
  }
}
