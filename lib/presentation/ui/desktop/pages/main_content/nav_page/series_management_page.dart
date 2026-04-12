import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/custom_toast.dart';
import 'package:hentai_library/domain/entity/comic/series.dart';
import 'package:hentai_library/domain/usecases/infer_series_from_comic_titles_usecase.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/dialog/add_comics_to_series_dialog.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/dialog/add_series_dialog.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/dialog/rename_series_dialog.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/dialog/reorder_series_items_dialog.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/dialog/series_confirm_delete_dialog.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/button/ghost_button.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/input/custom_text_field.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SeriesManagementPage extends ConsumerWidget {
  const SeriesManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> openAddSeriesDialog() async {
      await showDialog<void>(
        context: context,
        barrierColor: Colors.transparent,
        builder: (BuildContext dialogContext) => AddSeriesDialog(
          onCreated: () {
            showSuccessToast(context, '系列创建成功');
          },
        ),
      );
    }

    final seriesAsync = ref.watch(allSeriesProvider);
    final query = ref.watch(seriesFilterProvider);

    return _AddShortcutScope(
      onAdd: openAddSeriesDialog,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(onAddSeries: openAddSeriesDialog),
            const SizedBox(height: 20),
            seriesAsync.when(
              data: (series) {
                final filtered = _applyFilter(series, query);
                if (filtered.isEmpty) {
                  return const _SeriesManagementEmptyState();
                }
                return _SeriesList(series: filtered);
              },
              loading: () => const _SeriesManagementLoadingState(),
              error: (e, _) => _SeriesManagementErrorState(error: e),
            ),
          ],
        ),
      ),
    );
  }

  List<Series> _applyFilter(List<Series> source, String query) {
    if (query.trim().isEmpty) return List<Series>.from(source);
    final q = query.trim().toLowerCase();
    return source.where((s) => s.name.toLowerCase().contains(q)).toList();
  }
}

class _Header extends ConsumerStatefulWidget {
  const _Header({required this.onAddSeries});

  final Future<void> Function() onAddSeries;

  @override
  ConsumerState<_Header> createState() => _HeaderState();
}

class _HeaderState extends ConsumerState<_Header> {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
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
                onChanged: (value) =>
                    ref.read(seriesFilterProvider.notifier).setQuery(value),
              ),
            ),
            Tooltip(
              message: '添加系列 ($shortcutLabel)',
              child: FilledButton.icon(
                onPressed: widget.onAddSeries,
                icon: const Icon(LucideIcons.plus, size: 16),
                label: Text('添加系列 ($shortcutLabel)'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            Tooltip(
              message: '按标题末尾卷号自动分组未归属漫画',
              child: OutlinedButton.icon(
                onPressed: _isInferring ? null : _inferSeries,
                icon: _isInferring
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.primary,
                        ),
                      )
                    : const Icon(LucideIcons.wandSparkles, size: 16),
                label: const Text('自动推断系列'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AddIntent extends Intent {
  const _AddIntent();
}

class _AddShortcutScope extends StatelessWidget {
  const _AddShortcutScope({required this.child, required this.onAdd});

  final Widget child;
  final Future<void> Function() onAdd;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyN, control: true): _AddIntent(),
        SingleActivator(LogicalKeyboardKey.keyN, meta: true): _AddIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _AddIntent: CallbackAction<_AddIntent>(
            onInvoke: (_AddIntent intent) {
              if (_isTextInputFocused()) {
                return null;
              }
              onAdd();
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }

  bool _isTextInputFocused() {
    final FocusNode? node = FocusManager.instance.primaryFocus;
    final BuildContext? context = node?.context;
    if (context == null) {
      return false;
    }
    return context.widget is EditableText;
  }
}

String _shortcutLabel(BuildContext context) {
  final TargetPlatform platform = Theme.of(context).platform;
  final bool isApple =
      platform == TargetPlatform.macOS || platform == TargetPlatform.iOS;
  return isApple ? '⌘N' : 'Ctrl+N';
}

class _SeriesList extends StatelessWidget {
  const _SeriesList({required this.series});

  final List<Series> series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.borderSubtle),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                border: Border(bottom: BorderSide(color: cs.borderSubtle)),
              ),
              child: Row(
                children: [
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
                ],
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: series.length,
              separatorBuilder: (context, _) =>
                  Divider(height: 1, color: cs.borderSubtle),
              itemBuilder: (context, index) {
                final s = series[index];
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
    final count = series.items.length;

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
                  barrierColor: Colors.transparent,
                  builder: (context) => AddComicsToSeriesDialog(
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
                  barrierColor: Colors.transparent,
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
                  barrierColor: Colors.transparent,
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
                final confirmed =
                    await showDialog<bool>(
                      context: context,
                      builder: (context) =>
                          SeriesConfirmDeleteDialog(series: series),
                    ) ??
                    false;
                if (!confirmed || !context.mounted) return;
                try {
                  await ref.read(seriesActionsProvider).delete(series.name);
                  if (context.mounted) {
                    showSuccessToast(context, '已删除系列');
                  }
                } catch (e) {
                  if (context.mounted) {
                    showErrorToast(context, e);
                  }
                }
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
