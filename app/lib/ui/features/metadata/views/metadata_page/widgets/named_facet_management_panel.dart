import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/repositories/named_facet_management_repository.dart';
import 'package:hentai_library/ui/core/layout/page_content_width_layout.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/destructive_filled_button.dart';
import 'package:hentai_library/ui/core/widgets/element/chip/count_digit_chip.dart';
import 'package:hentai_library/ui/core/widgets/element/chip/outlined_meta_chip.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/adaptive_form_surface.dart';
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
                (String item) => OutlinedMetaChip(
                  text: item,
                  compact: true,
                  onTap: () => showAdaptiveFormSurfaceWidget<void>(
                    context: context,
                    surface: _NamedFacetDetailSurface(
                      kind: kind,
                      initialName: item,
                    ),
                  ),
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
        _NamedFacetListFooter(state: state),
      ],
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

class _NamedFacetListFooter extends StatelessWidget {
  const _NamedFacetListFooter({required this.state});

  final NamedFacetManagementState state;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final l10n = context.l10n;
    final String message = state.hasSearchQuery
        ? l10n.metadataTotalCount(state.items.length)
        : state.isLoadingMore
        ? l10n.metadataLoadingMore
        : state.hasMore
        ? l10n.metadataScrollToLoadMore
        : l10n.metadataListEnd;
    return Text(
      message,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: tokens.text.labelXs,
        color: cs.hentai.textTertiary,
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

class _NamedFacetDetailSurface extends ConsumerStatefulWidget {
  const _NamedFacetDetailSurface({
    required this.kind,
    required this.initialName,
  });

  final ManagedNamedFacetKind kind;
  final String initialName;

  @override
  ConsumerState<_NamedFacetDetailSurface> createState() =>
      _NamedFacetDetailSurfaceState();
}

class _NamedFacetDetailSurfaceState
    extends ConsumerState<_NamedFacetDetailSurface> {
  late String _name = widget.initialName;
  int? _attachmentCount;
  Object? _countError;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    setState(() {
      _countError = null;
    });
    try {
      final count = await ref
          .read(namedFacetManagementControllerProvider(widget.kind).notifier)
          .countAttachments(_name);
      if (!mounted) {
        return;
      }
      setState(() {
        _attachmentCount = count;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _countError = error;
      });
    }
  }

  Future<void> _rename() async {
    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => TagNameEditorDialog(
        title: l10n.metadataRenameTitle(widget.kind),
        labelText: l10n.metadataNewName,
        hintText: l10n.metadataRenameHint(widget.kind),
        initialValue: _name,
        shouldCloseOnUnchanged: true,
        onSubmit: (String value) async {
          await ref
              .read(
                namedFacetManagementControllerProvider(widget.kind).notifier,
              )
              .rename(_name, value);
          if (!mounted) {
            return;
          }
          setState(() {
            _name = value.trim();
            _attachmentCount = null;
          });
          await _loadCount();
        },
      ),
    );
  }

  Future<void> _delete() async {
    final int? count = _attachmentCount;
    if (count == null) {
      return;
    }
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) =>
              _NamedFacetConfirmDeleteDialog(
                name: _name,
                attachmentCount: count,
              ),
        ) ??
        false;
    if (!confirmed || !mounted) {
      return;
    }

    setState(() => _busy = true);
    try {
      await ref
          .read(namedFacetManagementControllerProvider(widget.kind).notifier)
          .delete(_name);
      if (!mounted) {
        return;
      }
      showSuccessToast(context, context.l10n.metadataDeletedToast(widget.kind));
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      showErrorToast(context, error);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final int? count = _attachmentCount;
    final Object? countError = _countError;

    return AdaptiveFormSurface(
      title: _name,
      maxDialogWidth: 360,
      borderRadius: tokens.radius.xs,
      fitContentHeight: true,
      showFooterDivider: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            l10n.metadataAttachedComicsCaption,
            style: TextStyle(
              fontSize: tokens.text.labelXs,
              fontWeight: FontWeight.w600,
              color: cs.hentai.textSecondary,
            ),
          ),
          SizedBox(height: tokens.spacing.xs),
          if (countError != null)
            Text(
              '$countError',
              style: TextStyle(
                fontSize: tokens.text.bodySm,
                color: cs.hentai.error,
              ),
            )
          else
            Text(
              count?.toString() ?? l10n.shellLoading,
              style: TextStyle(
                fontSize: tokens.text.titleMd,
                fontWeight: FontWeight.w600,
                color: count == null
                    ? cs.hentai.textSecondary
                    : cs.hentai.textPrimary,
              ),
            ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
          child: Text(l10n.commonClose),
        ),
        OutlinedButton(
          onPressed: _busy ? null : _rename,
          child: Text(l10n.metadataRename),
        ),
        FilledButton(
          onPressed: _busy || count == null ? null : _delete,
          child: Text(l10n.metadataDelete),
        ),
      ],
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
