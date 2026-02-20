import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/domain/entity/comic/comic.dart';
import 'package:hentai_library/presentation/providers/pages/library/library_page_notifier.dart';
import 'package:hentai_library/presentation/providers/usecases/scan_library_controller.dart';
import 'package:hentai_library/presentation/providers/usecases/sync_library_progress.dart';

class MobileLibraryPage extends ConsumerStatefulWidget {
  const MobileLibraryPage({super.key});
  @override
  ConsumerState<MobileLibraryPage> createState() => _MobileLibraryPageState();
}

class _MobileLibraryPageState extends ConsumerState<MobileLibraryPage> {
  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Comic>> comicsAsync = ref.watch(
      libraryDisplayedComicsProvider,
    );
    final ScanLibraryState scanState = ref.watch(scanLibraryControllerProvider);
    final bool isScanning = scanState.running;
    return Scaffold(
      appBar: AppBar(
        title: const Text('漫画库'),
        actions: <Widget>[
          IconButton(
            tooltip: '管理路径',
            onPressed: () => context.go('/paths'),
            icon: const Icon(Icons.folder_open_outlined),
          ),
          IconButton(
            tooltip: '设置',
            onPressed: () => context.go('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                labelText: '搜索漫画',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (String value) {
                ref.read(libraryPageProvider.notifier).updateFilterQuery(value);
              },
            ),
          ),
          _ScanActionCard(
            isScanning: isScanning,
            scanState: scanState,
            onStartOrCancelTap: () => _onStartOrCancelTap(isScanning),
          ),
          Expanded(
            child: comicsAsync.when(
              data: (List<Comic> comics) {
                if (comics.isEmpty) {
                  return const _LibraryEmptyView();
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.read(libraryPageProvider.notifier).refreshStream();
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: comics.length,
                    separatorBuilder: (
                      BuildContext context,
                      int index,
                    ) => const SizedBox(height: 8),
                    itemBuilder: (BuildContext context, int index) {
                      final Comic comic = comics[index];
                      return Card(
                        child: ListTile(
                          title: Text(
                            comic.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            _buildComicSubtitle(comic),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            final String comicId = Uri.encodeComponent(
                              comic.comicId,
                            );
                            context.go('/comic/$comicId');
                          },
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object error, StackTrace stackTrace) {
                return Center(child: Text('加载失败：$error'));
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onStartOrCancelTap(bool isScanning) async {
    final ScanLibraryController notifier = ref.read(
      scanLibraryControllerProvider.notifier,
    );
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    if (isScanning) {
      notifier.cancel();
      return;
    }
    try {
      await notifier.start();
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(const SnackBar(content: Text('扫描完成')));
    } catch (_) {
      if (!mounted) {
        return;
      }
      final String message = ref.read(scanLibraryControllerProvider).error ?? '扫描失败';
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _ScanActionCard extends StatelessWidget {
  const _ScanActionCard({
    required this.isScanning,
    required this.scanState,
    required this.onStartOrCancelTap,
  });
  final bool isScanning;
  final ScanLibraryState scanState;
  final VoidCallback onStartOrCancelTap;
  @override
  Widget build(BuildContext context) {
    final SyncLibraryProgress? progress = scanState.progress;
    final String phaseText = _phaseText(progress);
    final String countText = '已发现 ${progress?.acceptedTotal ?? 0} 项';
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.sync),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isScanning ? '正在扫描漫画库' : '扫描漫画库',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                FilledButton.icon(
                  onPressed: onStartOrCancelTap,
                  icon: Icon(isScanning ? Icons.stop : Icons.play_arrow),
                  label: Text(isScanning ? '停止' : '开始'),
                ),
              ],
            ),
            if (isScanning) ...<Widget>[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 8),
            Text('$phaseText · $countText'),
          ],
        ),
      ),
    );
  }

  String _phaseText(SyncLibraryProgress? progress) {
    if (progress == null) {
      return '等待开始';
    }
    switch (progress.phase) {
      case SyncLibraryPhase.clearingLibrary:
        return '清空旧数据';
      case SyncLibraryPhase.scanning:
        return '扫描文件中';
      case SyncLibraryPhase.writingDb:
        return '写入数据库';
      case SyncLibraryPhase.done:
        return '扫描完成';
    }
  }
}

class _LibraryEmptyView extends StatelessWidget {
  const _LibraryEmptyView();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          '暂无漫画。请先添加路径并执行扫描。',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

String _buildComicSubtitle(Comic comic) {
  final String rating = comic.contentRating.name.toUpperCase();
  final int pageCount = comic.pageCount ?? 0;
  final int tagCount = comic.tags.length;
  return '评级: $rating  页数: $pageCount  标签: $tagCount';
}
