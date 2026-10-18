import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/author.dart';
import 'package:hentai_library/shared/domain/repositories/named_facet_management_repository.dart';
import 'package:hentai_library/shared/ui/layout/page_content_width_layout.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hentai_library/shared/ui/widgets/actions/destructive_filled_button.dart';
import 'package:hentai_library/shared/ui/widgets/actions/ghost_button.dart';
import 'package:hentai_library/shared/ui/widgets/element/chip/count_digit_chip.dart';
import 'package:hentai_library/shared/ui/widgets/element/chip/outlined_meta_chip.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/shared/ui/widgets/overlays/context_menu/named_facet_context_menu.dart';
import 'package:hentai_library/shared/di/author_detail_providers.dart';
import 'package:hentai_library/features/named_metadata/presentation/view_models/author_management_notifier.dart';
import 'package:hentai_library/shared/ui/widgets/overlays/dialog/hentai_dialog.dart';
import 'package:hentai_library/shared/ui/widgets/overlays/dialog/tag_name_editor_dialog.dart';
import 'package:hentai_library/features/named_metadata/presentation/view_models/named_facet_management_controller.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata_page/widgets/metadata_layout_constants.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

part 'named_facet_management_states.dart';

class NamedFacetManagementSliverGroup extends ConsumerWidget {
  const NamedFacetManagementSliverGroup({
    required this.kind,
    required this.layoutTier,
    required this.viewportWidth,
    required this.horizontalPadding,
    required this.contentMaxWidth,
    this.mergeTarget,
    this.mergeSources = const <String>{},
    this.onMergeTargetSelected,
    this.onMergeSourceSelected,
    this.onMergeSelectionExited,
    super.key,
  });

  final ManagedNamedFacetKind kind;
  final MetadataLayoutTier layoutTier;
  final double viewportWidth;
  final double horizontalPadding;
  final double contentMaxWidth;
  final String? mergeTarget;
  final Set<String> mergeSources;
  final ValueChanged<String>? onMergeTargetSelected;
  final ValueChanged<String>? onMergeSourceSelected;
  final VoidCallback? onMergeSelectionExited;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(namedFacetManagementControllerProvider(kind));
    final AppThemeTokens tokens = context.tokens;

    if (state.isLoading && state.items.isEmpty) {
      return _padListSliver(
        tokens,
        SliverToBoxAdapter(
          child: _alignedListChild(
            context,
            const _NamedFacetManagementLoadingState(),
          ),
        ),
      );
    }

    if (state.error != null && state.items.isEmpty) {
      return _padListSliver(
        tokens,
        SliverToBoxAdapter(
          child: _alignedListChild(
            context,
            _NamedFacetManagementErrorState(
              error: state.error!,
              onRetry: () => ref
                  .read(namedFacetManagementControllerProvider(kind).notifier)
                  .refresh(),
            ),
          ),
        ),
      );
    }

    if (state.items.isEmpty) {
      return _padListSliver(
        tokens,
        SliverToBoxAdapter(
          child: _alignedListChild(
            context,
            _NamedFacetManagementEmptyState(
              kind: kind,
              hasSearchQuery: state.hasSearchQuery,
              onCreate: () => openNamedFacetCreateDialog(context, ref, kind),
            ),
          ),
        ),
      );
    }

    return _padListSliver(
      tokens,
      SliverToBoxAdapter(
        child: _alignedListChild(
          context,
          _NamedFacetListSection(
            kind: kind,
            layoutTier: layoutTier,
            state: state,
            mergeTarget: mergeTarget,
            mergeSources: mergeSources,
            onMergeTargetSelected: onMergeTargetSelected,
            onMergeSourceSelected: onMergeSourceSelected,
            onMergeSelectionExited: onMergeSelectionExited,
          ),
        ),
      ),
    );
  }

  Widget _alignedListChild(BuildContext context, Widget child) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: pageContentAlignedHorizontalInset(
          viewportWidth: viewportWidth,
          horizontalPadding: horizontalPadding,
          maxWidth: contentMaxWidth,
        ),
      ),
      child: child,
    );
  }

  Widget _padListSliver(AppThemeTokens tokens, Widget sliver) {
    return SliverPadding(
      padding: EdgeInsets.only(
        bottom: tokens.layout.contentVerticalPadding + 24,
      ),
      sliver: sliver,
    );
  }
}

/// Flat Fluent list section: no card shell — spacing + hairline only.
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
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color? selectionFill = isMergeTarget
        ? colors.hentai.success.withValues(alpha: 0.22)
        : isMergeSource
        ? colors.error.withValues(alpha: 0.22)
        : null;
    final Color? selectionBorder = isMergeTarget
        ? colors.hentai.success
        : isMergeSource
        ? colors.error
        : null;
    return OutlinedMetaChip(
      text: name,
      compact: true,
      backgroundColor: selectionFill,
      borderColor: selectionBorder,
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
          ? () {
              if (isMergeTarget) {
                onMergeSelectionExited?.call();
              } else {
                onMergeSourceSelected?.call(name);
              }
            }
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
                  color: cs.hentai.textSecondary,
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
        Divider(height: 1, thickness: 1, color: cs.hentai.borderSubtle),
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
    final cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final l10n = context.l10n;
    final TextStyle footerStyle = TextStyle(
      fontSize: tokens.text.labelXs,
      color: cs.hentai.textTertiary,
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
