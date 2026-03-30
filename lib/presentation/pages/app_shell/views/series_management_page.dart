import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/config/app_fluent_color_scheme.dart';
import 'package:hentai_library/core/util/snackbar_util.dart';
import 'package:hentai_library/domain/entity/comic/series.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/widgets/input/custom_text_field.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SeriesManagementPage extends ConsumerWidget {
  const SeriesManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesAsync = ref.watch(allSeriesProvider);
    final query = ref.watch(seriesFilterProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Header(),
          const SizedBox(height: 20),
          seriesAsync.when(
            data: (series) {
              final filtered = _applyFilter(series, query);
              if (filtered.isEmpty) {
                return const _EmptyState();
              }
              return _SeriesList(series: filtered);
            },
            loading: () => const _LoadingCard(),
            error: (e, _) => _ErrorCard(error: e),
          ),
        ],
      ),
    );
  }

  List<Series> _applyFilter(List<Series> source, String query) {
    if (query.trim().isEmpty) return List<Series>.from(source);
    final q = query.trim().toLowerCase();
    return source.where((s) => s.name.toLowerCase().contains(q)).toList();
  }
}

class _Header extends ConsumerWidget {
  const _Header();

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
                '系列管理',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                  color: cs.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '创建、重命名或删除系列；删除系列仅移除归属关系，漫画仍保留在库中',
                style: TextStyle(color: cs.textTertiary, fontSize: 13),
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
                hintText: '搜索系列名称…',
                onChanged: (value) =>
                    ref.read(seriesFilterProvider.notifier).setQuery(value),
              ),
            ),
            FilledButton.icon(
              onPressed: () async {
                await showDialog<void>(
                  context: context,
                  builder: (context) => const _AddSeriesDialog(),
                );
              },
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('添加系列'),
            ),
          ],
        ),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        '加载失败：$error',
        style: TextStyle(color: cs.error, fontSize: 14),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          '暂无系列',
          style: TextStyle(fontSize: 14, color: cs.textTertiary),
        ),
      ),
    );
  }
}

class _SeriesList extends StatelessWidget {
  const _SeriesList({required this.series});

  final List<Series> series;

  @override
  Widget build(BuildContext context) {
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
              border: Border(bottom: BorderSide(color: cs.borderSubtle)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.layers, size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  '全部系列',
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
            itemCount: series.length,
            separatorBuilder: (context, _) =>
                Divider(height: 1, color: cs.borderSubtle),
            itemBuilder: (context, index) {
              final s = series[index];
              return _SeriesRow(series: s);
            },
          ),
        ],
      ),
    );
  }
}

class _SeriesRow extends ConsumerWidget {
  const _SeriesRow({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final count = series.items.length;

    return Material(
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    series.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: cs.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '包含 $count 本',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.textTertiary,
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
                  builder: (context) => _RenameSeriesDialog(series: series),
                );
              },
            ),
            IconButton(
              tooltip: '删除',
              icon: Icon(LucideIcons.trash2, size: 16, color: cs.error),
              onPressed: () async {
                final confirmed =
                    await showDialog<bool>(
                      context: context,
                      builder: (context) =>
                          _ConfirmDeleteSeriesDialog(series: series),
                    ) ??
                    false;
                if (!confirmed || !context.mounted) return;
                try {
                  await ref.read(seriesActionsProvider).delete(series.seriesId);
                  if (context.mounted) {
                    showSuccessSnackBar(context, '已删除系列');
                  }
                } catch (e) {
                  if (context.mounted) showErrorSnackBar(context, e);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AddSeriesDialog extends ConsumerStatefulWidget {
  const _AddSeriesDialog();

  @override
  ConsumerState<_AddSeriesDialog> createState() => _AddSeriesDialogState();
}

class _AddSeriesDialogState extends ConsumerState<_AddSeriesDialog> {
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
      await ref.read(seriesActionsProvider).create(name);
      if (mounted) {
        Navigator.of(context).pop();
        showSuccessSnackBar(context, '已添加系列');
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '添加系列',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '名称'),
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

class _RenameSeriesDialog extends ConsumerStatefulWidget {
  const _RenameSeriesDialog({required this.series});

  final Series series;

  @override
  ConsumerState<_RenameSeriesDialog> createState() =>
      _RenameSeriesDialogState();
}

class _RenameSeriesDialogState extends ConsumerState<_RenameSeriesDialog> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.series.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final newName = _controller.text.trim();
    if (newName.isEmpty || newName == widget.series.name) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(seriesActionsProvider)
          .rename(widget.series.seriesId, newName);
      if (mounted) {
        Navigator.of(context).pop();
        showSuccessSnackBar(context, '已重命名');
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '重命名系列',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: '新名称'),
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

class _ConfirmDeleteSeriesDialog extends StatelessWidget {
  const _ConfirmDeleteSeriesDialog({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context) {
    final count = series.items.length;
    final extra = count > 0
        ? '该系列包含 $count 本漫画，将移除系列归属，漫画仍保留在库中。'
        : '删除后无法恢复。';

    return AlertDialog(
      title: const Text('确认删除'),
      content: Text('确定删除系列「${series.name}」？$extra'),
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
