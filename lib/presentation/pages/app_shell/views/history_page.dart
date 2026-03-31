import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/core/util/snackbar_util.dart';
import 'package:hentai_library/domain/entity/reading_history.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/routes/routes.dart';
import 'package:hentai_library/presentation/widgets/card_item/reading_history_card.dart';
import 'package:hentai_library/presentation/widgets/input/custom_text_field.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HistoryPage extends HookConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = useState<String>('');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          const _ReadingStatsSection(),
          _Header(query: query.value, onQueryChanged: (v) => query.value = v),
          _HistoryList(query: query.value),
        ],
      ),
    );
  }
}

class _ReadingStatsSection extends ConsumerWidget {
  const _ReadingStatsSection();

  static String _formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return '0 分钟';
    final d = Duration(seconds: totalSeconds);
    if (d.inHours > 0) {
      return '${d.inHours} 小时 ${d.inMinutes.remainder(60)} 分钟';
    }
    return '${d.inMinutes} 分钟';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(readingStatsProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.borderMedium, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Row(
            spacing: 4,
            children: [
              Icon(
                LucideIcons.chartBar,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              Text(
                '阅读统计',
                style: TextStyle(
                  color: theme.colorScheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          statsAsync.when(
            data: (stats) {
              final colorScheme = theme.colorScheme;
              return Wrap(
                spacing: 24,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.borderSubtle,
                        width: 1,
                      ),
                    ),
                    child: _StatChip(
                      label: '累计阅读',
                      value: _formatDuration(stats.totalSeconds),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.borderSubtle,
                        width: 1,
                      ),
                    ),
                    child: _StatChip(
                      label: '每日平均',
                      value: stats.daysWithReading > 0
                          ? _formatDuration(stats.averageSecondsPerDay)
                          : '0 分钟',
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.borderSubtle,
                        width: 1,
                      ),
                    ),
                    child: _StatChip(
                      label: '有阅读天数',
                      value: '${stats.daysWithReading} 天',
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Text(
              '加载统计失败',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.query, required this.onQueryChanged});

  final String query;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final rawData = ref.watch(readingHistoryStreamProvider);

    final history = rawData.when(
      data: (data) => data,
      loading: () => <ReadingHistory>[],
      error: (error, _) => <ReadingHistory>[],
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
    );

    return Container(
      padding: const .all(2),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: .start,
            spacing: 6,
            children: [
              Row(
                spacing: 4,
                children: [
                  Icon(
                    LucideIcons.history,
                    size: 24,
                    color: theme.colorScheme.primary,
                  ),
                  Text(
                    "阅读历史",
                    style: TextStyle(
                      color: theme.colorScheme.textPrimary,
                      fontSize: 24,
                      fontWeight: .w600,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              Text(
                "${history.length} 条记录 • 最长保留 30 天",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: .w200,
                  color: theme.colorScheme.textSecondary,
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
          _buildClearBtn(context, ref, history.isNotEmpty),
        ],
      ),
    );
  }

  Widget _buildClearBtn(BuildContext context, WidgetRef ref, bool enabled) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: '清空阅读历史',
      child: Semantics(
        label: '清空阅读历史',
        button: true,
        child: TextButton.icon(
          onPressed: !enabled
              ? null
              : () async {
                  final confirmed =
                      await showDialog<bool>(
                        context: context,
                        builder: (context) =>
                            const _ConfirmClearHistoryDialog(),
                      ) ??
                      false;
                  if (!confirmed) return;
                  try {
                    await ref
                        .read(readingHistoryRepoProvider)
                        .clearAllHistory();
                    if (context.mounted) {
                      showSuccessSnackBar(context, '已清空阅读历史');
                    }
                  } catch (e) {
                    if (context.mounted) showErrorSnackBar(context, e);
                  }
                },
          icon: Icon(LucideIcons.trash2, size: 16),
          label: const Text(
            '清空',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
              if (states.contains(MaterialState.hovered)) {
                return cs.error;
              }
              return cs.warning;
            }),
            backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
              if (states.contains(MaterialState.hovered)) {
                return cs.error.withAlpha(24);
              }
              return Colors.transparent;
            }),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            padding: WidgetStateProperty.all(
              const .symmetric(horizontal: 12, vertical: 8),
            ),
            overlayColor: MaterialStateProperty.all(
              cs.error.withAlpha(20),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryList extends ConsumerWidget {
  const _HistoryList({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rawData = ref.watch(readingHistoryStreamProvider);

    return rawData.when(
      data: (history) {
        final q = query.trim().toLowerCase();
        final filtered = q.isEmpty
            ? history
            : history
                  .where((h) => h.title.toLowerCase().contains(q))
                  .toList(growable: false);

        if (filtered.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 48),
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: filtered
              .map(
                (h) => ReadingHistoryCard(
                  history: h,
                  onTap: () => appRouter.pushNamed(
                    '阅读页面',
                    pathParameters: {'id': h.comicId},
                  ),
                  onDelete: () async {
                    final confirmed =
                        await showDialog<bool>(
                          context: context,
                          builder: (context) =>
                              _ConfirmDeleteHistoryDialog(title: h.title),
                        ) ??
                        false;
                    if (!confirmed) return;
                    try {
                      await ref
                          .read(readingHistoryRepoProvider)
                          .deleteByComicId(h.comicId);
                      if (context.mounted) {
                        showSuccessSnackBar(context, '已删除记录');
                      }
                    } catch (e) {
                      if (context.mounted) showErrorSnackBar(context, e);
                    }
                  },
                ),
              )
              .toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.only(top: 48),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Padding(
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
      ),
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
    );
  }
}

class _ConfirmClearHistoryDialog extends StatelessWidget {
  const _ConfirmClearHistoryDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('确认清空'),
      content: const Text('将清空全部阅读历史记录。此操作不可撤销。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('清空'),
        ),
      ],
    );
  }
}

class _ConfirmDeleteHistoryDialog extends StatelessWidget {
  const _ConfirmDeleteHistoryDialog({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('删除记录？'),
      content: Text('将删除「$title」的阅读历史记录。'),
      actions: [
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
  }
}
