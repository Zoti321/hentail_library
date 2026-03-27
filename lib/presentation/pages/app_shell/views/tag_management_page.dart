import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/config/app_fluent_color_scheme.dart';
import 'package:hentai_library/domain/entity/v2/library_tag.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TagManagementPage extends ConsumerWidget {
  const TagManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(allTagsProvider);
    final selection = ref.watch(tagSelectionProvider);
    final query = ref.watch(tagFilterProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(selectionCount: selection.length),
          const SizedBox(height: 20),
          tagsAsync.when(
            data: (tags) {
              final filtered = _applyFilter(tags, query);
              if (filtered.isEmpty) return _EmptyState();
              return _TagList(tags: filtered);
            },
            loading: () => const _LoadingCard(),
            error: (e, _) => _ErrorCard(error: e),
          ),
        ],
      ),
    );
  }

  List<LibraryTag> _applyFilter(List<LibraryTag> source, String query) {
    if (query.trim().isEmpty) return List<LibraryTag>.from(source);
    final q = query.trim().toLowerCase();
    return source.where((t) => t.name.toLowerCase().contains(q)).toList();
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
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

class _Header extends ConsumerWidget {
  const _Header({required this.selectionCount});
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
                  fontSize: 26,
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
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetaChip(
                    icon: LucideIcons.tags,
                    label: '标签',
                  ),
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
              width: 240,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cs.borderSubtle),
                ),
                child: TextField(
                  onChanged: (value) =>
                      ref.read(tagFilterProvider.notifier).setQuery(value),
                  decoration: const InputDecoration(
                    isDense: true,
                    prefixIcon: Icon(
                      LucideIcons.search,
                      size: 16,
                    ),
                    hintText: '搜索标签名称…',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: () async {
                await showDialog<void>(
                  context: context,
                  builder: (context) => const _AddTagDialog(),
                );
              },
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('添加标签'),
            ),
            if (selectionCount > 0)
              OutlinedButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => _ConfirmDeleteDialog(
                          count: selectionCount,
                        ),
                      ) ??
                      false;
                  if (!confirmed) return;
                  final tags =
                      ref.read(tagSelectionProvider).toList(growable: false);
                  await ref.read(tagActionsProvider).deleteTags(tags);
                },
                icon: const Icon(LucideIcons.trash2, size: 16),
                label: Text('删除已选（$selectionCount）'),
              ),
          ],
        ),
      ],
    );
  }
}

class _TagList extends ConsumerWidget {
  const _TagList({required this.tags});

  final List<LibraryTag> tags;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.borderSubtle),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(color: cs.borderSubtle),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.tags,
                  size: 16,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  '全部标签',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tags.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: cs.borderSubtle),
            itemBuilder: (context, index) {
              final tag = tags[index];
              final isSelected = ref.watch(tagSelectionProvider).contains(tag);
              return _TagRow(tag: tag, isSelected: isSelected);
            },
          ),
        ],
      ),
    );
  }
}

class _TagRow extends ConsumerWidget {
  const _TagRow({
    required this.tag,
    required this.isSelected,
  });

  final LibraryTag tag;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: isSelected
          ? cs.primaryContainer.withAlpha(60)
          : cs.surface,
      child: InkWell(
        onTap: () => ref.read(tagSelectionProvider.notifier).toggle(tag),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (_) =>
                    ref.read(tagSelectionProvider.notifier).toggle(tag),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tag.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: cs.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '重命名',
                icon: const Icon(LucideIcons.squarePen, size: 16),
                onPressed: () async {
                  await showDialog<void>(
                    context: context,
                    builder: (context) => _RenameTagDialog(tag: tag),
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

class _AddTagDialog extends ConsumerStatefulWidget {
  const _AddTagDialog();

  @override
  ConsumerState<_AddTagDialog> createState() => _AddTagDialogState();
}

class _AddTagDialogState extends ConsumerState<_AddTagDialog> {
  final TextEditingController _nameController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      final tag = LibraryTag(name: name);
      await ref.read(tagActionsProvider).addTag(tag);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '添加标签',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '名称',
              ),
              autofocus: true,
              onSubmitted: (_) => _handleSave(),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _saving ? null : _handleSave,
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RenameTagDialog extends ConsumerStatefulWidget {
  const _RenameTagDialog({required this.tag});

  final LibraryTag tag;

  @override
  ConsumerState<_RenameTagDialog> createState() => _RenameTagDialogState();
}

class _RenameTagDialogState extends ConsumerState<_RenameTagDialog> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.tag.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final newName = _controller.text.trim();
    if (newName.isEmpty || newName == widget.tag.name) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(tagActionsProvider)
          .renameTag(widget.tag, newName);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '重命名标签',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: '新名称',
              ),
              autofocus: true,
              onSubmitted: (_) => _handleSave(),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _saving ? null : _handleSave,
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmDeleteDialog extends StatelessWidget {
  const _ConfirmDeleteDialog({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('确认删除'),
      content: Text('将删除 $count 个标签，并同时从所有漫画中移除这些标签。此操作不可撤销。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('删除'),
        ),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 42),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.borderSubtle),
      ),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.borderSubtle),
      ),
      child: Text(
        '$error',
        style: TextStyle(
          fontSize: 13,
          color: theme.colorScheme.textTertiary,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.borderSubtle),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.tags,
            size: 32,
            color: cs.onSurfaceVariant,
          ),
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
              fontSize: 13,
              color: cs.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

