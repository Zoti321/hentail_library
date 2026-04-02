import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/domain/entity/comic/tag.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/widgets/input/custom_text_field.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'dialogs/tag_confirm_delete_dialog.dart';
import 'dialogs/tag_name_editor_dialog.dart';
import 'tag_management_styles.dart';

class TagManagementHeader extends ConsumerWidget {
  const TagManagementHeader({super.key, required this.selectionCount});

  final int selectionCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
                  fontSize: TagManagementStyles.titleFontSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                  color: cs.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '查看、添加、重命名以及批量删除分类标签',
                style: TextStyle(
                  color: cs.textTertiary,
                  fontSize: TagManagementStyles.subtitleFontSize,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  const _MetaChip(icon: LucideIcons.tags, label: '标签'),
                  if (selectionCount > 0)
                    _MetaChip(
                      icon: LucideIcons.circleCheckBig,
                      label: '已选 $selectionCount',
                      highlighted: true,
                    ),
                ],
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
                onChanged: (value) =>
                    ref.read(tagFilterProvider.notifier).setQuery(value),
              ),
            ),
            FilledButton.icon(
              onPressed: () async {
                await showDialog<void>(
                  context: context,
                  barrierColor: Colors.transparent,
                  builder: (context) => TagNameEditorDialog(
                    title: '添加标签',
                    labelText: '名称',
                    hintText: '输入标签名称…',
                    initialValue: '',
                    onSubmit: (value) async {
                      await ref
                          .read(tagActionsProvider)
                          .addTag(Tag(name: value));
                    },
                  ),
                );
              },
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('添加标签'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            if (selectionCount > 0)
              OutlinedButton.icon(
                onPressed: () async {
                  final confirmed =
                      await showDialog<bool>(
                        context: context,
                        barrierColor: Colors.transparent,
                        builder: (context) =>
                            TagConfirmDeleteDialog(count: selectionCount),
                      ) ??
                      false;
                  if (!confirmed) return;
                  final tags = ref
                      .read(tagSelectionProvider)
                      .toList(growable: false);
                  await ref.read(tagActionsProvider).deleteTags(tags);
                },
                icon: const Icon(LucideIcons.trash2, size: 16),
                label: Text('删除已选（$selectionCount）'),
                style: OutlinedButton.styleFrom(
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

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = highlighted
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    final bgColor = highlighted
        ? theme.colorScheme.primaryContainer.withAlpha(130)
        : theme.colorScheme.surfaceContainerHighest;

    return Container(
      padding: TagManagementStyles.metaChipPadding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(TagManagementStyles.metaChipRadius),
        border: Border.all(color: theme.colorScheme.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: TagManagementStyles.metaChipIconSize,
            color: iconColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: TagManagementStyles.metaChipFontSize,
              fontWeight: FontWeight.w600,
              color: highlighted
                  ? theme.colorScheme.primary
                  : theme.colorScheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

