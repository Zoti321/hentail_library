import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/theme/theme.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/model/entity/comic/series.dart';
import 'package:hentai_library/domain/usecases/infer_series_from_comic_titles_usecase.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/overlays/dialog/add_comics_to_series_dialog.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/overlays/dialog/add_series_dialog.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/overlays/dialog/rename_series_dialog.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/overlays/dialog/reorder_series_items_dialog.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/overlays/dialog/confirm/series_confirm_delete_dialog.dart';
import 'package:hentai_library/presentation/ui/desktop/routes/desktop_router.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/actions/ghost_button.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/form/custom_text_field.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SeriesManagementPanel extends StatelessWidget {
  const SeriesManagementPanel({super.key});

  @override
  Widget build(BuildContext context) {
    Future<void> openAddSeriesDialog() async {
      await showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) => AddSeriesDialog(
          onCreated: () {
            showSuccessToast(context, '系列创建成功');
          },
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(onAddSeries: openAddSeriesDialog),
          const SizedBox(height: 12),
          const _SeriesManagementToolbar(),
          const SizedBox(height: 20),
          const _FilteredSeriesSection(),
        ],
      ),
    );
  }
}

class _FilteredSeriesSection extends ConsumerWidget {
  const _FilteredSeriesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Series>> seriesAsync = ref.watch(allSeriesProvider);
    final String query = ref.watch(seriesFilterProvider);
    return seriesAsync.when(
      data: (List<Series> series) {
        final List<Series> filtered = _filterSeriesByQuery(series, query);
        if (filtered.isEmpty) {
          return const _SeriesManagementEmptyState();
        }
        return _SeriesListCard(series: filtered);
      },
      loading: () => const _SeriesManagementLoadingState(),
      error: (Object e, StackTrace _) => _SeriesManagementErrorState(error: e),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.onAddSeries});

  final Future<void> Function() onAddSeries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final String shortcutLabel = _shortcutLabel(context);

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
                onChanged: (String value) =>
                    ref.read(seriesFilterProvider.notifier).setQuery(value),
              ),
            ),
            FilledButton.icon(
              onPressed: onAddSeries,
              icon: const Icon(LucideIcons.plus, size: 16),
              label: Text('添加系列 ($shortcutLabel)'),
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

class _SeriesManagementToolbar extends ConsumerStatefulWidget {
  const _SeriesManagementToolbar();

  @override
  ConsumerState<_SeriesManagementToolbar> createState() =>
      _SeriesManagementToolbarState();
}

class _SeriesManagementToolbarState
    extends ConsumerState<_SeriesManagementToolbar> {
  bool _isInferring = false;

  Future<void> _inferSeries() async {
    if (_isInferring) {
      return;
    }
    setState(() {
      _isInferring = true;
    });
    try {
      final InferSeriesFromComicTitlesUseCase useCase = ref.read(
        inferSeriesFromComicTitlesUseCaseProvider,
      );
      final InferSeriesFromComicTitlesResult result = await useCase.call();
      ref.invalidate(allSeriesProvider);
      if (!mounted) {
        return;
      }
      final String newPart = result.newSeriesCreated > 0
          ? '，新建 ${result.newSeriesCreated} 个系列名'
          : '';
      showSuccessToast(
        context,
        '已推断 ${result.groupsApplied} 组系列，归属 ${result.comicsAssigned} 本漫画$newPart。',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      showErrorToast(context, e);
    } finally {
      if (mounted) {
        setState(() {
          _isInferring = false;
        });
      }
    }
  }

  Future<void> _deleteEmptySeries() async {
    final List<Series> allSeries = await ref.read(allSeriesProvider.future);
    if (!mounted) {
      return;
    }
    final List<String> emptyNames = allSeries
        .where((Series s) => s.items.isEmpty)
        .map((Series s) => s.name)
        .toList();
    if (emptyNames.isEmpty) {
      showInfoToast(context, '没有不含漫画的系列');
      return;
    }
    emptyNames.sort();
    if (!mounted) {
      return;
    }
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('删除空系列'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  '将删除 ${emptyNames.length} 个不含漫画的系列（仅移除系列记录，不删除漫画）：',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                ...emptyNames.map(
                  (String name) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '· $name',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
    if (confirmed != true || !mounted) {
      return;
    }
    final SeriesActions actions = ref.read(seriesActionsProvider);
    try {
      for (final String name in emptyNames) {
        await actions.delete(name);
      }
      if (!mounted) {
        return;
      }
      showSuccessToast(context, '已删除 ${emptyNames.length} 个空系列');
    } catch (e) {
      if (!mounted) {
        return;
      }
      showErrorToast(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        if (_isInferring)
          SizedBox(
            width: 28,
            height: 28,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.primary,
                ),
              ),
            ),
          )
        else
          GhostButton.icon(
            tooltip: '自动推断系列',
            semanticLabel: '自动推断系列',
            icon: LucideIcons.wandSparkles,
            size: 28,
            onPressed: _inferSeries,
            delayTooltipThreeSeconds: true,
            overlayColor: cs.primary.withAlpha(14),
          ),
        const SizedBox(width: 4),
        GhostButton.icon(
          tooltip: '删除没有漫画的系列',
          semanticLabel: '删除没有漫画的系列',
          icon: LucideIcons.folderMinus,
          size: 28,
          onPressed: _deleteEmptySeries,
          delayTooltipThreeSeconds: true,
          overlayColor: cs.primary.withAlpha(14),
        ),
      ],
    );
  }
}

class _SeriesListCard extends StatelessWidget {
  const _SeriesListCard({required this.series});

  final List<Series> series;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.borderSubtle),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                border: Border(bottom: BorderSide(color: cs.borderSubtle)),
              ),
              child: Row(
                children: <Widget>[
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
                  const SizedBox(width: 12),
                  Text(
                    '共 ${series.length} 条',
                    style: TextStyle(fontSize: 13, color: cs.textTertiary),
                  ),
                ],
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: series.length,
              separatorBuilder: (BuildContext context, int _) =>
                  Divider(height: 1, color: cs.borderSubtle),
              itemBuilder: (BuildContext context, int index) {
                final Series s = series[index];
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
    final cs = Theme.of(context).colorScheme;
    final int count = series.items.length;

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
            GhostButton.icon(
              tooltip: '添加漫画',
              semanticLabel: '添加漫画',
              icon: LucideIcons.plus,
              size: 28,
              delayTooltipThreeSeconds: true,
              overlayColor: cs.primary.withAlpha(14),
              onPressed: () async {
                await showDialog<void>(
                  context: context,
                  builder: (BuildContext context) => AddComicsToSeriesDialog(
                    key: ValueKey<String>(series.name),
                    series: series,
                  ),
                );
              },
            ),
            GhostButton.icon(
              tooltip: '调整顺序',
              semanticLabel: '调整顺序',
              icon: LucideIcons.arrowUpDown,
              size: 28,
              delayTooltipThreeSeconds: true,
              overlayColor: cs.primary.withAlpha(14),
              onPressed: () {
                if (series.items.length < 2) {
                  showInfoToast(context, '至少需要 2 本漫画才能调整顺序');
                  return;
                }
                showDialog<void>(
                  context: context,
                  builder: (BuildContext context) =>
                      ReorderSeriesItemsDialog(series: series),
                );
              },
            ),
            GhostButton.icon(
              tooltip: '重命名',
              semanticLabel: '重命名',
              icon: LucideIcons.squarePen,
              size: 28,
              delayTooltipThreeSeconds: true,
              overlayColor: cs.primary.withAlpha(14),
              onPressed: () async {
                final String? newName = await showDialog<String>(
                  context: context,
                  builder: (BuildContext dialogContext) =>
                      RenameSeriesDialog(series: series),
                );
                if (newName != null && context.mounted) {
                  showSuccessToast(context, '已重命名');
                }
              },
            ),
            GhostButton.icon(
              tooltip: '删除',
              semanticLabel: '删除',
              icon: LucideIcons.trash2,
              size: 28,
              foregroundColor: cs.error,
              delayTooltipThreeSeconds: true,
              overlayColor: cs.primary.withAlpha(14),
              onPressed: () async {
                final bool confirmed =
                    await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) =>
                          SeriesConfirmDeleteDialog(series: series),
                    ) ??
                    false;
                if (!confirmed || !context.mounted) {
                  return;
                }
                try {
                  await ref.read(seriesActionsProvider).delete(series.name);
                } catch (e) {
                  _showDesktopSeriesFeedbackToast(message: null, error: e);
                  return;
                }
                _showDesktopSeriesFeedbackToast(message: '已删除系列', error: null);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SeriesManagementLoadingState extends StatelessWidget {
  const _SeriesManagementLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _SeriesManagementErrorState extends StatelessWidget {
  const _SeriesManagementErrorState({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        '加载失败：$error',
        style: TextStyle(color: cs.error, fontSize: 14),
      ),
    );
  }
}

class _SeriesManagementEmptyState extends StatelessWidget {
  const _SeriesManagementEmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          '暂无系列',
          style: TextStyle(fontSize: 14, color: cs.textTertiary),
        ),
      ),
    );
  }
}

/// 删除系列后列表行会立即卸挂载；在下一帧用根导航 [Context] 显示 Toast，
/// 避免行内 [Context] 与 Tooltip / Overlay 竞态触发 `_overlay != null` 断言。
void _showDesktopSeriesFeedbackToast({
  required String? message,
  required Object? error,
}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final BuildContext? rootCtx = desktopRootNavigatorKey.currentContext;
    if (rootCtx == null || !rootCtx.mounted) {
      return;
    }
    if (message != null) {
      showSuccessToast(rootCtx, message);
    } else if (error != null) {
      showErrorToast(rootCtx, error);
    }
  });
}

List<Series> _filterSeriesByQuery(List<Series> source, String query) {
  if (query.trim().isEmpty) {
    return List<Series>.from(source);
  }
  final String q = query.trim().toLowerCase();
  return source.where((Series s) => s.name.toLowerCase().contains(q)).toList();
}

String _shortcutLabel(BuildContext context) {
  final TargetPlatform platform = Theme.of(context).platform;
  final bool isApple =
      platform == TargetPlatform.macOS || platform == TargetPlatform.iOS;
  return isApple ? '⌘N' : 'Ctrl+N';
}
