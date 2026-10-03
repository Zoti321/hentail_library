import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/domain/repositories/named_facet_management_repository.dart';
import 'package:hentai_library/ui/core/layout/page_content_width_layout.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/destructive_filled_button.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/widgets/element/chip/count_digit_chip.dart';
import 'package:hentai_library/ui/core/widgets/element/chip/outlined_meta_chip.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/core/widgets/overlays/context_menu/named_facet_context_menu.dart';
import 'package:hentai_library/ui/features/library/views/widgets/show_author_detail.dart';
import 'package:hentai_library/ui/features/metadata/view_models/author_management_notifier.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/hentai_dialog.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/tag_name_editor_dialog.dart';
import 'package:hentai_library/ui/features/metadata/view_models/named_facet_management_controller.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/widgets/metadata_layout_constants.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class NamedFacetManagementSliverGroup extends ConsumerWidget {
  const NamedFacetManagementSliverGroup({
    required this.kind,
    required this.layoutTier,
    required this.viewportWidth,
    required this.horizontalPadding,
    required this.contentMaxWidth,
    super.key,
  });

  final ManagedNamedFacetKind kind;
  final MetadataLayoutTier layoutTier;
  final double viewportWidth;
  final double horizontalPadding;
  final double contentMaxWidth;

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
  });

  final ManagedNamedFacetKind kind;
  final MetadataLayoutTier layoutTier;
  final NamedFacetManagementState state;

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
  });

  final ManagedNamedFacetKind kind;
  final String name;
  final int? attachmentCount;

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
      onAction: (NamedFacetContextAction action) {
        switch (action) {
          case NamedFacetContextAction.rename:
            unawaited(_renameNamedFacet(context, ref, kind, name));
          case NamedFacetContextAction.merge:
            break;
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
    return OutlinedMetaChip(
      text: name,
      compact: true,
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
                showAuthorDetailByName(context: context, ref: ref, name: name),
              );
            }
          : null,
      onLongPress: isAuthor || desktop
          ? null
          : () {
              final RenderBox box = context.findRenderObject()! as RenderBox;
              _showMenu(context, ref, box.localToGlobal(Offset.zero));
            },
      onSecondaryTapUp: isAuthor || !desktop
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

class _NamedFacetManagementLoadingState extends StatelessWidget {
  const _NamedFacetManagementLoadingState();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spacing.xl * 2),
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.2, color: cs.primary),
        ),
      ),
    );
  }
}

class _NamedFacetManagementErrorState extends StatelessWidget {
  const _NamedFacetManagementErrorState({
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spacing.xl * 2),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              LucideIcons.circleAlert,
              size: 32,
              color: cs.hentai.textTertiary,
            ),
            SizedBox(height: tokens.spacing.md),
            Text(
              '$error',
              style: TextStyle(
                fontSize: tokens.text.bodySm,
                color: cs.hentai.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: tokens.spacing.lg),
            FilledButton(
              onPressed: onRetry,
              child: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}

class _NamedFacetManagementEmptyState extends StatelessWidget {
  const _NamedFacetManagementEmptyState({
    required this.kind,
    required this.hasSearchQuery,
    required this.onCreate,
  });

  final ManagedNamedFacetKind kind;
  final bool hasSearchQuery;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spacing.xl * 2),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              hasSearchQuery ? LucideIcons.searchX : _iconForKind(kind),
              size: 32,
              color: cs.hentai.textTertiary,
            ),
            SizedBox(height: tokens.spacing.md),
            Text(
              hasSearchQuery
                  ? l10n.metadataNoMatchTitle(kind)
                  : l10n.metadataEmptyTitle(kind),
              style: TextStyle(
                fontSize: tokens.text.bodyMd,
                fontWeight: FontWeight.w600,
                color: cs.hentai.textPrimary,
              ),
            ),
            SizedBox(height: tokens.spacing.xs),
            Text(
              hasSearchQuery
                  ? l10n.metadataSearchNoMatchHint
                  : l10n.metadataEmptyHint(kind),
              style: TextStyle(
                fontSize: tokens.text.bodySm,
                color: cs.hentai.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (!hasSearchQuery) ...<Widget>[
              SizedBox(height: tokens.spacing.lg),
              FilledButton(
                onPressed: onCreate,
                child: Text(l10n.metadataAddLabel(kind)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NamedFacetConfirmDeleteDialog extends StatelessWidget {
  const _NamedFacetConfirmDeleteDialog({
    required this.name,
    required this.attachmentCount,
  });

  final String name;
  final int attachmentCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return HentaiDialog(
      title: l10n.confirmDeleteNamedFacetTitle,
      content: Text(l10n.confirmDeleteNamedFacetContent(name, attachmentCount)),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        const SizedBox(width: 8),
        DestructiveFilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.commonDelete),
        ),
      ],
    );
  }
}

Future<void> _renameNamedFacet(
  BuildContext context,
  WidgetRef ref,
  ManagedNamedFacetKind kind,
  String name,
) async {
  final l10n = context.l10n;
  await showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) => TagNameEditorDialog(
      title: l10n.metadataRenameTitle(kind),
      labelText: l10n.metadataNewName,
      hintText: l10n.metadataRenameHint(kind),
      initialValue: name,
      shouldCloseOnUnchanged: true,
      onSubmit: (String value) async {
        await ref
            .read(namedFacetManagementControllerProvider(kind).notifier)
            .rename(name, value);
      },
    ),
  );
}

Future<void> _deleteNamedFacet(
  BuildContext context,
  WidgetRef ref,
  ManagedNamedFacetKind kind,
  String name,
) async {
  final int count;
  try {
    count = await ref
        .read(namedFacetManagementControllerProvider(kind).notifier)
        .countAttachments(name);
  } catch (error) {
    if (context.mounted) {
      showErrorToast(context, error);
    }
    return;
  }
  if (!context.mounted) {
    return;
  }
  final bool confirmed =
      await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) =>
            _NamedFacetConfirmDeleteDialog(name: name, attachmentCount: count),
      ) ??
      false;
  if (!confirmed || !context.mounted) {
    return;
  }
  try {
    await ref
        .read(namedFacetManagementControllerProvider(kind).notifier)
        .delete(name);
    if (context.mounted) {
      showSuccessToast(context, context.l10n.metadataDeletedToast(kind));
    }
  } catch (error) {
    if (context.mounted) {
      showErrorToast(context, error);
    }
  }
}

Future<void> openNamedFacetCreateDialog(
  BuildContext context,
  WidgetRef ref,
  ManagedNamedFacetKind kind,
) async {
  final l10n = context.l10n;
  await showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) => TagNameEditorDialog(
      title: l10n.metadataAddLabel(kind),
      labelText: l10n.metadataNameLabel,
      hintText: l10n.metadataAddHint(kind),
      initialValue: '',
      onSubmit: (String value) async {
        await ref
            .read(namedFacetManagementControllerProvider(kind).notifier)
            .add(value);
      },
    ),
  );
}

IconData _iconForKind(ManagedNamedFacetKind kind) => switch (kind) {
  ManagedNamedFacetKind.author => LucideIcons.penLine,
  ManagedNamedFacetKind.tag => LucideIcons.tags,
  ManagedNamedFacetKind.parody => LucideIcons.clapperboard,
  ManagedNamedFacetKind.character => LucideIcons.userRound,
};
