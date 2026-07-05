import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/entity/comic/series_item.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/core/dto/comic_cover_display_data.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/edit_series_dialog.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_comics_providers.dart';
import 'package:hentai_library/ui/features/reader/view_models/read_session_providers.dart';
import 'package:hentai_library/ui/features/shell/state/series_aggregate_notifier.dart';

class MobileSeriesDetailPage extends ConsumerWidget {
  const MobileSeriesDetailPage({super.key, required this.seriesId});
  final String seriesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Series>> seriesAsync = ref.watch(allSeriesProvider);
    return seriesAsync.when(
      data: (List<Series> seriesList) {
        Series? target;
        for (final Series series in seriesList) {
          if (series.id == seriesId) {
            target = series;
            break;
          }
        }
        if (target == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('系列详情')),
            body: Center(child: Text('未找到系列「$seriesId」')),
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
            tooltip: '编辑系列',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (BuildContext context) =>
                    EditSeriesDialog(series: series),
              );
            },
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
                        Text(series.volumeCountLabel),
                        if (series.serializationStatus !=
                            SerializationStatus.unknown) ...[
                          const SizedBox(height: 4),
                          Text(series.serializationStatus.label),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: sortedItems.isEmpty
                ? const Center(child: Text('系列内暂无漫画。'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: sortedItems.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (BuildContext context, int index) {
                      final SeriesItem item = sortedItems[index];
                      return _SeriesComicTile(item: item, index: index);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SeriesComicTile extends ConsumerWidget {
  const _SeriesComicTile({required this.item, required this.index});

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
          final String encoded = Uri.encodeComponent(item.comicId);
          context.go('/comic/$encoded');
        },
      ),
    );
  }
}

String _resolveComicTitle(WidgetRef ref, String comicId) {
  final Comic? comic = ref.watch(libraryComicByIdProvider(comicId)).value;
  if (comic != null && comic.title.isNotEmpty) {
    return comic.title;
  }
  if (comicId.length > 12) {
    return '${comicId.substring(0, 12)}…';
  }
  return comicId;
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
  final memory = coverData.memoryBytes;
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
