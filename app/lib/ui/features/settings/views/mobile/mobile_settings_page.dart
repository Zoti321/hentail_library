import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/domain/models/app_setting.dart';
import 'package:hentai_library/ui/features/settings/state/app_update_controller.dart';
import 'package:hentai_library/ui/features/settings/view_models/settings_notifier.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
                        ref
                            .read(settingsProvider.notifier)
                            .setThemePreference(value);
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
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: '关于',
                children: <Widget>[
                  SwitchListTile(
                    title: const Text('自动更新'),
                    subtitle: Text(
                      settings.autoUpdate ? '启动时检查更新' : '启动时不检查更新',
                    ),
                    value: settings.autoUpdate,
                    onChanged: (bool value) {
                      ref.read(settingsProvider.notifier).setAutoUpdate(value);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.system_update_outlined),
                    title: const Text('检查更新'),
                    subtitle: ref
                        .watch(packageInfoProvider)
                        .maybeWhen(
                          data: (PackageInfo info) =>
                              Text('当前版本 v${info.version}'),
                          orElse: () => const Text('正在读取版本…'),
                        ),
                    onTap: () {
                      ref
                          .read(appUpdateControllerProvider.notifier)
                          .runManualCheck(context: context);
                    },
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
