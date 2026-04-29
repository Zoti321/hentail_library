import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/presentation/theme/theme.dart';
import 'package:hentai_library/model/entity/comic/tag.dart';
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

class TagManagementPanel extends ConsumerWidget {
  const TagManagementPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> openAddTagDialog() async {
      await showDialog<void>(
        context: context,
        builder: (context) => TagNameEditorDialog(
          title: '添加标签',
          labelText: '名称',
          hintText: '输入标签名称…',
          initialValue: '',
          onSubmit: (value) async {
            await ref.read(tagActionsProvider).addTag(Tag(name: value));
          },
        ),
      );
    }

    final tagsAsync = ref.watch(allTagsProvider);
    final List<Tag> filteredTags = ref.watch(filteredTagsProvider);
    final AppThemeTokens tokens = context.tokens;
    final EdgeInsets contentPadding = tokens.layout.contentAreaPadding.copyWith(
      bottom: tokens.layout.contentVerticalPadding + 24,
    );
    return Padding(
      padding: contentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _TagManagementHeader(onAddTag: openAddTagDialog),
          const SizedBox(height: 12),
          const _TagBulkDeleteBar(),
          const SizedBox(height: 20),
          Expanded(
            child: tagsAsync.when(
              data: (_) {
                if (filteredTags.isEmpty) {
                  return const _TagManagementEmptyState();
                }
                return LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final double cardHeight =
                        MetadataPanelHeightCalculator.calculateCardHeight(
                          constraints: constraints,
                          itemCount: filteredTags.length,
                          config: _TagStyles.listHeightConfig,
                        );
                    return Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: double.infinity,
                        height: cardHeight,
                        child: _TagListCard(tags: filteredTags),
                      ),
                    );
                  },
                );
              },
              loading: () => const _TagManagementLoadingCard(),
              error: (Object e, StackTrace _) =>
                  _TagManagementErrorCard(error: e),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagStyles {
  const _TagStyles._();

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

class _TagManagementLoadingCard extends StatelessWidget {
  const _TagManagementLoadingCard();

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

class _TagManagementErrorCard extends StatelessWidget {
  const _TagManagementErrorCard({required this.error});

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
          fontSize: _TagStyles.subtitleFontSize,
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
    return StatusCardShell(
      padding: _TagStyles.statusEmptyPadding,
      borderRadius: _TagStyles.statusCardRadius,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.tags, size: 32, color: cs.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            '暂无标签',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.hentai.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '你可以从这里添加、重命名或删除标签。',
            style: TextStyle(
              fontSize: _TagStyles.subtitleFontSize,
              color: cs.hentai.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TagManagementHeader extends ConsumerWidget {
  const _TagManagementHeader({required this.onAddTag});

  final Future<void> Function() onAddTag;

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
                '标签管理',
                style: TextStyle(
                  fontSize: _TagStyles.titleFontSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                  color: cs.hentai.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '查看、添加、重命名以及批量删除分类标签',
                style: TextStyle(
                  color: cs.hentai.textTertiary,
                  fontSize: _TagStyles.subtitleFontSize,
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
                hintText: '搜索标签名称…',
                onChanged: (String value) =>
                    ref.read(tagFilterProvider.notifier).setQuery(value),
              ),
            ),
            FilledButton.icon(
              onPressed: onAddTag,
              icon: const Icon(LucideIcons.plus, size: 16),
              label: Text('添加标签 ($shortcutLabel)'),
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

class _TagBulkDeleteBar extends ConsumerWidget {
  const _TagBulkDeleteBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int selectionCount = ref.watch(
      tagSelectionProvider.select((Set<Tag> s) => s.length),
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
              showInfoToast(context, '此操作将删除已选中的标签，请先勾选列表中的标签。');
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
            final List<Tag> tags = ref
                .read(tagSelectionProvider)
                .toList(growable: false);
            await ref.read(tagActionsProvider).deleteTags(tags);
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

class _TagListCard extends StatelessWidget {
  const _TagListCard({required this.tags});

  final List<Tag> tags;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return MetadataPanelListCard(
      radius: _TagStyles.listRadius,
      child: Column(
        children: <Widget>[
          _TagListHeader(totalCount: tags.length),
          Expanded(
            child: ListView.separated(
              itemCount: tags.length,
              itemBuilder: (BuildContext context, int index) {
                final Tag tag = tags[index];
                return Consumer(
                  builder: (BuildContext context, WidgetRef ref, Widget? child) {
                    final bool isSelected = ref.watch(
                      tagSelectionProvider.select(
                        (Set<Tag> selected) => selected.contains(tag),
                      ),
                    );
                    return _TagRow(tag: tag, isSelected: isSelected);
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

class _TagListHeader extends ConsumerWidget {
  const _TagListHeader({required this.totalCount});

  final int totalCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
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
            '全部标签',
            style: TextStyle(
              fontSize: _TagStyles.listHeaderFontSize,
              fontWeight: FontWeight.w600,
              color: cs.hentai.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '共 $totalCount 条',
            style: TextStyle(
              fontSize: _TagStyles.listHeaderFontSize,
              color: cs.hentai.textTertiary,
            ),
          ),
          if (selectionCount > 0) ...[
            const SizedBox(width: 12),
            Text(
              '已选 $selectionCount',
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
  const _TagRow({required this.tag, required this.isSelected});

  final Tag tag;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
                tooltip: isSelected ? '取消选中' : '选中',
                foregroundColor:
                    isSelected ? cs.primary : cs.hentai.textTertiary,
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
              GhostButton.icon(
                icon: LucideIcons.squarePen,
                iconSize: 16,
                size: _TagStyles.iconButtonSize.width,
                borderRadius: _TagStyles.iconButtonRadius,
                tooltip: '重命名',
                delayTooltipThreeSeconds: true,
                hoverColor: cs.primary.withAlpha(10),
                overlayColor: cs.primary.withAlpha(14),
                onPressed: () async {
                  await showDialog<void>(
                    context: context,
                    builder: (context) => TagNameEditorDialog(
                      title: '重命名标签',
                      labelText: '新名称',
                      hintText: '输入新的标签名称…',
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
              ),
              GhostButton.icon(
                tooltip: '删除',
                semanticLabel: '删除',
                icon: LucideIcons.trash2,
                iconSize: 16,
                size: _TagStyles.iconButtonSize.width,
                borderRadius: _TagStyles.iconButtonRadius,
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
                    await ref.read(tagActionsProvider).deleteTag(tag);
                    if (context.mounted) {
                      showSuccessToast(context, '已删除标签');
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
