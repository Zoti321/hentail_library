import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/presentation/dto/history_grid_item_dto.dart';
import 'package:hentai_library/presentation/providers/pages/history/history_page_notifier.dart';

class MobileHistoryPage extends ConsumerWidget {
  const MobileHistoryPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HistoryFeedViewData viewData = ref.watch(historyFeedViewProvider);
    if (viewData.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (viewData.hasError) {
      return const Scaffold(
        body: Center(child: Text('历史记录加载失败')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('历史')),
      body: viewData.mergedItems.isEmpty
          ? const Center(child: Text('暂无阅读记录'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              itemCount: viewData.mergedItems.length,
              separatorBuilder: (
                BuildContext context,
                int index,
              ) => const SizedBox(height: 8),
              itemBuilder: (BuildContext context, int index) {
                final HistoryGridItemDto item = viewData.mergedItems[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      item.map(
                        comic: (_) => Icons.menu_book_outlined,
                        series: (_) => Icons.layers_outlined,
                      ),
                    ),
                    title: Text(item.title),
                    subtitle: Text(_buildSubtitle(item)),
                    onTap: () => _openHistoryTarget(context, item),
                  ),
                );
              },
            ),
    );
  }

  String _buildSubtitle(HistoryGridItemDto item) {
    final String pageText = item.pageIndex == null ? '未知页' : '第 ${item.pageIndex! + 1} 页';
    final String timeText =
        '${item.lastReadTime.year}-${item.lastReadTime.month.toString().padLeft(2, '0')}-${item.lastReadTime.day.toString().padLeft(2, '0')}';
    return '$pageText · $timeText';
  }

  void _openHistoryTarget(BuildContext context, HistoryGridItemDto item) {
    item.when(
      comic: (
        String id,
        String title,
        DateTime lastReadTime,
        String coverComicId,
        String comicId,
        int? pageIndex,
      ) {
        final String encoded = Uri.encodeComponent(comicId);
        context.go('/comic/$encoded');
      },
      series: (
        String id,
        String title,
        DateTime lastReadTime,
        String coverComicId,
        String seriesName,
        String lastReadComicId,
        int? pageIndex,
        int? lastReadComicOrder,
      ) {
        final String encoded = Uri.encodeComponent(seriesName);
        context.go('/series/$encoded');
      },
    );
  }
}
