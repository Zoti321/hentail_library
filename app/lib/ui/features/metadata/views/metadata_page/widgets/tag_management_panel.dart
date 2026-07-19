import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/layout/page_content_width_layout.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hentai_library/ui/core/widgets/chrome/status_card_shell.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/confirm/tag_confirm_delete_dialog.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/tag_name_editor_dialog.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/widgets/metadata_layout_constants.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/widgets/metadata_panel_shell.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/widgets/metadata_row_actions.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TagManagementSliverGroup extends ConsumerWidget {
  const TagManagementSliverGroup({
    required this.layoutTier,
    required this.viewportWidth,
    required this.horizontalPadding,
    required this.contentMaxWidth,
    super.key,
  });

  final MetadataLayoutTier layoutTier;
  final double viewportWidth;
  final double horizontalPadding;
  final double contentMaxWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(allTagsProvider);
    final List<Tag> filteredTags = ref.watch(filteredTagsProvider);
    final AppThemeTokens tokens = context.tokens;

    return tagsAsync.when(
      data: (_) {
        if (filteredTags.isEmpty) {
          return _padListSliver(
            tokens,
            SliverToBoxAdapter(
              child: _alignedListChild(const _TagManagementEmptyState()),
            ),
          );
        }
        return _padListSliver(
          tokens,
          SliverToBoxAdapter(
            child: _alignedListChild(
              _TagListCardContent(layoutTier: layoutTier, tags: filteredTags),
            ),
          ),
        );
      },
      loading: () => _padListSliver(
        tokens,
        SliverToBoxAdapter(
          child: _alignedListChild(const _TagManagementLoadingState()),
        ),
      ),
      error: (Object e, StackTrace _) => _padListSliver(
        tokens,
        SliverToBoxAdapter(
          child: _alignedListChild(_TagManagementErrorState(error: e)),
        ),
      ),
    );
  }

  Widget _alignedListChild(Widget child) {
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

class _TagStyles {
  const _TagStyles._();

  static const double listRadius = 12;
  static const EdgeInsets listHeaderPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  );
  static const EdgeInsets rowPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 10,
  );
  static const double listHeaderIconSize = 16;
  static const double listHeaderFontSize = 13;

  static const double iconButtonRadius = 8;
  static const Size iconButtonSize = Size(28, 28);

  static const double statusCardRadius = 14;
  static const EdgeInsets statusErrorPadding = EdgeInsets.all(20);
  static const EdgeInsets statusLoadingPadding = EdgeInsets.symmetric(
    vertical: 42,
  );
  static const EdgeInsets statusEmptyPadding = EdgeInsets.symmetric(
    vertical: 48,
  );
}

class _TagListCardContent extends ConsumerWidget {
  const _TagListCardContent({required this.layoutTier, required this.tags});

