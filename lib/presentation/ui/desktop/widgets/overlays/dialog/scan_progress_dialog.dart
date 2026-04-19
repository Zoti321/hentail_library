import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/feedback/terminal_spinner.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 扫描漫画库对话框：同步进度、完成/已取消/错误。
class ScanProgressDialog extends ConsumerWidget {
  const ScanProgressDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final state = ref.watch(scanLibraryControllerProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 480,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: BoxDecoration(
              color: cs.cardHover,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.borderSubtle, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(theme),
                if (state.error != null)
                  _buildError(theme, state.error!)
                else if (!state.running ||
                    state.progress?.phase == SyncLibraryPhase.done)
                  _buildDone(theme, state.cancelled, state.progress)
                else
                  _buildRunning(theme, state.progress),
                _buildFooter(context, ref, theme, state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cs.borderSubtle, width: 1)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.scanSearch, size: 20, color: cs.primary),
          const SizedBox(width: 10),
          Text(
            '扫描漫画库',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cs.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunning(ThemeData theme, SyncLibraryProgress? progress) {
    final cs = theme.colorScheme;
    final p = progress;

    if (p == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TerminalSpinner(color: cs.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '准备中…',
                style: TextStyle(fontSize: 14, color: cs.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TerminalSpinner(color: cs.primary),
              const SizedBox(width: 12),
              Expanded(child: _buildRunningBody(theme, p)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRunningBody(ThemeData theme, SyncLibraryProgress p) {
    final cs = theme.colorScheme;
    final secondary = TextStyle(fontSize: 14, color: cs.textSecondary);

    switch (p.route) {
      case SyncLibraryRoute.noRootsNoop:
        return Text('同步中…', style: secondary);
      case SyncLibraryRoute.noRootsCleared:
        return Text(
          p.phase == SyncLibraryPhase.writingDb ? '正在写入…' : '正在清空漫画库…',
          style: secondary,
        );
      case SyncLibraryRoute.withRoots:
        return _buildWithRootsRunning(theme, p, secondary);
    }
  }

  Widget _buildWithRootsRunning(
    ThemeData theme,
    SyncLibraryProgress p,
    TextStyle secondary,
  ) {
    final cs = theme.colorScheme;

    if (p.phase == SyncLibraryPhase.writingDb) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('正在应用扫描结果到数据库…', style: secondary),
          const SizedBox(height: 8),
          Text(
            '已识别 ${p.acceptedTotal} 本 · (dir: ${p.counts.dir}, zip: ${p.counts.zip}, '
            'cbz: ${p.counts.cbz}, epub: ${p.counts.epub})',
            style: TextStyle(fontSize: 13, color: cs.textSecondary),
          ),
        ],
      );
    }

    final path = p.currentPath;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          path == null || path.isEmpty ? '准备中…' : path,
          style: secondary,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          '已识别 ${p.acceptedTotal} 本 · (dir: ${p.counts.dir}, zip: ${p.counts.zip}, '
          'cbz: ${p.counts.cbz}, epub: ${p.counts.epub})',
          style: TextStyle(fontSize: 13, color: cs.textSecondary),
        ),
      ],
    );
  }

  Widget _buildDone(
    ThemeData theme,
    bool cancelled,
    SyncLibraryProgress? progress,
  ) {
    final cs = theme.colorScheme;
    if (cancelled) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Text(
          '已取消扫描',
          style: TextStyle(fontSize: 14, color: cs.textSecondary),
        ),
      );
    }

    final p = progress;
    final String label;
    if (p != null) {
      switch (p.route) {
        case SyncLibraryRoute.noRootsNoop:
          label = '未配置有效路径，库中无漫画，同步已完成。';
        case SyncLibraryRoute.noRootsCleared:
          label = '已清空现有漫画数据。';
        case SyncLibraryRoute.withRoots:
          final r = p.removedCount;
          final a = p.addedCount;
          final k = p.keptCount;
          if (r != null && a != null && k != null) {
            label = '同步完成 · 移除 $r · 新增 $a · 保留 $k';
          } else {
            label = '同步完成';
          }
      }
    } else {
      label = '同步完成';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        label,
        style: TextStyle(fontSize: 14, color: cs.textSecondary),
      ),
    );
  }

  Widget _buildError(ThemeData theme, String error) {
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Icon(LucideIcons.circleAlert, size: 20, color: cs.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: TextStyle(fontSize: 13, color: cs.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ScanLibraryState state,
  ) {
    final cs = theme.colorScheme;
    final syncDone = state.progress?.phase == SyncLibraryPhase.done;
    final showClose = state.error != null || !state.running || syncDone;
    final showError = state.error != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.borderSubtle, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        spacing: 8,
        children: [
          if (showClose)
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(showError ? '关闭' : '确定'),
            )
          else ...[
            TextButton(
              onPressed: () {
                ref.read(scanLibraryControllerProvider.notifier).cancel();
                if (context.mounted) Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: cs.textSecondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                ref
                    .read(scanLibraryControllerProvider.notifier)
                    .setRunInBackground(true);
                if (context.mounted) Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('后台扫描'),
            ),
          ],
        ],
      ),
    );
  }
}
