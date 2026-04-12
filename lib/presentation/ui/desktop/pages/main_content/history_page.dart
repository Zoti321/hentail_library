import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/core/util/snackbar_util.dart';
import 'package:hentai_library/domain/entity/entities.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/routes/reader_route_args.dart';
import 'package:hentai_library/presentation/ui/desktop/routes/routes.dart';
import 'package:hentai_library/presentation/dto/history_grid_item_dto.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/button/ghost_button.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/element/reading_history_card.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/dialog/clear_reading_history_confirm_dialog.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/input/custom_text_field.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HistoryPage extends HookConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = useState<String>('');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          _Header(query: query.value, onQueryChanged: (v) => query.value = v),
          _HistoryList(query: query.value),
        ],
      ),
    );
  }
}

class _HistoryStyles {
  const _HistoryStyles._();
  static const double titleFontSize = 26;
  static const double subtitleFontSize = 13;
}

class _Header extends ConsumerWidget {
  const _Header({required this.query, required this.onQueryChanged});

  final String query;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final comicHistory = ref
        .watch(readingHistoryStreamProvider)
        .maybeWhen(data: (data) => data, orElse: () => <ReadingHistory>[]);
    final seriesHistory = ref
        .watch(seriesReadingHistoryStreamProvider)
        .maybeWhen(
          data: (data) => data,
          orElse: () => const <SeriesReadingHistory>[],
        );
    final int totalCount = comicHistory.length + seriesHistory.length;

    return Container(
      padding: const EdgeInsets.all(2),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              Text(
                "阅读历史",
                style: TextStyle(
                  color: theme.colorScheme.textPrimary,
                  fontSize: _HistoryStyles.titleFontSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                "$totalCount 条记录 • 最长保留 30 天",
                style: TextStyle(
                  fontSize: _HistoryStyles.subtitleFontSize,
                  fontWeight: FontWeight.w400,
                  color: theme.colorScheme.textTertiary,
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.2,
            child: CustomTextField(
              hintText: "搜索历史记录...",
              onChanged: onQueryChanged,
            ),
          ),
          const SizedBox(width: 12),
          _buildClearBtn(context, ref, totalCount > 0),
        ],
      ),
    );
  }

  Widget _buildClearBtn(BuildContext context, WidgetRef ref, bool enabled) {
    final cs = Theme.of(context).colorScheme;
    return GhostButton.iconText(
      icon: LucideIcons.trash2,
      text: '清空',
      tooltip: '清空阅读历史',
      semanticLabel: '清空阅读历史',
      onPressed: !enabled
          ? null
          : () async {
              final confirmed =
                  await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) =>
                        const ClearReadingHistoryConfirmDialog(),
                  ) ??
                  false;
              if (!confirmed) return;
              try {
                await ref.read(readingHistoryRepoProvider).clearAllHistory();
                if (context.mounted) {
                  showSuccessSnackBar(context, '已清空阅读历史');
                }
              } catch (e) {
                if (context.mounted) showErrorSnackBar(context, e);
              }
            },
      foregroundColor: cs.warning,
      hoverColor: cs.error.withAlpha(24),
      overlayColor: cs.error.withAlpha(20),
    );
  }
}

class _HistoryList extends ConsumerWidget {
  const _HistoryList({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final comicsAsync = ref.watch(readingHistoryStreamProvider);
    final seriesAsync = ref.watch(seriesReadingHistoryStreamProvider);
    final allSeriesAsync = ref.watch(allSeriesProvider);
    final merged = ref.watch(mergedHistoryGridItemsProvider);

    if (comicsAsync.isLoading ||
        seriesAsync.isLoading ||
        allSeriesAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (comicsAsync.hasError ||
        seriesAsync.hasError ||
        allSeriesAsync.hasError) {
      return Padding(
        padding: const EdgeInsets.only(top: 48),
        child: Center(
          child: Text(
            '加载失败',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.textSecondary,
            ),
          ),
        ),
      );
    }

    final q = query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? merged
        : merged
              .where((h) => h.title.toLowerCase().contains(q))
              .toList(growable: false);

    if (filtered.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: 48),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              Icon(
                LucideIcons.bookOpen,
                size: 48,
                color: theme.colorScheme.textTertiary,
              ),
              Text(
                q.isEmpty ? '暂无阅读历史' : '没有匹配的历史记录',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        int crossAxisCount = 2;
        if (width >= 1600) {
          crossAxisCount = 5;
        } else if (width >= 1300) {
          crossAxisCount = 4;
        } else if (width >= 980) {
          crossAxisCount = 3;
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 138,
          ),
          itemBuilder: (BuildContext context, int index) {
            final item = filtered[index];
            if (item is ComicHistoryGridItemDto) {
              return ReadingHistoryCard.comic(
                comicId: item.comicId,
                title: item.title,
                lastReadTime: item.lastReadTime,
                pageIndex: item.pageIndex,
                onTap: () => appRouter.pushNamed(
                  '阅读页面',
                  queryParameters: {
                    'read_type': 'comic',
                    'comic_id': item.comicId,
                  },
                ),
                onDelete: () => _handleDeleteComicHistory(
                  context: context,
                  ref: ref,
                  comicId: item.comicId,
                ),
              );
            }
            final seriesItem = item as SeriesHistoryGridItemDto;
            return ReadingHistoryCard.series(
              seriesName: seriesItem.seriesName,
              lastReadComicId: seriesItem.lastReadComicId,
              lastReadTime: seriesItem.lastReadTime,
              pageIndex: seriesItem.pageIndex,
              lastReadComicOrder: seriesItem.lastReadComicOrder,
              onTap: () => appRouter.pushNamed(
                ReaderRouteArgs.readerRouteName,
                queryParameters: ReaderRouteArgs(
                  comicId: seriesItem.lastReadComicId,
                  readType: ReaderRouteArgs.readTypeSeries,
                  seriesName: seriesItem.seriesName,
                ).toQueryParameters(),
              ),
              onDelete: () => _handleDeleteSeriesHistory(
                context: context,
                ref: ref,
                seriesName: seriesItem.seriesName,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleDeleteComicHistory({
    required BuildContext context,
    required WidgetRef ref,
    required String comicId,
  }) async {
    try {
      await ref.read(readingHistoryRepoProvider).deleteByComicId(comicId);
      if (context.mounted) {
        showSuccessSnackBar(context, '已删除记录');
      }
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context, e);
    }
  }

  Future<void> _handleDeleteSeriesHistory({
    required BuildContext context,
    required WidgetRef ref,
    required String seriesName,
  }) async {
    try {
      await ref
          .read(readingHistoryRepoProvider)
          .deleteSeriesReadingBySeriesName(seriesName);
      if (context.mounted) {
        showSuccessSnackBar(context, '已删除记录');
      }
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context, e);
    }
  }
}