  final MetadataLayoutTier layoutTier;
  final List<Tag> tags;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return MetadataPanelListCard(
      radius: _TagStyles.listRadius,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _TagListHeader(totalCount: tags.length),
          for (int i = 0; i < tags.length; i++) ...<Widget>[
            if (i > 0) Divider(height: 1, color: cs.hentai.borderSubtle),
            Consumer(
              builder: (BuildContext context, WidgetRef ref, Widget? child) {
                final Tag tag = tags[i];
                final bool isSelected = ref.watch(
                  tagSelectionProvider.select(
                    (Set<Tag> selected) => selected.contains(tag),
                  ),
                );
                return _TagRow(
                  layoutTier: layoutTier,
                  tag: tag,
                  isSelected: isSelected,
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _TagListHeader extends ConsumerWidget {
  const _TagListHeader({required this.totalCount});

  final int totalCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final int selectionCount = ref.watch(
      tagSelectionProvider.select((Set<Tag> s) => s.length),
    );
    return Container(
      padding: _TagStyles.listHeaderPadding,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: cs.hentai.borderSubtle)),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.tags,
            size: _TagStyles.listHeaderIconSize,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            l10n.metadataAllTags,
            style: TextStyle(
              fontSize: _TagStyles.listHeaderFontSize,
              fontWeight: FontWeight.w600,
              color: cs.hentai.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            l10n.metadataTotalCount(totalCount),
            style: TextStyle(
              fontSize: _TagStyles.listHeaderFontSize,
              color: cs.hentai.textTertiary,
            ),
          ),
          if (selectionCount > 0) ...[
            const SizedBox(width: 12),
            Text(
              l10n.metadataSelectedCount(selectionCount),
              style: TextStyle(
                fontSize: _TagStyles.listHeaderFontSize,
                fontWeight: FontWeight.w600,
                color: cs.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TagRow extends ConsumerWidget {
  const _TagRow({
    required this.layoutTier,
    required this.tag,
    required this.isSelected,
  });

  final MetadataLayoutTier layoutTier;
  final Tag tag;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = context.l10n;

    return MetadataPanelRowInteractionShell(
      hoverColor: cs.primary.withAlpha(10),
      materialColor: cs.surface,
      child: InkWell(
        onTap: () => ref.read(tagSelectionProvider.notifier).toggle(tag),
        child: Padding(
          padding: _TagStyles.rowPadding,
          child: Row(
            spacing: 12,
            children: [
              GhostButton.icon(
                icon: isSelected
                    ? LucideIcons.squareCheckBig
                    : LucideIcons.square,
                iconSize: 16,
                size: _TagStyles.iconButtonSize.width,
                tooltip: isSelected ? l10n.metadataDeselect : l10n.metadataSelect,
                foregroundColor: isSelected
                    ? cs.primary
                    : cs.hentai.textTertiary,
                hoverColor: theme.colorScheme.primary.withAlpha(10),
                overlayColor: theme.colorScheme.primary.withAlpha(14),
                borderRadius: 8,
                delayTooltipThreeSeconds: true,
                onPressed: () =>
                    ref.read(tagSelectionProvider.notifier).toggle(tag),
              ),
              Expanded(
                child: Text(
                  tag.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: cs.hentai.textPrimary,
                  ),
                ),
              ),
              MetadataPanelRowActions(
                layoutTier: layoutTier,
                iconButtonRadius: _TagStyles.iconButtonRadius,
                iconButtonSize: _TagStyles.iconButtonSize.width,
                onRename: () async {
                  await showDialog<void>(
                    context: context,
                    builder: (context) => TagNameEditorDialog(
                      title: l10n.metadataRenameTag,
                      labelText: l10n.metadataNewName,
                      hintText: l10n.metadataRenameTagHint,
                      initialValue: tag.name,
                      shouldCloseOnUnchanged: true,
                      onSubmit: (value) async {
                        await ref
                            .read(tagActionsProvider)
                            .renameTag(tag, value);
                      },
                    ),
                  );
                },
                onDelete: () async {
                  final bool confirmed =
                      await showDialog<bool>(
                        context: context,
                        builder: (BuildContext dialogContext) =>
                            const TagConfirmDeleteDialog(count: 1),
                      ) ??
                      false;
                  if (!confirmed || !context.mounted) {
                    return;
                  }
                  try {
                    await ref.read(tagActionsProvider).deleteTag(tag);
                    if (context.mounted) {
                      showSuccessToast(context, l10n.metadataTagDeletedToast);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      showErrorToast(context, e);
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagManagementLoadingState extends StatelessWidget {
  const _TagManagementLoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StatusCardShell(
      padding: _TagStyles.statusLoadingPadding,
      borderRadius: _TagStyles.statusCardRadius,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _TagManagementErrorState extends StatelessWidget {
  const _TagManagementErrorState({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StatusCardShell(
      padding: _TagStyles.statusErrorPadding,
      borderRadius: _TagStyles.statusCardRadius,
      child: Text(
        '$error',
        style: TextStyle(
          fontSize: kMetadataPanelSubtitleFontSize,
          color: theme.colorScheme.hentai.textTertiary,
        ),
      ),
    );
  }
}

class _TagManagementEmptyState extends StatelessWidget {
  const _TagManagementEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = context.l10n;
    return StatusCardShell(
      padding: _TagStyles.statusEmptyPadding,
      borderRadius: _TagStyles.statusCardRadius,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.tags, size: 32, color: cs.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            l10n.metadataTagsEmptyTitle,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.hentai.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.metadataTagsEmptyHint,
            style: TextStyle(
              fontSize: kMetadataPanelSubtitleFontSize,
              color: cs.hentai.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
