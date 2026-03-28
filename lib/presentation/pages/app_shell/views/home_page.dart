import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/config/app_fluent_color_scheme.dart';
import 'package:hentai_library/core/util/snackbar_util.dart';
import 'package:hentai_library/domain/value_objects/sync_report/sync_report.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/routes/routes.dart';
import 'package:hentai_library/presentation/widgets/button/home_refresh_button.dart';
import 'package:hentai_library/presentation/widgets/card_item/comic_card.dart';
import 'package:hentai_library/presentation/widgets/card_item/reading_history_card.dart';
import 'package:hentai_library/presentation/widgets/dialog/scan_progress_dialog.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const int _continueReadingLimit = 5;
  static const int _recentComicsLimit = 6;

  /// 单例扫描约束：扫描进行中不打开新对话框，并提示用户。
  static void _openScanDialogIfAllowed(BuildContext context, WidgetRef ref) {
    if (ref.read(scanInProgressProvider)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('扫描进行中，请勿重复操作'),
            behavior: SnackBarBehavior.floating,
            margin: snackBarMargin(context),
          ),
        );
      }
      return;
    }
    ref.read(scanInProgressProvider.notifier).setInProgress(true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ScanProgressDialog(
        onBackgroundComplete: (SyncReport? report) {
          if (!context.mounted) return;
          ref.read(libraryPageProvider.notifier).refreshStream();
          if (report == null || report.cancelled) return;
          showSuccessSnackBar(
            context,
            '扫描完成，新增 ${report.addedCount} 条，移除 ${report.removedCount} 条',
          );
        },
        onScanEnd: () {
          ref.read(scanInProgressProvider.notifier).setInProgress(false);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comicCount = ref
        .watch(libraryPageProvider.select((s) => s.rawList.length));

    return SafeArea(
      child: SingleChildScrollView(
        padding: .all(24),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            _buildHeader(context, ref),
            const SizedBox(height: 32),
            _buildHeroWidgets(context, ref, comicCount),
            const SizedBox(height: 24),
            _buildShortcutEntries(context, ref),
            const SizedBox(height: 40),
            _buildContinueReadingSection(context, ref),
            const SizedBox(height: 40),
            _buildRecentComicsSection(context, ref),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      mainAxisAlignment: .spaceBetween,
      crossAxisAlignment: .end,
      children: [
        Column(
          crossAxisAlignment: .start,
          children: [
            Text(
              '首页',
              style: TextStyle(
                color: cs.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '下午好，读者',
              style: TextStyle(color: cs.textTertiary, fontSize: 14),
            ),
          ],
        ),
        Row(
          spacing: 8,
          children: [
            HomeRefreshButton(
              onPressed: () async {
                ref.read(libraryPageProvider.notifier).refreshStream();
              },
            ),
            FilledButton.icon(
              onPressed: () => _openScanDialogIfAllowed(context, ref),
              icon: const Icon(LucideIcons.scanSearch, size: 18),
              label: const Text('扫描漫画库'),
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroWidgets(
    BuildContext context,
    WidgetRef ref,
    int comicCount,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: cs.cardShadow,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '漫画库',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: cs.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$comicCount',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: cs.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '共 $comicCount 本',
                    style: TextStyle(fontSize: 13, color: cs.textSecondary),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(LucideIcons.bookImage, size: 32, color: cs.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShortcutEntries(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _ShortcutEntry(
          icon: LucideIcons.library,
          label: '漫画库',
          onTap: () => context.go('/local'),
          colorScheme: cs,
        ),
        _ShortcutEntry(
          icon: LucideIcons.folderTree,
          label: '选中路径',
          onTap: () => context.go('/paths'),
          colorScheme: cs,
        ),
        _ShortcutEntry(
          icon: LucideIcons.history,
          label: '阅读历史',
          onTap: () => context.go('/history'),
          colorScheme: cs,
        ),
        _ShortcutEntry(
          icon: LucideIcons.scanSearch,
          label: '扫描漫画库',
          onTap: () => _openScanDialogIfAllowed(context, ref),
          colorScheme: cs,
        ),
      ],
    );
  }

  Widget _buildContinueReadingSection(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final historyAsync = ref.watch(readingHistoryStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '继续阅读',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: cs.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/history'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '查看全部',
                    style: TextStyle(fontSize: 14, color: cs.primary),
                  ),
                  Icon(LucideIcons.chevronRight, size: 16, color: cs.primary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        historyAsync.when(
          data: (history) {
            final list = history.take(_continueReadingLimit).toList();
            if (list.isEmpty) {
              return _EmptyContinueReading(theme: theme);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: list
                  .map(
                    (h) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ReadingHistoryCard(
                        history: h,
                        onTap: () => appRouter.pushNamed(
                          '阅读页面',
                          pathParameters: {'id': h.comicId},
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              '加载失败',
              style: TextStyle(fontSize: 14, color: cs.textSecondary),
            ),
          ),
          skipLoadingOnReload: true,
          skipLoadingOnRefresh: true,
        ),
      ],
    );
  }

  Widget _buildRecentComicsSection(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final comicsAsync = ref.watch(
      libraryPageProvider.select((s) => s.rawComicsAsyncValue),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '最近添加',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: cs.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/local'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '查看全部',
                    style: TextStyle(fontSize: 14, color: cs.primary),
                  ),
                  Icon(LucideIcons.chevronRight, size: 16, color: cs.primary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        comicsAsync.when(
          data: (comics) {
            final list = comics.take(_recentComicsLimit).toList();
            if (list.isEmpty) {
              return _EmptyRecentComics(theme: theme);
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                mainAxisExtent: 356,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: list.length,
              itemBuilder: (BuildContext context, int index) {
                final comic = list[index];
                return ComicCard(
                  key: Key(comic.comicId),
                  comic: comic,
                  size: const Size(double.infinity, double.infinity),
                  onTap: () => appRouter.pushNamed(
                    '漫画详情',
                    pathParameters: {'id': comic.comicId},
                  ),
                  onPlay: () {},
                  onRightClick: (_) {},
                );
              },
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              '加载失败',
              style: TextStyle(fontSize: 14, color: cs.textSecondary),
            ),
          ),
          skipLoadingOnReload: true,
        ),
      ],
    );
  }
}

class _EmptyContinueReading extends StatelessWidget {
  const _EmptyContinueReading({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.bookOpen, size: 40, color: cs.textTertiary),
            const SizedBox(height: 12),
            Text(
              '暂无阅读记录',
              style: TextStyle(fontSize: 14, color: cs.textTertiary),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => context.go('/history'),
              icon: Icon(LucideIcons.history, size: 16, color: cs.primary),
              label: Text(
                '查看阅读历史',
                style: TextStyle(fontSize: 14, color: cs.primary),
              ),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRecentComics extends StatelessWidget {
  const _EmptyRecentComics({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.library, size: 40, color: cs.textTertiary),
            const SizedBox(height: 12),
            Text(
              '暂无漫画，请先添加路径并扫描',
              style: TextStyle(fontSize: 14, color: cs.textTertiary),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => context.go('/paths'),
              icon: Icon(LucideIcons.folderPlus, size: 16, color: cs.primary),
              label: Text(
                '添加路径',
                style: TextStyle(fontSize: 14, color: cs.primary),
              ),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutEntry extends StatelessWidget {
  const _ShortcutEntry({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.colorScheme,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorScheme.borderSubtle),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
