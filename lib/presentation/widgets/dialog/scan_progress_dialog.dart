import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hentai_library/config/app_fluent_color_scheme.dart';
import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/domain/entity/entities.dart';
import 'package:hentai_library/domain/enums/enums.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 扫描漫画库时的进度对话框。支持取消、后台扫描，完成后可展示报告。
class ScanProgressDialog extends ConsumerStatefulWidget {
  const ScanProgressDialog({
    super.key,
    this.onBackgroundComplete,
    this.onScanEnd,
  });

  /// 用户点击「后台扫描」后，同步在后台完成时回调（用于 SnackBar 或打开报告）。
  final void Function(SyncReport?)? onBackgroundComplete;

  /// 同步任务结束时回调（成功、失败或取消）。用于单例约束：仅在此后允许再次打开扫描。
  final VoidCallback? onScanEnd;

  @override
  ConsumerState<ScanProgressDialog> createState() => _ScanProgressDialogState();
}

class _ScanProgressDialogState extends ConsumerState<ScanProgressDialog> {
  final ValueNotifier<bool> _isCancelled = ValueNotifier(false);
  bool _runInBackground = false;
  bool _started = false;

  SyncProgress? _progress;
  SyncReport? _report;
  String? _error;
  bool _isRunning = true;

  Future<SyncReport?>? _syncFuture;

  void _startSync() {
    if (_started) return;
    _started = true;
    _syncFuture = ref.read(syncComicsUseCaseProvider).call(
          isCancelled: () => _isCancelled.value,
          onProgress: (p) {
            if (mounted) setState(() => _progress = p);
          },
        );
    _syncFuture!.then((report) {
      if (mounted) {
        setState(() {
          _report = report;
          _isRunning = false;
        });
      }
      if (_runInBackground) {
        widget.onBackgroundComplete?.call(report);
      }
      widget.onScanEnd?.call();
    }).catchError((e, _) {
      if (mounted) {
        setState(() {
          _error = e is AppException ? e.message : e.toString();
          _isRunning = false;
        });
      }
      if (_runInBackground) widget.onBackgroundComplete?.call(null);
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
                if (_error != null) _buildError(theme) else if (_report != null && !_isRunning)
                  _buildReport(theme)
                else
                  _buildProgress(theme),
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

  Widget _buildProgress(ThemeData theme) {
    final cs = theme.colorScheme;
    final p = _progress;
    final total = p?.total ?? 0;
    final current = p?.current ?? 0;
    final hasTotal = total > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p?.message ?? '准备中…',
            style: TextStyle(
              fontSize: 14,
              color: cs.textSecondary,
            ),
          ),
          if (p?.currentPath != null) ...[
            const SizedBox(height: 6),
            Text(
              p!.currentPath!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: cs.textTertiary,
              ),
            ),
          ],
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: hasTotal
                ? LinearProgressIndicator(
                    value: current > 0 ? current / total : 0,
                    backgroundColor: cs.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                    minHeight: 6,
                  )
                : LinearProgressIndicator(
                    backgroundColor: cs.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                    minHeight: 6,
                  ),
          ),
        ],
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

  Widget _buildReport(ThemeData theme) {
    final cs = theme.colorScheme;
    final report = _report!;
    final cancelled = report.cancelled;

    if (cancelled) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Text(
          '已取消扫描',
          style: TextStyle(fontSize: 14, color: cs.textSecondary),
        ),
      );
    }

    return Flexible(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  '共 ${report.addedCount} 条将写入，${report.removedCount} 条将移除',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (report.scannedItems.isEmpty)
              Text(
                '本次无新增漫画',
                style: TextStyle(fontSize: 13, color: cs.textTertiary),
              )
            else
              ...report.scannedItems.map((item) => _ReportRow(item: item, cs: cs)),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    final cs = theme.colorScheme;
    final showReport = _report != null && !_isRunning;
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
          if (showReport || showError)
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
              child: const Text('关闭'),
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

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.item, required this.cs});

  final ScannedItemReport item;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final typeLabel = item.type == ScannedItemType.epub ? 'epub' : '漫画文件夹';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.path,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: cs.borderSubtle),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.textSecondary,
                        ),
                      ),
                    ),
                    if (item.pageCount != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${item.pageCount} 页',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
