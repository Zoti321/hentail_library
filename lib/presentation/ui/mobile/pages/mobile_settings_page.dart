import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/util/format_byte_size.dart';
import 'package:hentai_library/domain/entity/app_setting.dart';
import 'package:hentai_library/presentation/providers/providers.dart';

class MobileSettingsPage extends ConsumerWidget {
  const MobileSettingsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AppSetting> settingsAsync = ref.watch(settingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: settingsAsync.when(
        skipLoadingOnRefresh: true,
        skipLoadingOnReload: true,
        data: (AppSetting settings) {
          final AsyncValue<int> archiveCoverUsage =
              ref.watch(archiveCoverCacheDiskUsageBytesProvider);
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            children: <Widget>[
              _SectionCard(
                title: '外观',
                children: <Widget>[
                  ListTile(
                    title: const Text('主题模式'),
                    subtitle: Text(settings.themePreference.labelZh),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: DropdownButtonFormField<AppThemePreference>(
                      value: settings.themePreference,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: AppThemePreference.values
                          .map(
                            (AppThemePreference item) =>
                                DropdownMenuItem<AppThemePreference>(
                                  value: item,
                                  child: Text(item.labelZh),
                                ),
                          )
                          .toList(),
                      onChanged: (AppThemePreference? value) {
                        if (value == null) {
                          return;
                        }
                        ref.read(settingsProvider.notifier).setThemePreference(value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: '漫画库',
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.folder_open_outlined),
                    title: const Text('扫描路径'),
                    subtitle: const Text('管理扫描路径'),
                    onTap: () => context.go('/paths'),
                  ),
                  SwitchListTile(
                    title: const Text('启动时自动扫描'),
                    value: settings.autoScan,
                    onChanged: (bool value) {
                      ref.read(settingsProvider.notifier).setAutoScan(value);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('漫画库隐藏系列内漫画'),
                    subtitle: Text(
                      settings.libraryHideComicsInSeries
                          ? '漫画列表不显示已归入系列的条目'
                          : '漫画列表显示全部漫画',
                    ),
                    value: settings.libraryHideComicsInSeries,
                    onChanged: (bool value) {
                      ref
                          .read(settingsProvider.notifier)
                          .setLibraryHideComicsInSeries(value);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('健全模式'),
                    subtitle: Text(settings.isHealthyMode ? '隐藏 R18' : '显示 R18'),
                    value: settings.isHealthyMode,
                    onChanged: (_) {
                      ref.read(settingsProvider.notifier).toggleHealthyMode();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: '缓存',
                children: <Widget>[
                  SwitchListTile(
                    title: const Text('归档封面磁盘缓存'),
                    subtitle: Text(
                      settings.archiveCoverDiskCacheEnabled
                          ? '列表封面解码结果写入应用缓存'
                          : '不读写缓存文件（每次重新解码）',
                    ),
                    value: settings.archiveCoverDiskCacheEnabled,
                    onChanged: (bool value) {
                      ref
                          .read(settingsProvider.notifier)
                          .setArchiveCoverDiskCacheEnabled(value);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.storage_outlined),
                    title: const Text('归档封面缓存占用'),
                    subtitle: archiveCoverUsage.when(
                      data: (int bytes) => Text(
                        '应用缓存目录；当前 ${formatByteSizeBin1024(bytes)}',
                      ),
                      loading: () => const Text('正在计算占用…'),
                      error: (Object _, StackTrace _) =>
                          const Text('无法读取占用'),
                    ),
                    trailing: TextButton(
                      onPressed: () async {
                        await ref.read(archiveCoverCacheProvider).clearAll();
                        ref.invalidate(archiveCoverCacheDiskUsageBytesProvider);
                      },
                      child: const Text('清理'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: '阅读',
                children: <Widget>[
                  SwitchListTile(
                    title: const Text('竖向阅读'),
                    value: settings.readerIsVertical,
                    onChanged: (bool value) {
                      ref.read(settingsProvider.notifier).setReaderIsVertical(value);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('自动播放'),
                    value: settings.readerAutoPlayEnabled,
                    onChanged: (bool value) {
                      ref
                          .read(settingsProvider.notifier)
                          .setReaderAutoPlayEnabled(value);
                    },
                  ),
                  ListTile(
                    title: const Text('自动播放间隔（秒）'),
                    subtitle: Text('${settings.readerAutoPlayIntervalSeconds} 秒'),
                    trailing: SizedBox(
                      width: 120,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              ref
                                  .read(settingsProvider.notifier)
                                  .setReaderAutoPlayIntervalSeconds(
                                    settings.readerAutoPlayIntervalSeconds - 1,
                                  );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              ref
                                  .read(settingsProvider.notifier)
                                  .setReaderAutoPlayIntervalSeconds(
                                    settings.readerAutoPlayIntervalSeconds + 1,
                                  );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stackTrace) {
          return Center(child: Text('加载失败：$error'));
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Column(
          children: <Widget>[
            ListTile(
              title: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}
