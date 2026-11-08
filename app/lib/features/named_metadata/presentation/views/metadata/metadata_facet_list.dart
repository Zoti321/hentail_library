import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/named_metadata/presentation/view_models/author_management_notifier.dart';
import 'package:hentai_library/features/named_metadata/presentation/view_models/named_facet_management_view_model.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata/metadata_facet_chips.dart';
import 'package:hentai_library/shared/ui/widgets/actions/filled_button.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/author.dart';
import 'package:hentai_library/features/named_metadata/domain/named_facet_management_repository.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 当前维度的名称列表（chip 流）：加载 / 错误 / 空 / 列表 / 底部状态。
///
/// 盒模型内容，供页面用 [PeerContentTransition] + [SliverToBoxAdapter] 挂载。
class MetadataFacetContent extends ConsumerWidget {
  const MetadataFacetContent({
    required this.kind,
    required this.onCreatePressed,
    this.draftChip,
    this.mergeTarget,
    this.mergeSources = const <String>{},
    this.onMergeTargetSelected,
    this.onMergeSourceSelected,
    this.onMergeSelectionExited,
    super.key,
  });

  /// 空态「添加」按钮与 FAB 共用的新建入口（由页面按断点决定 Dialog / 内联）。
  final VoidCallback onCreatePressed;

  /// 桌面端内联新建草稿 chip，挂在 chip 流末尾；移动端为 null。
  final Widget? draftChip;

  final ManagedNamedFacetKind kind;
  final String? mergeTarget;
  final Set<String> mergeSources;
  final ValueChanged<String>? onMergeTargetSelected;
  final ValueChanged<String>? onMergeSourceSelected;
  final VoidCallback? onMergeSelectionExited;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (
      bool isLoading,
      Object? error,
      List<String> items,
      bool hasSearchQuery,
      Map<String, int> attachmentCounts,
      bool isLoadingMore,
      bool hasMore,
    ) = ref.watch(
      namedFacetManagementViewModelProvider(kind).select(
        (NamedFacetManagementState s) => (
          s.isLoading,
          s.error,
          s.items,
          s.hasSearchQuery,
          s.attachmentCounts,
          s.isLoadingMore,
          s.hasMore,
        ),
      ),
    );
    if (isLoading && items.isEmpty) {
      return const _FacetLoading();
    }
    if (error != null && items.isEmpty) {
      return _FacetError(
        message: '$error',
        onRetry: () => ref
            .read(namedFacetManagementViewModelProvider(kind).notifier)
            .refresh(),
      );
    }
    if (items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _FacetEmpty(
            kind: kind,
            hasSearchQuery: hasSearchQuery,
            onCreate: onCreatePressed,
          ),
          if (draftChip != null)
            Wrap(spacing: 8, runSpacing: 8, children: <Widget>[draftChip!]),
        ],
      );
    }
    return _FacetList(
      kind: kind,
      items: items,
      attachmentCounts: attachmentCounts,
      hasSearchQuery: hasSearchQuery,
      isLoadingMore: isLoadingMore,
      hasMore: hasMore,
      error: error,
      draftChip: draftChip,
      mergeTarget: mergeTarget,
      mergeSources: mergeSources,
      onMergeTargetSelected: onMergeTargetSelected,
      onMergeSourceSelected: onMergeSourceSelected,
      onMergeSelectionExited: onMergeSelectionExited,
    );
  }
}

class _FacetList extends ConsumerWidget {
  const _FacetList({
    required this.kind,
    required this.items,
    required this.attachmentCounts,
    required this.hasSearchQuery,
    required this.isLoadingMore,
    required this.hasMore,
    required this.mergeSources,
    this.error,
    this.draftChip,
    this.mergeTarget,
    this.onMergeTargetSelected,
    this.onMergeSourceSelected,
    this.onMergeSelectionExited,
  });

