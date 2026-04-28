import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/model/entity/comic/comic.dart';
import 'package:hentai_library/model/entity/comic/series.dart';
import 'package:hentai_library/model/entity/comic/series_item.dart';
import 'package:hentai_library/model/entity/series_reading_history.dart';
import 'package:hentai_library/presentation/providers/aggregates/series_aggregate_notifier.dart';
import 'package:hentai_library/presentation/providers/aggregates/comic_aggregate_notifier.dart';
import 'package:hentai_library/presentation/providers/deps/repos.dart';
import 'package:hentai_library/presentation/dto/comic_cover_display_data.dart';
import 'package:hentai_library/presentation/providers/pages/library/library_page_comics_providers.dart';
import 'package:hentai_library/presentation/providers/pages/reader/reader_page_notifier.dart';
import 'package:hentai_library/presentation/providers/pages/series_management/series_add_comics_dialog_notifier.dart';
import 'package:hentai_library/presentation/providers/pages/series_management/series_management_notifier.dart';
import 'package:hentai_library/presentation/ui/shared/routing/reader_route_args.dart';

class MobileSeriesDetailPage extends ConsumerWidget {
  const MobileSeriesDetailPage({super.key, required this.seriesName});
  final String seriesName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Series>> seriesAsync = ref.watch(allSeriesProvider);
    return seriesAsync.when(
      data: (List<Series> seriesList) {
        Series? target;
        for (final Series series in seriesList) {
          if (series.name == seriesName) {
            target = series;
            break;
          }
        }
        if (target == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('系列详情')),
            body: const Center(child: Text('未找到该系列')),
          );
        }
        return _MobileSeriesDetailBody(series: target);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (Object error, StackTrace stackTrace) => Scaffold(
        appBar: AppBar(title: const Text('系列详情')),
        body: Center(child: Text('加载失败：$error')),
      ),
    );
  }
}

class _MobileSeriesDetailBody extends ConsumerWidget {
  const _MobileSeriesDetailBody({required this.series});
  final Series series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<SeriesItem> sortedItems = List<SeriesItem>.from(series.items)
      ..sort((SeriesItem a, SeriesItem b) => a.order.compareTo(b.order));
    final String? coverComicId = series.coverItem?.comicId;
    final ComicCoverDisplayData? coverData = coverComicId == null
        ? null
        : ref
              .watch(comicCoverDisplayProvider(comicId: coverComicId))
              .maybeWhen(
                data: (ComicCoverDisplayData? value) => value,
                orElse: () => null,
              );
    return Scaffold(
      appBar: AppBar(
        title: Text(series.name),
        actions: <Widget>[
          IconButton(
            tooltip: '重命名',
            onPressed: () => _showRenameDialog(context, ref, series),
            icon: const Icon(Icons.drive_file_rename_outline),
          ),
          IconButton(
            tooltip: '删除系列',
            onPressed: () => _deleteSeries(context, ref, series),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Card(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 100,
                      height: 150,
                      child: _mobileSeriesCoverImage(
                        coverData,
                        width: 100,
                        height: 150,
                        placeholder: ColoredBox(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          child: const Icon(
                            Icons.collections_bookmark_outlined,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          series.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text('共 ${sortedItems.length} 本漫画'),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => _openSeriesReader(
                            context,
                            ref,
                            series,
                            sortedItems,
                          ),
                          icon: const Icon(Icons.menu_book_outlined),
                          label: const Text('阅读系列'),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            OutlinedButton.icon(
                              onPressed: () =>
                                  _openManageItemsSheet(context, ref, series),
                              icon: const Icon(Icons.playlist_add_outlined),
                              label: const Text('管理条目'),
                            ),
                            OutlinedButton.icon(
                              onPressed: sortedItems.length < 2
                                  ? null
                                  : () => _openReorderSheet(
                                      context,
                                      ref,
                                      series,
                                      sortedItems,
                                    ),
                              icon: const Icon(Icons.reorder),
                              label: const Text('调整顺序'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: sortedItems.isEmpty
                ? const Center(child: Text('系列内暂无漫画，请先添加。'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: sortedItems.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (BuildContext context, int index) {
                      final SeriesItem item = sortedItems[index];
                      return _SeriesComicTile(
                        seriesName: series.name,
                        item: item,
                        index: index,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSeriesReader(
    BuildContext context,
    WidgetRef ref,
    Series targetSeries,
    List<SeriesItem> sortedItems,
  ) async {
    if (sortedItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('系列内暂无漫画')));
      return;
    }
    final SeriesReadingHistory? history = await ref
        .read(readingHistoryRepoProvider)
        .getSeriesReadingBySeriesName(targetSeries.name);
    String comicId = sortedItems.first.comicId;
    if (history != null) {
      final bool exists = sortedItems.any(
        (SeriesItem item) => item.comicId == history.lastReadComicId,
      );
      if (exists) {
        comicId = history.lastReadComicId;
      }
    }
    if (!context.mounted) {
      return;
    }
    context.pushNamed(
      ReaderRouteArgs.readerRouteName,
      queryParameters: ReaderRouteArgs(
        comicId: comicId,
        readType: ReaderRouteArgs.readTypeSeries,
        seriesName: targetSeries.name,
      ).toQueryParameters(),
    );
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    Series targetSeries,
  ) async {
    final TextEditingController controller = TextEditingController(
      text: targetSeries.name,
    );
    final String? renamed = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('重命名系列'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            onSubmitted: (String value) {
              Navigator.of(dialogContext).pop(value.trim());
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
    final String newName = (renamed ?? '').trim();
    if (newName.isEmpty || newName == targetSeries.name) {
      return;
    }
    try {
      await ref.read(seriesActionsProvider).rename(targetSeries.name, newName);
      if (!context.mounted) {
        return;
      }
      final String encoded = Uri.encodeComponent(newName);
      context.go('/series/$encoded');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('系列已重命名')));
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('重命名失败：$error')));
    }
  }

  Future<void> _deleteSeries(
    BuildContext context,
    WidgetRef ref,
    Series targetSeries,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('删除系列'),
          content: Text('确认删除系列「${targetSeries.name}」吗？'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    try {
      await ref.read(seriesActionsProvider).delete(targetSeries.name);
      if (!context.mounted) {
        return;
      }
      context.go('/manage');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('系列已删除')));
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('删除失败：$error')));
    }
  }

  Future<void> _openManageItemsSheet(
    BuildContext context,
    WidgetRef ref,
    Series targetSeries,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return _SeriesManageItemsSheet(series: targetSeries);
      },
    );
  }

  Future<void> _openReorderSheet(
    BuildContext context,
    WidgetRef ref,
    Series targetSeries,
    List<SeriesItem> sortedItems,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return _SeriesReorderSheet(
          seriesName: targetSeries.name,
          sortedItems: sortedItems,
        );
      },
    );
  }
}

class _SeriesComicTile extends ConsumerWidget {
  const _SeriesComicTile({
    required this.seriesName,
    required this.item,
    required this.index,
  });

  final String seriesName;
  final SeriesItem item;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String title = _resolveComicTitle(ref, item.comicId);
    final ComicCoverDisplayData? coverData = ref
        .watch(comicCoverDisplayProvider(comicId: item.comicId))
        .maybeWhen(
          data: (ComicCoverDisplayData? value) => value,
          orElse: () => null,
        );
    return Card(
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 38,
            height: 52,
            child: _mobileSeriesCoverImage(
              coverData,
              width: 38,
              height: 52,
              placeholder: ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.image_not_supported_outlined, size: 16),
              ),
            ),
          ),
        ),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('序号 ${index + 1}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          context.pushNamed(
            ReaderRouteArgs.readerRouteName,
            queryParameters: ReaderRouteArgs(
              comicId: item.comicId,
              readType: ReaderRouteArgs.readTypeSeries,
              seriesName: seriesName,
            ).toQueryParameters(),
          );
        },
      ),
    );
  }
}

