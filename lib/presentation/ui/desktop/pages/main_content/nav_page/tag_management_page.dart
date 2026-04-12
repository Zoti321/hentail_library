import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/domain/entity/comic/tag.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/common/status/status_card_shell.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/dialog/tag_confirm_delete_dialog.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/dialog/tag_name_editor_dialog.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/button/ghost_button.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/custom_toast.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/input/custom_text_field.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TagManagementPage extends ConsumerWidget {
  const TagManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> openAddTagDialog() async {
      await showDialog<void>(
        context: context,
        barrierColor: Colors.transparent,
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
    final selection = ref.watch(tagSelectionProvider);
    final query = ref.watch(tagFilterProvider);

    return _AddShortcutScope(
      onAdd: openAddTagDialog,
      child: SingleChildScrollView(
        padding: _TagStyles.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TagManagementHeader(
              selectionCount: selection.length,
              onAddTag: openAddTagDialog,
            ),
            const SizedBox(height: 20),
            tagsAsync.when(
              data: (tags) {
                final filtered = _applyFilter(tags, query);
                if (filtered.isEmpty) return const _TagManagementEmptyState();
                return _TagList(tags: filtered);
              },
              loading: () => const _TagManagementLoadingCard(),
              error: (e, _) => _TagManagementErrorCard(error: e),
            ),
          ],
        ),
      ),
    );
  }

  List<Tag> _applyFilter(List<Tag> source, String query) {
    if (query.trim().isEmpty) return List<Tag>.from(source);
    final q = query.trim().toLowerCase();
    return source.where((t) => t.name.toLowerCase().contains(q)).toList();
  }
}

class _TagStyles {
  const _TagStyles._();

  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: 48,
    vertical: 24,
  );

  static const double titleFontSize = 26;
  static const double subtitleFontSize = 13;

  static const double metaChipIconSize = 14;
  static const double metaChipFontSize = 12;
  static const double metaChipRadius = 8;
  static const EdgeInsets metaChipPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 6,
  );

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
          color: theme.colorScheme.textTertiary,
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
              color: cs.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '你可以从这里添加、重命名或删除标签。',
            style: TextStyle(
              fontSize: _TagStyles.subtitleFontSize,
              color: cs.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TagManagementHeader extends ConsumerWidget {
  const _TagManagementHeader({
    required this.selectionCount,
    required this.onAddTag,
  });

  final int selectionCount;
  final Future<void> Function() onAddTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
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
                  color: cs.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '查看、添加、重命名以及批量删除分类标签',
                style: TextStyle(
                  color: cs.textTertiary,
                  fontSize: _TagStyles.subtitleFontSize,
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
            Tooltip(
              message: '添加标签 ($shortcutLabel)',
              child: FilledButton.icon(
                onPressed: onAddTag,
                icon: const Icon(LucideIcons.plus, size: 16),
                label: Text('添加标签 ($shortcutLabel)'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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

class _AddIntent extends Intent {
  const _AddIntent();
}

class _AddShortcutScope extends StatelessWidget {
  const _AddShortcutScope({required this.child, required this.onAdd});

  final Widget child;
  final Future<void> Function() onAdd;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyN, control: true): _AddIntent(),
        SingleActivator(LogicalKeyboardKey.keyN, meta: true): _AddIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _AddIntent: CallbackAction<_AddIntent>(
            onInvoke: (_AddIntent intent) {
              if (_isTextInputFocused()) {
                return null;
              }
              onAdd();
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }

  bool _isTextInputFocused() {
    final FocusNode? node = FocusManager.instance.primaryFocus;
    final BuildContext? context = node?.context;
    if (context == null) {
      return false;
    }
    return context.widget is EditableText;
  }
}

String _shortcutLabel(BuildContext context) {
  final TargetPlatform platform = Theme.of(context).platform;
  final bool isApple =
      platform == TargetPlatform.macOS || platform == TargetPlatform.iOS;
  return isApple ? '⌘N' : 'Ctrl+N';
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
      padding: _TagStyles.metaChipPadding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(_TagStyles.metaChipRadius),
        border: Border.all(color: theme.colorScheme.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _TagStyles.metaChipIconSize, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: _TagStyles.metaChipFontSize,
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

class _TagList extends ConsumerWidget {
  const _TagList({required this.tags});

  final List<Tag> tags;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _TagListCard(
      child: Column(
        children: [
          const _TagListHeader(),
          _TagListView(tags: tags),
        ],
      ),
    );
  }
}

class _TagListCard extends StatelessWidget {
  const _TagListCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(_TagStyles.listRadius),
        border: Border.all(color: cs.borderSubtle),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_TagStyles.listRadius),
        child: child,
      ),
    );
  }
}

class _TagListHeader extends StatelessWidget {
  const _TagListHeader();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: _TagStyles.listHeaderPadding,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: cs.borderSubtle)),
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
              color: cs.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagListView extends ConsumerWidget {
  const _TagListView({required this.tags});

  final List<Tag> tags;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tags.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: cs.borderSubtle),
      itemBuilder: (context, index) {
        final tag = tags[index];
        final isSelected = ref.watch(tagSelectionProvider).contains(tag);
        return _TagRow(tag: tag, isSelected: isSelected);
      },
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

    return _TagRowInteractionShell(
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
                foregroundColor: isSelected ? cs.primary : cs.textTertiary,
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
                    color: cs.textPrimary,
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
                delayTooltipThreeSeconds: true,
                overlayColor: cs.primary.withAlpha(14),
                onPressed: () async {
                  final bool confirmed =
                      await showDialog<bool>(
                        context: context,
                        barrierColor: Colors.transparent,
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

class _TagRowInteractionShell extends StatelessWidget {
  const _TagRowInteractionShell({required this.child});

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
      child: Material(color: cs.surface, child: child),
    );
  }
}
