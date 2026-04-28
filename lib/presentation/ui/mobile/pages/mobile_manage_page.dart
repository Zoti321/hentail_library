import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/model/entity/comic/series.dart';
import 'package:hentai_library/model/entity/comic/tag.dart';
import 'package:hentai_library/presentation/providers/aggregates/series_aggregate_notifier.dart';
import 'package:hentai_library/presentation/providers/pages/series_management/series_management_notifier.dart';
import 'package:hentai_library/presentation/providers/pages/tag_management/tag_management_notifier.dart';

class MobileManagePage extends StatelessWidget {
  const MobileManagePage({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: const _ManageAppBar(),
        body: Column(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.draw_outlined),
              title: const Text('作者管理'),
              subtitle: const Text('浏览、添加、重命名或删除作者'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/metadata?tab=authors'),
            ),
            const Divider(height: 1),
            const Expanded(
              child: TabBarView(
                children: <Widget>[_ManageTagsTab(), _ManageSeriesTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ManageAppBar();
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('管理'),
      bottom: const TabBar(
        tabs: <Widget>[
          Tab(text: '标签'),
          Tab(text: '系列'),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 48);
}

class _ManageTagsTab extends ConsumerWidget {
  const _ManageTagsTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String query = ref.watch(tagFilterProvider);
    final AsyncValue<List<Tag>> tagsAsync = ref.watch(allTagsProvider);
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: '搜索标签',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (String value) {
                    ref.read(tagFilterProvider.notifier).setQuery(value);
                  },
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _onAddTag(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('新增'),
              ),
            ],
          ),
        ),
        Expanded(
          child: tagsAsync.when(
            data: (List<Tag> tags) {
              final String lowered = query.trim().toLowerCase();
              final List<Tag> filtered = tags
                  .where((Tag tag) => tag.name.toLowerCase().contains(lowered))
                  .toList();
              if (filtered.isEmpty) {
                return const _ManageEmptyView(message: '暂无标签');
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: filtered.length,
                separatorBuilder: (BuildContext context, int index) =>
                    const SizedBox(height: 8),
                itemBuilder: (BuildContext context, int index) {
                  final Tag tag = filtered[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.label_outline),
                      title: Text(tag.name),
                      trailing: PopupMenuButton<String>(
                        onSelected: (String value) async {
                          if (value == 'rename') {
                            await _onRenameTag(context, ref, tag);
                            return;
                          }
                          if (value == 'delete') {
                            await _onDeleteTag(context, ref, tag);
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                            const <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(
                                value: 'rename',
                                child: Text('重命名'),
                              ),
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Text('删除'),
                              ),
                            ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object error, StackTrace stackTrace) {
              return Center(child: Text('加载失败：$error'));
            },
          ),
        ),
      ],
    );
  }

  Future<void> _onAddTag(BuildContext context, WidgetRef ref) async {
    final String? input = await _showNameDialog(context, title: '新增标签');
    if (input == null || input.trim().isEmpty) {
      return;
    }
    try {
      await ref.read(tagActionsProvider).addTag(Tag(name: input.trim()));
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('标签已创建')));
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('创建失败：$error')));
    }
  }

  Future<void> _onRenameTag(
    BuildContext context,
    WidgetRef ref,
    Tag tag,
  ) async {
    final String? input = await _showNameDialog(
      context,
      title: '重命名标签',
      initialValue: tag.name,
    );
    if (input == null || input.trim().isEmpty) {
      return;
    }
    try {
      await ref.read(tagActionsProvider).renameTag(tag, input.trim());
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('标签已重命名')));
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('重命名失败：$error')));
    }
  }

  Future<void> _onDeleteTag(
    BuildContext context,
    WidgetRef ref,
    Tag tag,
  ) async {
    final bool confirmed = await _showDeleteConfirmDialog(
      context,
      message: '确认删除标签「${tag.name}」吗？',
    );
    if (!confirmed) {
      return;
    }
    try {
      await ref.read(tagActionsProvider).deleteTag(tag);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('标签已删除')));
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('删除失败：$error')));
    }
  }
}

