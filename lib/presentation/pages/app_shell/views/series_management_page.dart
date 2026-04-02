import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/core/util/snackbar_util.dart';
import 'package:hentai_library/domain/entity/comic/comic.dart';
import 'package:hentai_library/domain/entity/comic/series.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/widgets/dialog/fluent_dialog_shell.dart';
import 'package:hentai_library/presentation/widgets/form/fluent_text_field.dart';
import 'package:hentai_library/presentation/widgets/input/custom_text_field.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'series_management/series_management_states.dart';

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
                return const SeriesManagementEmptyState();
              }
              return _SeriesList(series: filtered);
            },
            loading: () => const SeriesManagementLoadingState(),
            error: (e, _) => SeriesManagementErrorState(error: e),
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
                  barrierColor: Colors.transparent,
                  builder: (context) => const _AddSeriesDialog(),
                );
              },
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('添加系列'),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.borderSubtle),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
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
                  Icon(
                    LucideIcons.layers,
                    size: 16,
                    color: cs.onSurfaceVariant,
                  ),
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
    final iconButtonStyle = IconButton.styleFrom(
      minimumSize: const Size(28, 28),
      fixedSize: const Size(28, 28),
      padding: EdgeInsets.zero,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      overlayColor: cs.primary.withAlpha(14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );

    return Material(
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          spacing: 12,
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
                    style: TextStyle(fontSize: 12, color: cs.textTertiary),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: '添加漫画',
              style: iconButtonStyle,
              icon: const Icon(LucideIcons.plus, size: 16),
              onPressed: () async {
                await showDialog<void>(
                  context: context,
                  barrierColor: Colors.transparent,
                  builder: (context) =>
                      _AddComicsToSeriesDialog(series: series),
                );
              },
            ),
            IconButton(
              tooltip: '重命名',
              style: iconButtonStyle,
              icon: const Icon(LucideIcons.squarePen, size: 16),
              onPressed: () async {
                await showDialog<void>(
                  context: context,
                  barrierColor: Colors.transparent,
                  builder: (context) => _RenameSeriesDialog(series: series),
                );
              },
            ),
            IconButton(
              tooltip: '删除',
              style: iconButtonStyle,
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
                  await ref.read(seriesActionsProvider).delete(series.name);
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

class _AddComicsToSeriesDialog extends ConsumerStatefulWidget {
  const _AddComicsToSeriesDialog({required this.series});

  final Series series;

  @override
  ConsumerState<_AddComicsToSeriesDialog> createState() =>
      _AddComicsToSeriesDialogState();
}

class _AddComicsToSeriesDialogState
    extends ConsumerState<_AddComicsToSeriesDialog> {
  late final ScrollController _listScrollController;

  @override
  void initState() {
    super.initState();
    _listScrollController = ScrollController();
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final notifier = ref.read(seriesAddComicsDialogProvider.notifier);
    try {
      final added = await notifier.submit(
        seriesName: widget.series.name,
        existingOrders: widget.series.items.map((e) => e.order).toList(),
      );
      if (!mounted || added <= 0) return;
      Navigator.of(context).pop();
      showSuccessSnackBar(context, '已添加 $added 本漫画');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final libraryPage = ref.watch(libraryPageProvider);
    final notifier = ref.read(seriesAddComicsDialogProvider.notifier);
    final existingComicIds = widget.series.items.map((e) => e.comicId).toSet();
    Future<void>(() {
      if (!mounted) return;
      notifier.updateSource(
        comics: libraryPage.rawList,
        existingComicIds: existingComicIds,
      );
    });
    final dialogState = ref.watch(seriesAddComicsDialogProvider);
    final listHeight = (MediaQuery.of(context).size.height * 0.45).clamp(
      280.0,
      420.0,
    );

    return FluentDialogShell(
      title: '向「${widget.series.name}」添加漫画',
      width: 520,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomTextField(hintText: '搜索漫画', onChanged: notifier.setQuery),
          const SizedBox(height: 12),
          SizedBox(
            height: listHeight,
            child: !libraryPage.hasReceivedFirstEmit
                ? const Center(child: CircularProgressIndicator())
                : dialogState.visibleComics.isEmpty
                ? Center(
                    child: Text(
                      '没有可显示的漫画',
                      style: TextStyle(color: cs.textTertiary, fontSize: 13),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Scrollbar(
                      thumbVisibility: true,
                      controller: _listScrollController,
                      child: ListView.separated(
                        controller: _listScrollController,
                        padding: const EdgeInsets.only(right: 14),
                        itemCount: dialogState.visibleComics.length,
                        separatorBuilder: (context, _) =>
                            Divider(height: 1, color: cs.borderSubtle),
                        itemBuilder: (context, index) {
                          final comic = dialogState.visibleComics[index];
                          return _ComicSelectableTile(
                            comic: comic,
                            state: dialogState,
                            onToggle: () =>
                                notifier.toggleSelected(comic.comicId),
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: dialogState.submitting
              ? null
              : () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('取消'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: dialogState.canSubmit ? _handleSubmit : null,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: dialogState.submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('确认添加 (${dialogState.selectedComicIdsInOrder.length})'),
        ),
      ],
    );
  }
}

class _ComicSelectableTile extends StatelessWidget {
  const _ComicSelectableTile({
    required this.comic,
    required this.state,
    required this.onToggle,
  });

  final Comic comic;
  final SeriesAddComicsDialogState state;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final id = comic.comicId;
    final orderIndex = state.selectedComicIdsInOrder.indexOf(id);
    final isSelected = orderIndex >= 0;
    final inSeries = state.existingComicIds.contains(id);
    final enabled = !inSeries && !state.submitting;

    return Theme(
      data: Theme.of(context).copyWith(
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: cs.primary.withAlpha(10),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        onTap: enabled ? onToggle : null,
        title: Text(
          comic.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: cs.textPrimary, fontSize: 13),
        ),
        subtitle: comic.authors.isEmpty
            ? null
            : Text(
                comic.authors.join(' / '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: cs.textTertiary, fontSize: 12),
              ),
        trailing: inSeries
            ? Text(
                '已在系列中',
                style: TextStyle(color: cs.textTertiary, fontSize: 12),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected)
                    Container(
                      width: 16,
                      height: 16,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: cs.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${orderIndex + 1}',
                        style: TextStyle(
                          color: cs.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  IconButton(
                    tooltip: isSelected ? '取消选中' : '选中',
                    onPressed: enabled ? onToggle : null,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(28, 28),
                      fixedSize: const Size(28, 28),
                      padding: EdgeInsets.zero,
                      splashFactory: NoSplash.splashFactory,
                      overlayColor: cs.primary.withAlpha(14),
                      highlightColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: Icon(
                      isSelected
                          ? LucideIcons.squareCheckBig
                          : LucideIcons.square,
                      size: 16,
                      color: enabled
                          ? (isSelected ? cs.primary : cs.textTertiary)
                          : cs.textDisabled,
                    ),
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
    return FluentDialogShell(
      title: '添加系列',
      content: FluentTextField(
        initialValue: _nameController.text,
        labelText: '名称',
        hintText: '输入系列名称…',
        onChanged: (value) => _nameController.text = value,
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('取消'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _saving ? null : _handleSave,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('保存'),
        ),
      ],
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
      await ref.read(seriesActionsProvider).rename(widget.series.name, newName);
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
    return FluentDialogShell(
      title: '重命名系列',
      content: FluentTextField(
        initialValue: _controller.text,
        labelText: '新名称',
        hintText: '输入新的系列名称…',
        onChanged: (value) => _controller.text = value,
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('取消'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _saving ? null : _handleSave,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('保存'),
        ),
      ],
    );
  }
}

class _ConfirmDeleteSeriesDialog extends StatelessWidget {
  const _ConfirmDeleteSeriesDialog({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context) {
    final count = series.items.length;
    final extra = count > 0 ? '该系列包含 $count 本漫画，将移除系列归属，漫画仍保留在库中。' : '删除后无法恢复。';

    return FluentDialogShell(
      title: '确认删除',
      content: Text('确定删除系列「${series.name}」？$extra'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('取消'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('删除'),
        ),
      ],
    );
  }
}
