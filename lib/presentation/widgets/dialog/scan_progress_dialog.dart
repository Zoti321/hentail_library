import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hentai_library/config/app_fluent_color_scheme.dart';
import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/widgets/terminal_spinner.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 扫描漫画库对话框：同步进度、完成/已取消/错误。
class ScanProgressDialog extends ConsumerStatefulWidget {
  const ScanProgressDialog({
    super.key,
    this.onBackgroundComplete,
    this.onScanEnd,
  });

  /// 用户点击「后台扫描」后，同步在后台完成时回调（例如刷新列表）。
  final VoidCallback? onBackgroundComplete;

  /// 同步任务结束时回调（成功、失败或取消）。用于单例约束：仅在此后允许再次打开扫描。
  final VoidCallback? onScanEnd;

  @override
  ConsumerState<ScanProgressDialog> createState() => _ScanProgressDialogState();
}

class _ScanProgressDialogState extends ConsumerState<ScanProgressDialog> {
  final ValueNotifier<bool> _isCancelled = ValueNotifier(false);
  bool _runInBackground = false;
  bool _started = false;

  String? _error;
  bool _isRunning = true;

  SyncLibraryProgress? _progress;

  Future<void>? _syncFuture;

  void _startSync() {
    if (_started) return;
    _started = true;
    _syncFuture = ref
        .read(syncComicsUseCaseProvider)
        .call(
          isCancelled: () => _isCancelled.value,
          onProgress: (p) {
            if (!mounted) return;
            setState(() => _progress = p);
          },
        );
    _syncFuture!
        .then((_) {
          if (mounted) {
            setState(() {
              _isRunning = false;
            });
          }
          if (_runInBackground) {
            widget.onBackgroundComplete?.call();
          }
          widget.onScanEnd?.call();
        })
        .catchError((e, _) {
          if (mounted) {
            setState(() {
              _error = e is AppException ? e.message : e.toString();
              _isRunning = false;
            });
          }
          if (_runInBackground) widget.onBackgroundComplete?.call();
          widget.onScanEnd?.call();
        });
  }

  @override
  void dispose() {
    _isCancelled.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSync());

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
                if (_error != null)
                  _buildError(theme)
                else if (!_isRunning ||
                    _progress?.phase == SyncLibraryPhase.done)
                  _buildDone(theme)
                else
                  _buildRunning(theme),
                _buildFooter(theme),
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

  Widget _buildRunning(ThemeData theme) {
    final cs = theme.colorScheme;
    final p = _progress;

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

  Widget _buildDone(ThemeData theme) {
    final cs = theme.colorScheme;
    if (_isCancelled.value) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Text(
          '已取消扫描',
          style: TextStyle(fontSize: 14, color: cs.textSecondary),
        ),
      );
    }

    final p = _progress;
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

  Widget _buildError(ThemeData theme) {
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Icon(LucideIcons.circleAlert, size: 20, color: cs.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(fontSize: 13, color: cs.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    final cs = theme.colorScheme;
    final syncDone = _progress?.phase == SyncLibraryPhase.done;
    final showClose = _error != null || !_isRunning || syncDone;
    final showError = _error != null;

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
                _isCancelled.value = true;
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
                _runInBackground = true;
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
