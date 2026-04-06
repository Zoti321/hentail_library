import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/core/util/snackbar_util.dart';
import 'package:hentai_library/domain/entity/comic/series.dart';
import 'package:hentai_library/domain/entity/comic/series_item.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/routes/routes.dart';
import 'package:hentai_library/presentation/widgets/dialog/add_comics_to_series_dialog.dart';
import 'package:hentai_library/presentation/widgets/dialog/rename_series_dialog.dart';
import 'package:hentai_library/presentation/widgets/dialog/reorder_series_items_dialog.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SeriesDetailPage extends ConsumerWidget {
  const SeriesDetailPage({super.key, required this.seriesName});

  final String seriesName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Series>> seriesAsync = ref.watch(allSeriesProvider);
    return seriesAsync.when(
      data: (List<Series> list) {
        Series? found;
        for (final Series s in list) {
          if (s.name == seriesName) {
            found = s;
            break;
          }
        }
        if (found == null) {
          return _SeriesNotFoundBody(seriesName: seriesName);
        }
        return _SeriesDetailBody(series: found);
      },
      loading: () => const _SeriesDetailLoadingBody(),
      error: (Object e, StackTrace _) => _SeriesDetailErrorBody(error: e),
    );
  }
}

class _SeriesDetailLoadingBody extends StatelessWidget {
  const _SeriesDetailLoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _SeriesDetailErrorBody extends StatelessWidget {
  const _SeriesDetailErrorBody({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '加载失败：$error',
            style: TextStyle(color: cs.error, fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.go('/local'),
            child: const Text('返回本地漫画'),
          ),
        ],
      ),
    );
  }
}

class _SeriesNotFoundBody extends StatelessWidget {
  const _SeriesNotFoundBody({required this.seriesName});

  final String seriesName;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '未找到系列「$seriesName」',
            style: TextStyle(fontSize: 14, color: cs.textTertiary),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.go('/local'),
            child: const Text('返回本地漫画'),
          ),
        ],
      ),
    );
  }
}

class _SeriesDetailBody extends ConsumerWidget {
  const _SeriesDetailBody({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<SeriesItem> sortedItems = List<SeriesItem>.from(series.items)
      ..sort((SeriesItem a, SeriesItem b) => a.order.compareTo(b.order));
    final ButtonStyle toolbarButtonStyle = FilledButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SeriesDetailHeader(series: series),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton.icon(
                onPressed: () {
                  if (sortedItems.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('系列内暂无漫画'),
                        behavior: SnackBarBehavior.floating,
                        margin: snackBarMargin(context),
                      ),
                    );
                    return;
                  }
                  appRouter.pushNamed(
                    '阅读页面',
                    pathParameters: <String, String>{
                      'id': sortedItems.first.comicId,
                    },
                    queryParameters: <String, String>{'series': series.name},
                  );
                },
                icon: const Icon(LucideIcons.bookOpen, size: 16),
                label: const Text('阅读系列'),
                style: toolbarButtonStyle,
              ),
              FilledButton.icon(
                onPressed: () async {
                  await showDialog<void>(
                    context: context,
                    barrierColor: Colors.transparent,
                    builder: (BuildContext context) => AddComicsToSeriesDialog(
                      key: ValueKey<String>(series.name),
                      series: series,
                    ),
                  );
                },
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('添加漫画'),
                style: toolbarButtonStyle,
              ),
              FilledButton.icon(
                onPressed: () {
                  if (series.items.length < 2) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('至少需要 2 本漫画才能调整顺序'),
                        behavior: SnackBarBehavior.floating,
                        margin: snackBarMargin(context),
                      ),
                    );
                    return;
                  }
                  showDialog<void>(
                    context: context,
                    barrierColor: Colors.transparent,
                    builder: (BuildContext context) =>
                        ReorderSeriesItemsDialog(series: series),
                  );
                },
                icon: const Icon(LucideIcons.arrowUpDown, size: 16),
                label: const Text('调整顺序'),
                style: toolbarButtonStyle,
              ),
              FilledButton.icon(
                onPressed: () async {
                  final String? newName = await showDialog<String>(
                    context: context,
                    barrierColor: Colors.transparent,
                    builder: (BuildContext context) =>
                        RenameSeriesDialog(series: series),
                  );
                  if (newName != null && context.mounted) {
                    context.goNamed(
                      '系列详情',
                      pathParameters: <String, String>{'name': newName},
                    );
                  }
                },
                icon: const Icon(LucideIcons.squarePen, size: 16),
                label: const Text('重命名'),
                style: toolbarButtonStyle,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.borderSubtle),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      border: Border(
                        bottom: BorderSide(color: cs.borderSubtle),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          LucideIcons.bookOpen,
                          size: 16,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '系列内漫画',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (sortedItems.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 32,
                      ),
                      child: Text(
                        '暂无漫画，点击「添加漫画」加入',
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.textTertiary,
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedItems.length,
                      separatorBuilder: (BuildContext context, int _) =>
                          Divider(height: 1, color: cs.borderSubtle),
                      itemBuilder: (BuildContext context, int index) {
                        final SeriesItem item = sortedItems[index];
                        return _SeriesComicRow(
                          item: item,
                          sequenceNumber: index + 1,
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeriesDetailHeader extends ConsumerWidget {
  const _SeriesDetailHeader({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final SeriesItem? coverItem = series.coverItem;
    final String? coverComicId = coverItem?.comicId;
    final String? coverPath = coverComicId != null
        ? ref
            .watch(comicCoverPathProvider(comicId: coverComicId))
            .maybeWhen(data: (String? v) => v, orElse: () => null)
        : null;
    final int count = series.items.length;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 96,
            height: 136,
            color: cs.imagePlaceholder,
            child: coverPath != null
                ? ExtendedImage.file(
                    File(coverPath),
                    fit: BoxFit.cover,
                    cacheWidth: 320,
                  )
                : Icon(
                    Icons.broken_image,
                    color: cs.iconSecondary,
                  ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                series.name,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                  color: cs.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '包含 $count 本',
                style: TextStyle(color: cs.textTertiary, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SeriesComicRow extends ConsumerWidget {
  const _SeriesComicRow({
    required this.item,
    required this.sequenceNumber,
  });

  final SeriesItem item;
  final int sequenceNumber;

  static String _titleForComic(WidgetRef ref, String comicId) {
    final String? title =
        ref.read(libraryPageProvider.notifier).comicById(comicId)?.title;
    if (title != null && title.isNotEmpty) {
      return title;
    }
    return comicId.length > 12 ? '${comicId.substring(0, 12)}…' : comicId;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final String? coverPath = ref
        .watch(comicCoverPathProvider(comicId: item.comicId))
        .maybeWhen(data: (String? v) => v, orElse: () => null);
    final String title = _titleForComic(ref, item.comicId);
    return Material(
      color: cs.surface,
      child: InkWell(
        onTap: () {
          appRouter.pushNamed(
            '漫画详情',
            pathParameters: <String, String>{'id': item.comicId},
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 40,
                child: Text(
                  '$sequenceNumber',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(tokens.radius.sm),
                child: Container(
                  width: 56,
                  height: 80,
                  color: cs.imagePlaceholder,
                  child: coverPath != null
                      ? ExtendedImage.file(
                          File(coverPath),
                          fit: BoxFit.cover,
                          cacheWidth: 240,
                        )
                      : Icon(
                          Icons.broken_image,
                          color: cs.iconSecondary,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: cs.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
