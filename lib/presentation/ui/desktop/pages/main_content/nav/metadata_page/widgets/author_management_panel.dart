import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/presentation/theme/theme.dart';
import 'package:hentai_library/model/entity/comic/author.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/chrome/status_card_shell.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/overlays/dialog/confirm/tag_confirm_delete_dialog.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/overlays/dialog/rename_tag_dialog.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/nav/metadata_page/widgets/metadata_panel_height.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/nav/metadata_page/widgets/metadata_panel_shell.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/actions/ghost_button.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/form/custom_text_field.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AuthorManagementPanel extends ConsumerWidget {
  const AuthorManagementPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> openAddAuthorDialog() async {
      await showDialog<void>(
        context: context,
        builder: (context) => TagNameEditorDialog(
          title: '添加作者',
          labelText: '名称',
          hintText: '输入作者名称…',
          initialValue: '',
          onSubmit: (value) async {
            await ref
                .read(authorActionsProvider)
                .addAuthor(Author(name: value));
          },
        ),
      );
    }

    final authorsAsync = ref.watch(allAuthorsProvider);
    final List<Author> filteredAuthors = ref.watch(filteredAuthorsProvider);
    final AppThemeTokens tokens = context.tokens;
    final EdgeInsets contentPadding = tokens.layout.contentAreaPadding.copyWith(
      bottom: tokens.layout.contentVerticalPadding + 24,
    );
    return Padding(
      padding: contentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _AuthorManagementHeader(onAddAuthor: openAddAuthorDialog),
          const SizedBox(height: 12),
          const _AuthorBulkDeleteBar(),
          const SizedBox(height: 20),
          Expanded(
            child: authorsAsync.when(
              data: (_) {
                if (filteredAuthors.isEmpty) {
                  return const _AuthorManagementEmptyState();
                }
                return LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final double cardHeight =
                        MetadataPanelHeightCalculator.calculateCardHeight(
                          constraints: constraints,
                          itemCount: filteredAuthors.length,
                          config: _AuthorStyles.listHeightConfig,
                        );
                    return Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: double.infinity,
                        height: cardHeight,
                        child: _AuthorListCard(authors: filteredAuthors),
                      ),
                    );
                  },
                );
              },
              loading: () => const _AuthorManagementLoadingCard(),
              error: (Object e, StackTrace _) =>
                  _AuthorManagementErrorCard(error: e),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthorStyles {
  const _AuthorStyles._();

  static const double titleFontSize = 26;
  static const double subtitleFontSize = 13;

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
      MetadataPanelHeightCalculator.defaultConfig;
}

class _AuthorManagementHeader extends ConsumerWidget {
  const _AuthorManagementHeader({required this.onAddAuthor});

  final Future<void> Function() onAddAuthor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String shortcutLabel = _shortcutLabel(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '作者管理',
                style: TextStyle(
                  fontSize: _AuthorStyles.titleFontSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                  color: cs.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '查看、添加、重命名以及批量删除作者',
                style: TextStyle(
                  color: cs.textTertiary,
                  fontSize: _AuthorStyles.subtitleFontSize,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.2,
              child: CustomTextField(
                hintText: '搜索作者名称…',
                onChanged: (String value) =>
                    ref.read(authorFilterProvider.notifier).setQuery(value),
              ),
            ),
            FilledButton.icon(
              onPressed: onAddAuthor,
              icon: const Icon(LucideIcons.plus, size: 16),
              label: Text('添加作者 ($shortcutLabel)'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AuthorBulkDeleteBar extends ConsumerWidget {
  const _AuthorBulkDeleteBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int selectionCount = ref.watch(
      authorSelectionProvider.select((Set<Author> s) => s.length),
    );
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        GhostButton.icon(
          tooltip: '删除已选',
          semanticLabel: '删除已选',
          icon: LucideIcons.trash2,
          size: 28,
          onPressed: () async {
            if (selectionCount == 0) {
              showInfoToast(context, '此操作将删除已选中的作者，请先勾选列表中的作者。');
              return;
            }
            final bool confirmed =
                await showDialog<bool>(
                  context: context,
                  builder: (BuildContext dialogContext) =>
                      TagConfirmDeleteDialog(count: selectionCount),
                ) ??
                false;
            if (!confirmed) {
              return;
            }
            final List<Author> authors = ref
                .read(authorSelectionProvider)
                .toList(growable: false);
            await ref.read(authorActionsProvider).deleteAuthors(authors);
          },
          delayTooltipThreeSeconds: true,
          overlayColor: cs.primary.withAlpha(14),
        ),
      ],
    );
  }
}

String _shortcutLabel(BuildContext context) {
  final TargetPlatform platform = Theme.of(context).platform;
  final bool isApple =
      platform == TargetPlatform.macOS || platform == TargetPlatform.iOS;
  return isApple ? '⌘N' : 'Ctrl+N';
}

class _AuthorListCard extends StatelessWidget {
  const _AuthorListCard({required this.authors});

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
                  builder: (BuildContext context, WidgetRef ref, Widget? child) {
                    final bool isSelected = ref.watch(
                      authorSelectionProvider.select(
                        (Set<Author> selected) => selected.contains(author),
                      ),
                    );
                    return _AuthorRow(author: author, isSelected: isSelected);
                  },
                );
              },
              separatorBuilder: (BuildContext context, int index) =>
                  Divider(height: 1, color: cs.borderSubtle),
            ),
          ),
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
        border: Border(bottom: BorderSide(color: cs.borderSubtle)),
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
              color: cs.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '共 $totalCount 条',
            style: TextStyle(
              fontSize: _AuthorStyles.listHeaderFontSize,
              color: cs.textTertiary,
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
  const _AuthorRow({required this.author, required this.isSelected});

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
                foregroundColor: isSelected ? cs.primary : cs.textTertiary,
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
                    color: cs.textPrimary,
                  ),
                ),
              ),
              GhostButton.icon(
                icon: LucideIcons.squarePen,
                iconSize: 16,
                size: _AuthorStyles.iconButtonSize.width,
                borderRadius: _AuthorStyles.iconButtonRadius,
                tooltip: '重命名',
                delayTooltipThreeSeconds: true,
                hoverColor: cs.primary.withAlpha(10),
                overlayColor: cs.primary.withAlpha(14),
                onPressed: () async {
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
              ),
              GhostButton.icon(
                tooltip: '删除',
                semanticLabel: '删除',
                icon: LucideIcons.trash2,
                iconSize: 16,
                size: _AuthorStyles.iconButtonSize.width,
                borderRadius: _AuthorStyles.iconButtonRadius,
                foregroundColor: cs.error,
                hoverColor: cs.primary.withAlpha(10),
                overlayColor: cs.primary.withAlpha(14),
                delayTooltipThreeSeconds: true,
                onPressed: () async {
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

class _AuthorManagementLoadingCard extends StatelessWidget {
  const _AuthorManagementLoadingCard();

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

class _AuthorManagementErrorCard extends StatelessWidget {
  const _AuthorManagementErrorCard({required this.error});

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
          fontSize: _AuthorStyles.subtitleFontSize,
          color: theme.colorScheme.textTertiary,
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
              color: cs.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '你可以从这里添加、重命名或删除作者。',
            style: TextStyle(
              fontSize: _AuthorStyles.subtitleFontSize,
              color: cs.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