class _ManageSeriesTab extends ConsumerWidget {
  const _ManageSeriesTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String query = ref.watch(seriesFilterProvider);
    final AsyncValue<List<Series>> seriesAsync = ref.watch(allSeriesProvider);
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: '搜索系列',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (String value) {
                    ref.read(seriesFilterProvider.notifier).setQuery(value);
                  },
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _onAddSeries(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('新增'),
              ),
            ],
          ),
        ),
        Expanded(
          child: seriesAsync.when(
            data: (List<Series> seriesList) {
              final String lowered = query.trim().toLowerCase();
              final List<Series> filtered = seriesList
                  .where(
                    (Series item) => item.name.toLowerCase().contains(lowered),
                  )
                  .toList();
              if (filtered.isEmpty) {
                return const _ManageEmptyView(message: '暂无系列');
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: filtered.length,
                separatorBuilder: (BuildContext context, int index) =>
                    const SizedBox(height: 8),
                itemBuilder: (BuildContext context, int index) {
                  final Series series = filtered[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.layers_outlined),
                      title: Text(series.name),
                      subtitle: Text('共 ${series.items.length} 本'),
                      onTap: () {
                        final String encoded = Uri.encodeComponent(series.name);
                        context.go('/series/$encoded');
                      },
                      trailing: PopupMenuButton<String>(
                        onSelected: (String value) async {
                          if (value == 'rename') {
                            await _onRenameSeries(context, ref, series);
                            return;
                          }
                          if (value == 'delete') {
                            await _onDeleteSeries(context, ref, series);
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                            const <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(
                                value: 'rename',
                                child: Text('重命名'),
                              ),
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Text('删除'),
                              ),
                            ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object error, StackTrace stackTrace) {
              return Center(child: Text('加载失败：$error'));
            },
          ),
        ),
      ],
    );
  }

  Future<void> _onAddSeries(BuildContext context, WidgetRef ref) async {
    final String? input = await _showNameDialog(context, title: '新增系列');
    if (input == null || input.trim().isEmpty) {
      return;
    }
    try {
      await ref.read(seriesActionsProvider).create(input.trim());
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('系列已创建')));
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('创建失败：$error')));
    }
  }

  Future<void> _onRenameSeries(
    BuildContext context,
    WidgetRef ref,
    Series series,
  ) async {
    final String? input = await _showNameDialog(
      context,
      title: '重命名系列',
      initialValue: series.name,
    );
    if (input == null || input.trim().isEmpty) {
      return;
    }
    try {
      await ref.read(seriesActionsProvider).rename(series.name, input.trim());
      if (!context.mounted) {
        return;
      }
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

  Future<void> _onDeleteSeries(
    BuildContext context,
    WidgetRef ref,
    Series series,
  ) async {
    final bool confirmed = await _showDeleteConfirmDialog(
      context,
      message: '确认删除系列「${series.name}」吗？',
    );
    if (!confirmed) {
      return;
    }
    try {
      await ref.read(seriesActionsProvider).delete(series.name);
      if (!context.mounted) {
        return;
      }
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
}

class _ManageEmptyView extends StatelessWidget {
  const _ManageEmptyView({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(message, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}

Future<String?> _showNameDialog(
  BuildContext context, {
  required String title,
  String initialValue = '',
}) async {
  final TextEditingController controller = TextEditingController(
    text: initialValue,
  );
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          onSubmitted: (String value) => Navigator.of(context).pop(value),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('确定'),
          ),
        ],
      );
    },
  );
}

Future<bool> _showDeleteConfirmDialog(
  BuildContext context, {
  required String message,
}) async {
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('删除确认'),
        content: Text(message),
        actions: <Widget>[
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
    },
  );
  return result ?? false;
}
