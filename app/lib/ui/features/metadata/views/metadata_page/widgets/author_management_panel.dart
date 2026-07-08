import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hentai_library/ui/core/widgets/chrome/status_card_shell.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/confirm/tag_confirm_delete_dialog.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/tag_name_editor_dialog.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/widgets/metadata_layout_constants.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/widgets/metadata_panel_height.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/widgets/metadata_panel_shell.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/widgets/metadata_row_actions.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AuthorManagementPanel extends ConsumerWidget {
  const AuthorManagementPanel({
    required this.layoutTier,
    super.key,
  });

  final MetadataLayoutTier layoutTier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    assert(metadataUsesListCard(layoutTier));
    final authorsAsync = ref.watch(allAuthorsProvider);
    final List<Author> filteredAuthors = ref.watch(filteredAuthorsProvider);
    final AppThemeTokens tokens = context.tokens;

    return Padding(
      padding: EdgeInsets.only(
        bottom: tokens.layout.contentVerticalPadding + 24,
      ),
      child: authorsAsync.when(
        data: (_) {
          if (filteredAuthors.isEmpty) {
            return const _AuthorManagementEmptyState(inline: false);
          }
          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double cardHeight = metadataPanelCardHeight(
                constraints: constraints,
                itemCount: filteredAuthors.length,
                config: _AuthorStyles.listHeightConfig,
              );
              return Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: double.infinity,
                  height: cardHeight,
                  child: _AuthorListCard(
                    layoutTier: layoutTier,
                    authors: filteredAuthors,
                  ),
                ),
              );
            },
          );
        },
        loading: () => const _AuthorManagementLoadingState(inline: false),
        error: (Object e, StackTrace _) =>
            _AuthorManagementErrorState(error: e, inline: false),
      ),
    );
  }
}

class AuthorManagementSliverGroup extends ConsumerWidget {
  const AuthorManagementSliverGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authorsAsync = ref.watch(allAuthorsProvider);
    final List<Author> filteredAuthors = ref.watch(filteredAuthorsProvider);
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;

    return authorsAsync.when(
      data: (_) {
        if (filteredAuthors.isEmpty) {
          return SliverPadding(
            padding: EdgeInsets.only(
              bottom: tokens.layout.contentVerticalPadding + 24,
            ),
            sliver: const SliverToBoxAdapter(
              child: _AuthorManagementEmptyState(inline: true),
            ),
          );
        }
        return SliverPadding(
          padding: EdgeInsets.only(
            bottom: tokens.layout.contentVerticalPadding + 24,
          ),
          sliver: SliverMainAxisGroup(
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: _AuthorListHeader(
                  totalCount: filteredAuthors.length,
                  compactStyle: true,
                ),
              ),
              SliverList.separated(
                itemCount: filteredAuthors.length,
                itemBuilder: (BuildContext context, int index) {
                  final Author author = filteredAuthors[index];
                  return Consumer(
                    builder:
                        (BuildContext context, WidgetRef ref, Widget? child) {
                          final bool isSelected = ref.watch(
                            authorSelectionProvider.select(
                              (Set<Author> selected) =>
                                  selected.contains(author),
                            ),
                          );
                          return _AuthorRow(
                            layoutTier: MetadataLayoutTier.compact,
                            author: author,
                            isSelected: isSelected,
                          );
                        },
                  );
                },
                separatorBuilder: (BuildContext context, int index) =>
                    Divider(height: 1, color: cs.hentai.borderSubtle),
              ),
            ],
          ),
        );
      },
      loading: () => SliverPadding(
        padding: EdgeInsets.only(
          bottom: tokens.layout.contentVerticalPadding + 24,
        ),
        sliver: const SliverToBoxAdapter(
          child: _AuthorManagementLoadingState(inline: true),
        ),
      ),
      error: (Object e, StackTrace _) => SliverPadding(
        padding: EdgeInsets.only(
          bottom: tokens.layout.contentVerticalPadding + 24,
        ),
        sliver: SliverToBoxAdapter(
          child: _AuthorManagementErrorState(error: e, inline: true),
        ),
      ),
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
  static const MetadataPanelHeightConfig listHeightConfig =
      kMetadataPanelHeightDefaultConfig;
}

class _AuthorListCard extends StatelessWidget {
  const _AuthorListCard({
    required this.layoutTier,
    required this.authors,
  });

  final MetadataLayoutTier layoutTier;
  final List<Author> authors;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return MetadataPanelListCard(
      radius: _AuthorStyles.listRadius,
      child: Column(
        children: <Widget>[
          _AuthorListHeader(totalCount: authors.length),
          Expanded(
            child: ListView.separated(
              itemCount: authors.length,
              itemBuilder: (BuildContext context, int index) {
                final Author author = authors[index];
                return Consumer(
                  builder:
                      (BuildContext context, WidgetRef ref, Widget? child) {
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
                );
              },
              separatorBuilder: (BuildContext context, int index) =>
                  Divider(height: 1, color: cs.hentai.borderSubtle),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthorListHeader extends ConsumerWidget {
  const _AuthorListHeader({
    required this.totalCount,
    this.compactStyle = false,
  });

  final int totalCount;
  final bool compactStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final int selectionCount = ref.watch(
      authorSelectionProvider.select((Set<Author> s) => s.length),
    );
    return Container(
      padding: _AuthorStyles.listHeaderPadding,
      decoration: BoxDecoration(
        color: compactStyle ? Colors.transparent : cs.surfaceContainerHighest,
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
  const _AuthorManagementLoadingState({required this.inline});

  final bool inline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Widget indicator = CircularProgressIndicator(
      strokeWidth: 2.2,
      color: theme.colorScheme.primary,
    );
    if (inline) {
      return Padding(
        padding: _AuthorStyles.statusLoadingPadding,
        child: Center(child: indicator),
      );
    }
    return StatusCardShell(
      padding: _AuthorStyles.statusLoadingPadding,
      borderRadius: _AuthorStyles.statusCardRadius,
      child: Center(child: indicator),
    );
  }
}

class _AuthorManagementErrorState extends StatelessWidget {
  const _AuthorManagementErrorState({
    required this.error,
    required this.inline,
  });

  final Object error;
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final TextStyle style = TextStyle(
      fontSize: kMetadataPanelSubtitleFontSize,
      color: theme.colorScheme.hentai.textTertiary,
    );
    if (inline) {
      return Padding(
        padding: _AuthorStyles.statusErrorPadding,
        child: Text('$error', style: style),
      );
    }
    return StatusCardShell(
      padding: _AuthorStyles.statusErrorPadding,
      borderRadius: _AuthorStyles.statusCardRadius,
      child: Text('$error', style: style),
    );
  }
}

class _AuthorManagementEmptyState extends StatelessWidget {
  const _AuthorManagementEmptyState({required this.inline});

  final bool inline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final Widget content = Column(
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
    );
    if (inline) {
      return Padding(
        padding: _AuthorStyles.statusEmptyPadding,
        child: Center(child: content),
      );
    }
    return StatusCardShell(
      padding: _AuthorStyles.statusEmptyPadding,
      borderRadius: _AuthorStyles.statusCardRadius,
      child: content,
    );
  }
}
