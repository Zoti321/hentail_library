import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/domain/entity/comic/tag.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../dialogs/tag_name_editor_dialog.dart';
import '../tag_management_styles.dart';

class TagRow extends ConsumerWidget {
  const TagRow({super.key, required this.tag, required this.isSelected});

  final Tag tag;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final iconButtonStyle = IconButton.styleFrom(
      minimumSize: TagManagementStyles.iconButtonSize,
      fixedSize: TagManagementStyles.iconButtonSize,
      padding: EdgeInsets.zero,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      overlayColor: cs.primary.withAlpha(14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TagManagementStyles.iconButtonRadius),
      ),
    );

    return TagRowInteractionShell(
      child: InkWell(
        onTap: () => ref.read(tagSelectionProvider.notifier).toggle(tag),
        child: Padding(
          padding: TagManagementStyles.rowPadding,
          child: Row(
            spacing: 12,
            children: [
              IconButton(
                tooltip: isSelected ? '取消选中' : '选中',
                onPressed: () =>
                    ref.read(tagSelectionProvider.notifier).toggle(tag),
                style: iconButtonStyle,
                icon: Icon(
                  isSelected
                      ? LucideIcons.squareCheckBig
                      : LucideIcons.square,
                  size: 16,
                  color: isSelected ? cs.primary : cs.textTertiary,
                ),
              ),
              Expanded(
                child: Text(
                  tag.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: cs.textPrimary,
                  ),
                ),
              ),
              IconButton(
                tooltip: '重命名',
                style: iconButtonStyle,
                icon: const Icon(LucideIcons.squarePen, size: 16),
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
                        await ref.read(tagActionsProvider).renameTag(tag, value);
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TagRowInteractionShell extends StatelessWidget {
  const TagRowInteractionShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Theme(
      data: theme.copyWith(
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: cs.primary.withAlpha(10),
      ),
      child: Material(
        color: cs.surface,
        child: child,
      ),
    );
  }
}

