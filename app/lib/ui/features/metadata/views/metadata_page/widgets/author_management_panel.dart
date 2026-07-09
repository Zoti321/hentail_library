import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/domain/models/entity/comic/author.dart';
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

class AuthorManagementSliverGroup extends ConsumerWidget {
  const AuthorManagementSliverGroup({
    required this.layoutTier,
    required this.contentMaxWidth,
    super.key,
  });

  final MetadataLayoutTier layoutTier;
  final double contentMaxWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authorsAsync = ref.watch(allAuthorsProvider);
    final List<Author> filteredAuthors = ref.watch(filteredAuthorsProvider);
    final AppThemeTokens tokens = context.tokens;

    return authorsAsync.when(
      data: (_) {
        if (filteredAuthors.isEmpty) {
          return _padListSliver(
            tokens,
            SliverToBoxAdapter(
              child: _centeredListChild(
                const _AuthorManagementEmptyState(),
              ),
            ),
          );
        }
        return _padListSliver(
          tokens,
          SliverToBoxAdapter(
            child: _centeredListChild(
              _AuthorListCardContent(
                layoutTier: layoutTier,
                authors: filteredAuthors,
              ),
            ),
          ),
        );
      },
      loading: () => _padListSliver(
        tokens,
        SliverToBoxAdapter(
          child: _centeredListChild(const _AuthorManagementLoadingState()),
        ),
      ),
      error: (Object e, StackTrace _) => _padListSliver(
        tokens,
        SliverToBoxAdapter(
          child: _centeredListChild(_AuthorManagementErrorState(error: e)),
        ),
      ),
    );
  }

  Widget _centeredListChild(Widget child) {
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(width: contentMaxWidth, child: child),
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

class _AuthorStyles {
  const _AuthorStyles._();

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

class _AuthorListCardContent extends ConsumerWidget {
  const _AuthorListCardContent({
    required this.layoutTier,
    required this.authors,
  });

  final MetadataLayoutTier layoutTier;
  final List<Author> authors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return MetadataPanelListCard(
      radius: _AuthorStyles.listRadius,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _AuthorListHeader(totalCount: authors.length),
          for (int i = 0; i < authors.length; i++) ...<Widget>[
            if (i > 0) Divider(height: 1, color: cs.hentai.borderSubtle),
            Consumer(
              builder: (BuildContext context, WidgetRef ref, Widget? child) {
                final Author author = authors[i];
                final bool isSelected = ref.watch(
                  authorSelectionProvider.select(
                    (Set<Author> selected) => selected.contains(author),
                  ),
                );
                return _AuthorRow(
                  layoutTier: layoutTier,
                  author: author,
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

class _AuthorListHeader extends ConsumerWidget {
  const _AuthorListHeader({required this.totalCount});

  final int totalCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final int selectionCount = ref.watch(
      authorSelectionProvider.select((Set<Author> s) => s.length),
    );
    return Container(
      padding: _AuthorStyles.listHeaderPadding,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: cs.hentai.borderSubtle)),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.penLine,
            size: _AuthorStyles.listHeaderIconSize,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            '全部作者',
            style: TextStyle(
              fontSize: _AuthorStyles.listHeaderFontSize,
              fontWeight: FontWeight.w600,
              color: cs.hentai.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '共 $totalCount 条',
            style: TextStyle(
              fontSize: _AuthorStyles.listHeaderFontSize,
              color: cs.hentai.textTertiary,
            ),
          ),
          if (selectionCount > 0) ...[
            const SizedBox(width: 12),
            Text(
              '已选 $selectionCount',
              style: TextStyle(
                fontSize: _AuthorStyles.listHeaderFontSize,
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

class _AuthorRow extends ConsumerWidget {
  const _AuthorRow({
    required this.layoutTier,
    required this.author,
    required this.isSelected,
  });

  final MetadataLayoutTier layoutTier;
  final Author author;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return MetadataPanelRowInteractionShell(
      hoverColor: cs.primary.withAlpha(10),
      materialColor: cs.surface,
      child: InkWell(
        onTap: () => ref.read(authorSelectionProvider.notifier).toggle(author),
        child: Padding(
          padding: _AuthorStyles.rowPadding,
          child: Row(
            spacing: 12,
            children: [
              GhostButton.icon(
                icon: isSelected
                    ? LucideIcons.squareCheckBig
                    : LucideIcons.square,
                iconSize: 16,
                size: _AuthorStyles.iconButtonSize.width,
                tooltip: '',
                foregroundColor: isSelected
                    ? cs.primary
                    : cs.hentai.textTertiary,
                hoverColor: theme.colorScheme.primary.withAlpha(10),
                overlayColor: theme.colorScheme.primary.withAlpha(14),
                borderRadius: 8,
                onPressed: () =>
                    ref.read(authorSelectionProvider.notifier).toggle(author),
              ),
              Expanded(
                child: Text(
                  author.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: cs.hentai.textPrimary,
                  ),
                ),
              ),
              MetadataPanelRowActions(
                layoutTier: layoutTier,
                iconButtonRadius: _AuthorStyles.iconButtonRadius,
                iconButtonSize: _AuthorStyles.iconButtonSize.width,
                onRename: () async {
                  await showDialog<void>(
                    context: context,
                    builder: (context) => TagNameEditorDialog(
                      title: '重命名作者',
                      labelText: '新名称',
                      hintText: '输入新的作者名称…',
                      initialValue: author.name,
                      shouldCloseOnUnchanged: true,
                      onSubmit: (value) async {
                        await ref
                            .read(authorActionsProvider)
                            .renameAuthor(author, value);
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
                    await ref.read(authorActionsProvider).deleteAuthor(author);
                    if (context.mounted) {
                      showSuccessToast(context, '已删除作者');
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

class _AuthorManagementLoadingState extends StatelessWidget {
  const _AuthorManagementLoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StatusCardShell(
      padding: _AuthorStyles.statusLoadingPadding,
      borderRadius: _AuthorStyles.statusCardRadius,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _AuthorManagementErrorState extends StatelessWidget {
  const _AuthorManagementErrorState({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StatusCardShell(
      padding: _AuthorStyles.statusErrorPadding,
      borderRadius: _AuthorStyles.statusCardRadius,
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

class _AuthorManagementEmptyState extends StatelessWidget {
  const _AuthorManagementEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return StatusCardShell(
      padding: _AuthorStyles.statusEmptyPadding,
      borderRadius: _AuthorStyles.statusCardRadius,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.penLine, size: 32, color: cs.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            '暂无作者',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.hentai.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '你可以从这里添加、重命名或删除作者。',
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
