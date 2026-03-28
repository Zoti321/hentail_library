import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hentai_library/config/app_fluent_color_scheme.dart';
import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 扫描漫画库对话框：同步中、完成/已取消/错误；不展示进度明细与条目报告。
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

  Future<void>? _syncFuture;

  void _startSync() {
    if (_started) return;
    _started = true;
    _syncFuture = ref.read(syncComicsUseCaseProvider).call(
          isCancelled: () => _isCancelled.value,
        );
    _syncFuture!.then((_) {
      if (mounted) {
        setState(() {
          _isRunning = false;
        });
      }
      if (_runInBackground) {
        widget.onBackgroundComplete?.call();
      }
      widget.onScanEnd?.call();
    }).catchError((e, _) {
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
                else if (!_isRunning)
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '同步中…',
            style: TextStyle(
              fontSize: 14,
              color: cs.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDone(ThemeData theme) {
    final cs = theme.colorScheme;
    final label = _isCancelled.value ? '已取消扫描' : '同步完成';
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
    final showClose = _error != null || !_isRunning;
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