class _SeriesManageItemsSheet extends ConsumerStatefulWidget {
  const _SeriesManageItemsSheet({required this.series});
  final Series series;

  @override
  ConsumerState<_SeriesManageItemsSheet> createState() =>
      _SeriesManageItemsSheetState();
}

class _SeriesManageItemsSheetState
    extends ConsumerState<_SeriesManageItemsSheet> {
  late final TextEditingController _queryController;
  late final SeriesAddComicsDialogNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
    _notifier = ref.read(seriesAddComicsDialogProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ComicAggregateState libraryPage = ref.read(comicAggregateProvider);
      _notifier.reset();
      _notifier.updateSource(
        comics: libraryPage.rawList,
        existingComicIdsInSeriesOrder: _existingComicIdsInSeriesOrder(
          widget.series,
        ),
      );
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    _notifier.reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(comicAggregateProvider, (
      ComicAggregateState? prev,
      ComicAggregateState next,
    ) {
      _notifier.updateSource(
        comics: next.rawList,
        existingComicIdsInSeriesOrder: _existingComicIdsInSeriesOrder(
          widget.series,
        ),
      );
    });
    final SeriesAddComicsDialogState state = ref.watch(
      seriesAddComicsDialogProvider,
    );
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.82,
          child: Column(
            children: <Widget>[
              const SizedBox(height: 12),
              Text(
                '管理「${widget.series.name}」中的漫画',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: TextField(
                  controller: _queryController,
                  decoration: const InputDecoration(
                    labelText: '搜索漫画',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _notifier.setQuery,
                ),
              ),
              Expanded(
                child: state.visibleComics.isEmpty
                    ? const Center(child: Text('没有可显示的漫画'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        itemCount: state.visibleComics.length,
                        separatorBuilder: (BuildContext context, int index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (BuildContext context, int index) {
                          final Comic comic = state.visibleComics[index];
                          final bool selected = state.selectedComicIdsInOrder
                              .contains(comic.comicId);
                          final int order = state.selectedComicIdsInOrder
                              .indexOf(comic.comicId);
                          return Card(
                            child: CheckboxListTile(
                              value: selected,
                              onChanged: state.submitting
                                  ? null
                                  : (bool? value) {
                                      _notifier.toggleSelected(comic.comicId);
                                    },
                              title: Text(
                                comic.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: selected
                                  ? Text('顺序 ${order + 1}')
                                  : (comic.authors.isEmpty
                                        ? null
                                        : Text(
                                            comic.authors
                                                .map((a) => a.name)
                                                .join(' / '),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          )),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: state.submitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('取消'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: state.canSubmit ? _submit : null,
                        child: state.submitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                '确认 (${state.selectedComicIdsInOrder.length})',
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    try {
      final SeriesAddComicsSubmitSummary? summary = await _notifier.submit(
        seriesName: widget.series.name,
        existingItems: widget.series.items,
      );
      if (!mounted || summary == null) {
        return;
      }
      if (!summary.hasAnyChange) {
        Navigator.of(context).pop();
        return;
      }
      final String message = _buildSummaryText(summary);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存失败：$error')));
    }
  }

  String _buildSummaryText(SeriesAddComicsSubmitSummary summary) {
    final List<String> parts = <String>[];
    if (summary.removedFromSeriesCount > 0) {
      parts.add('移出 ${summary.removedFromSeriesCount} 本');
    }
    if (summary.orderChanged) {
      parts.add('顺序已更新');
    }
    if (summary.addedCount > 0) {
      parts.add('新增 ${summary.addedCount} 本');
    }
    if (parts.isEmpty) {
      return '系列已更新';
    }
    return parts.join('，');
  }
}

class _SeriesReorderSheet extends ConsumerStatefulWidget {
  const _SeriesReorderSheet({
    required this.seriesName,
    required this.sortedItems,
  });

  final String seriesName;
  final List<SeriesItem> sortedItems;

  @override
  ConsumerState<_SeriesReorderSheet> createState() =>
      _SeriesReorderSheetState();
}

class _SeriesReorderSheetState extends ConsumerState<_SeriesReorderSheet> {
  late final List<SeriesItem> _items;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _items = List<SeriesItem>.from(widget.sortedItems);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(
          children: <Widget>[
            const SizedBox(height: 12),
            Text('调整顺序', style: Theme.of(context).textTheme.titleMedium),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                itemCount: _items.length,
                onReorder: (int oldIndex, int newIndex) {
                  setState(() {
                    int target = newIndex;
                    if (target > oldIndex) {
                      target -= 1;
                    }
                    final SeriesItem item = _items.removeAt(oldIndex);
                    _items.insert(target, item);
                  });
                },
                itemBuilder: (BuildContext context, int index) {
                  final SeriesItem item = _items[index];
                  final String title = _resolveComicTitle(ref, item.comicId);
                  return Card(
                    key: ValueKey<String>('${item.comicId}-$index'),
                    child: ListTile(
                      leading: const Icon(Icons.drag_handle),
                      title: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text('目标顺序 ${index + 1}'),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _saveOrder,
                      child: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('保存顺序'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveOrder() async {
    setState(() => _saving = true);
    try {
      final List<SeriesItem> normalized = _items
          .asMap()
          .entries
          .map(
            (MapEntry<int, SeriesItem> entry) =>
                SeriesItem(comicId: entry.value.comicId, order: entry.key),
          )
          .toList();
      await ref
          .read(librarySeriesRepoProvider)
          .setSeriesItemsOrder(widget.seriesName, normalized);
      ref.invalidate(allSeriesProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('顺序已保存')));
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存失败：$error')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

String _resolveComicTitle(WidgetRef ref, String comicId) {
  final Comic? comic = ref.read(libraryComicByIdProvider(comicId));
  if (comic != null && comic.title.isNotEmpty) {
    return comic.title;
  }
  if (comicId.length > 12) {
    return '${comicId.substring(0, 12)}…';
  }
  return comicId;
}

List<String> _existingComicIdsInSeriesOrder(Series series) {
  final List<SeriesItem> sorted = List<SeriesItem>.from(series.items)
    ..sort((SeriesItem a, SeriesItem b) => a.order.compareTo(b.order));
  return sorted.map((SeriesItem item) => item.comicId).toList();
}

Widget _mobileSeriesCoverImage(
  ComicCoverDisplayData? coverData, {
  required double width,
  required double height,
  required Widget placeholder,
}) {
  if (coverData == null) {
    return placeholder;
  }
  final Uint8List? memory = coverData.memoryBytes;
  if (memory != null) {
    return Image.memory(
      memory,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) {
            return placeholder;
          },
    );
  }
  final String? path = coverData.filePath;
  if (path != null) {
    return Image.file(
      File(path),
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) {
            return placeholder;
          },
    );
  }
  return placeholder;
}
