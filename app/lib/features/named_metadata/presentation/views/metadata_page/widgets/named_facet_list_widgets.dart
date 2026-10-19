part of 'named_facet_management_panel.dart';

// 名称列表区（列表容器、单项 chip、列表头与尾部）：#312 part 拆分。
class _NamedFacetListSection extends ConsumerWidget {
  const _NamedFacetListSection({
    required this.kind,
    required this.layoutTier,
    required this.state,
    this.mergeTarget,
    required this.mergeSources,
    this.onMergeTargetSelected,
    this.onMergeSourceSelected,
    this.onMergeSelectionExited,
  });

  final ManagedNamedFacetKind kind;
  final MetadataLayoutTier layoutTier;
  final NamedFacetManagementState state;
  final String? mergeTarget;
  final Set<String> mergeSources;
  final ValueChanged<String>? onMergeTargetSelected;
  final ValueChanged<String>? onMergeSourceSelected;
  final VoidCallback? onMergeSelectionExited;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _NamedFacetListHeader(
          kind: kind,
          layoutTier: layoutTier,
          totalCount: state.totalCount,
        ),
        SizedBox(height: tokens.spacing.md),
        Wrap(
          spacing: tokens.spacing.sm,
          runSpacing: tokens.spacing.sm,
          children: state.items
              .map(
                (String item) => _ManagedNamedFacetChip(
                  kind: kind,
                  name: item,
                  attachmentCount: state.attachmentCounts[item],
                  mergeTarget: mergeTarget,
                  isMergeSource: mergeSources.contains(item),
                  onMergeTargetSelected: onMergeTargetSelected,
                  onMergeSourceSelected: onMergeSourceSelected,
                  onMergeSelectionExited: onMergeSelectionExited,
                ),
              )
              .toList(),
        ),
        if (state.error != null) ...<Widget>[
          SizedBox(height: tokens.spacing.md),
          Text(
            '${state.error}',
            style: TextStyle(fontSize: tokens.text.labelXs, color: cs.error),
          ),
        ],
        SizedBox(height: tokens.spacing.lg),
        _NamedFacetListFooter(kind: kind, state: state),
      ],
    );
  }
}

class _ManagedNamedFacetChip extends ConsumerWidget {
  const _ManagedNamedFacetChip({
    required this.kind,
    required this.name,
    required this.attachmentCount,
    this.mergeTarget,
    this.isMergeSource = false,
    this.onMergeTargetSelected,
    this.onMergeSourceSelected,
    this.onMergeSelectionExited,
  });

  final ManagedNamedFacetKind kind;
  final String name;
  final int? attachmentCount;
  final String? mergeTarget;
  final bool isMergeSource;
  final ValueChanged<String>? onMergeTargetSelected;
  final ValueChanged<String>? onMergeSourceSelected;
  final VoidCallback? onMergeSelectionExited;

  bool _isDesktop(BuildContext context) {
    return switch (Theme.of(context).platform) {
      TargetPlatform.windows ||
      TargetPlatform.linux ||
      TargetPlatform.macOS => true,
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.fuchsia => false,
    };
  }

  void _showMenu(BuildContext context, WidgetRef ref, Offset position) {
    NamedFacetContextMenu.show(
      context,
      position: position,
      mergeEnabled: kind != ManagedNamedFacetKind.author,
      onAction: (NamedFacetContextAction action) {
        switch (action) {
          case NamedFacetContextAction.rename:
            unawaited(_renameNamedFacet(context, ref, kind, name));
          case NamedFacetContextAction.merge:
            onMergeTargetSelected?.call(name);
          case NamedFacetContextAction.delete:
            unawaited(_deleteNamedFacet(context, ref, kind, name));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isAuthor = kind == ManagedNamedFacetKind.author;
    final bool desktop = _isDesktop(context);
    final bool isMergeTarget = mergeTarget == name;
    final ({Color? fill, Color? border}) selection = _mergeSelectionColors(
      context.hentai,
      isMergeTarget: isMergeTarget,
      isMergeSource: isMergeSource,
    );
    return OutlinedMetaChip(
      text: name,
      compact: true,
      backgroundColor: selection.fill,
      borderColor: selection.border,
      count: isAuthor ? null : attachmentCount,
      verified:
          isAuthor &&
          ref
              .watch(allAuthorsProvider)
              .maybeWhen(
                data: (List<Author> authors) => authors.any(
                  (Author author) => author.name == name && author.verified,
                ),
                orElse: () => false,
              ),
      onTap: isAuthor
          ? () {
              unawaited(
                ref.read(authorDetailPortProvider).showByName(context, name),
              );
            }
          : mergeTarget != null
          ? () => _onMergeChipTap(
              name: name,
              isMergeTarget: isMergeTarget,
              onExit: onMergeSelectionExited,
              onSource: onMergeSourceSelected,
            )
          : null,
      onLongPress: isAuthor || desktop || mergeTarget != null
          ? null
          : () {
              final RenderBox box = context.findRenderObject()! as RenderBox;
              _showMenu(context, ref, box.localToGlobal(Offset.zero));
            },
      onSecondaryTapUp: isAuthor || !desktop || mergeTarget != null
          ? null
          : (TapUpDetails details) =>
                _showMenu(context, ref, details.globalPosition),
    );
  }
}

class _NamedFacetListHeader extends StatelessWidget {
  const _NamedFacetListHeader({
    required this.kind,
    required this.layoutTier,
    required this.totalCount,
  });

  final ManagedNamedFacetKind kind;
  final MetadataLayoutTier layoutTier;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final l10n = context.l10n;
    final bool showTotalCount = metadataListHeaderShowsTotalCount(layoutTier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(_iconForKind(kind), size: 16, color: cs.onSurfaceVariant),
            SizedBox(width: tokens.spacing.sm),
            Expanded(
              child: Text(
                l10n.metadataListTitle(kind),
                style: TextStyle(
                  fontSize: tokens.text.bodySm,
                  fontWeight: FontWeight.w600,
                  color: context.hentai.textSecondary,
                ),
              ),
            ),
            if (showTotalCount)
              CountDigitChip(
                count: totalCount,
                semanticLabel: l10n.metadataTotalCount(totalCount),
              ),
          ],
        ),
        SizedBox(height: tokens.spacing.sm),
        Divider(height: 1, thickness: 1, color: context.hentai.borderSubtle),
      ],
    );
  }
}

class _NamedFacetListFooter extends ConsumerWidget {
  const _NamedFacetListFooter({required this.kind, required this.state});

  final ManagedNamedFacetKind kind;
  final NamedFacetManagementState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeTokens tokens = context.tokens;
    final l10n = context.l10n;
    final TextStyle footerStyle = TextStyle(
      fontSize: tokens.text.labelXs,
      color: context.hentai.textTertiary,
    );

    if (state.hasSearchQuery) {
      return Text(
        l10n.metadataTotalCount(state.items.length),
        textAlign: TextAlign.center,
        style: footerStyle,
      );
    }

    if (state.isLoadingMore) {
      return Text(
        l10n.metadataLoadingMore,
        textAlign: TextAlign.center,
        style: footerStyle,
      );
    }

    if (!state.hasMore) {
      return Text(
        l10n.metadataListEnd,
        textAlign: TextAlign.center,
        style: footerStyle,
      );
    }

    return Center(
      child: GhostButton.iconText(
        icon: LucideIcons.chevronDown,
        text: l10n.metadataLoadMore,
        onPressed: () => ref
            .read(namedFacetManagementControllerProvider(kind).notifier)
            .loadMore(),
      ),
    );
  }
}