  final ManagedNamedFacetKind kind;
  final List<String> items;
  final Map<String, int> attachmentCounts;
  final bool hasSearchQuery;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;
  final Widget? draftChip;
  final String? mergeTarget;
  final Set<String> mergeSources;
  final ValueChanged<String>? onMergeTargetSelected;
  final ValueChanged<String>? onMergeSourceSelected;
  final VoidCallback? onMergeSelectionExited;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final Set<String> verifiedAuthors = kind == ManagedNamedFacetKind.author
        ? ref
              .watch(allAuthorsProvider)
              .maybeWhen(
                data: (List<Author> authors) => <String>{
                  for (final Author a in authors)
                    if (a.verified) a.name,
                },
                orElse: () => const <String>{},
              )
        : const <String>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            context.l10n.metadataListTitle(kind),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final String name in items)
              MetadataFacetChip(
                key: ValueKey<String>('facet-chip-$name'),
                kind: kind,
                name: name,
                attachmentCount: attachmentCounts[name],
                verified: verifiedAuthors.contains(name),
                mergeTarget: mergeTarget,
                isMergeSource: mergeSources.contains(name),
                onMergeTargetSelected: onMergeTargetSelected,
                onMergeSourceSelected: onMergeSourceSelected,
                onMergeSelectionExited: onMergeSelectionExited,
              ),
            ?draftChip,
          ],
        ),
        if (error != null) ...<Widget>[
          const SizedBox(height: 12),
          Text('$error', style: TextStyle(color: scheme.error)),
        ],
        const SizedBox(height: 16),
        _FacetFooter(
          kind: kind,
          hasSearchQuery: hasSearchQuery,
          isLoadingMore: isLoadingMore,
          hasMore: hasMore,
          itemCount: items.length,
        ),
      ],
    );
  }
}

class _FacetFooter extends ConsumerWidget {
  const _FacetFooter({
    required this.kind,
    required this.hasSearchQuery,
    required this.isLoadingMore,
    required this.hasMore,
    required this.itemCount,
  });

  final ManagedNamedFacetKind kind;
  final bool hasSearchQuery;
  final bool isLoadingMore;
  final bool hasMore;
  final int itemCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final TextStyle style = TextStyle(color: scheme.onSurfaceVariant);

    if (hasSearchQuery) {
      return Text(
        l10n.metadataTotalCount(itemCount),
        textAlign: TextAlign.center,
        style: style,
      );
    }
    if (isLoadingMore) {
      return Text(
        l10n.metadataLoadingMore,
        textAlign: TextAlign.center,
        style: style,
      );
    }
    if (!hasMore) {
      return Text(
        l10n.metadataListEnd,
        textAlign: TextAlign.center,
        style: style,
      );
    }
    return Center(
      child: ExpressiveFilledButton(
        label: l10n.metadataLoadMore,
        icon: Symbols.expand_more,
        onPressed: () => ref
            .read(namedFacetManagementViewModelProvider(kind).notifier)
            .loadMore(),
      ),
    );
  }
}

class _FacetLoading extends StatelessWidget {
  const _FacetLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2.2)),
    );
  }
}

class _FacetError extends StatelessWidget {
  const _FacetError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: <Widget>[
            Icon(Symbols.error, size: 32, color: scheme.outline),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            ExpressiveFilledButton(
              label: context.l10n.commonRetry,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _FacetEmpty extends StatelessWidget {
  const _FacetEmpty({
    required this.kind,
    required this.hasSearchQuery,
    required this.onCreate,
  });

  final ManagedNamedFacetKind kind;
  final bool hasSearchQuery;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: <Widget>[
            Icon(
              hasSearchQuery ? Symbols.search_off : Symbols.label,
              size: 48,
              color: scheme.outline,
            ),
            Text(
              hasSearchQuery
                  ? l10n.metadataNoMatchTitle(kind)
                  : l10n.metadataEmptyTitle(kind),
              style: theme.typeScale.titleMedium.copyWith(
                color: scheme.onSurface,
              ),
            ),
            Text(
              hasSearchQuery
                  ? l10n.metadataSearchNoMatchHint
                  : l10n.metadataEmptyHint(kind),
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            if (!hasSearchQuery) ...<Widget>[
              const SizedBox(height: 8),
              ExpressiveFilledButton(
                label: l10n.metadataAddLabel(kind),
                onPressed: onCreate,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
