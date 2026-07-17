import 'package:flutter/material.dart';
import 'package:hentai_library/domain/library/sync_library_types.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/feedback/terminal_spinner.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/hentai_dialog.dart';
import 'package:hentai_library/ui/features/shell/state/scan_library_controller.dart';
import 'package:hentai_library/ui/providers/comic_cover_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const double _kScanProgressDialogWidth = 480;
const double _kScanProgressDialogRadius = 4;
const double _kScanProgressBodyMinHeight = 96;

/// 扫描漫画库对话框：同步进度、完成/已取消/错误。
class ScanProgressDialog extends ConsumerWidget {
  const ScanProgressDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ScanLibraryState state = ref.watch(scanLibraryControllerProvider);
    final ThumbnailBackgroundProgress thumbnailProgress = ref.watch(
      thumbnailEventCoordinatorProvider,
    );
    final bool syncDone = state.progress?.phase == SyncLibraryPhase.done;
    final bool showClose = state.error != null || !state.running || syncDone;
    final bool showError = state.error != null;

    return HentaiDialog(
      title: '扫描漫画库',
      width: _kScanProgressDialogWidth,
      borderRadius: _kScanProgressDialogRadius,
      backgroundColor: cs.surface,
      showFooterDivider: false,
      scrollableContent: false,
      contentPadding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: _kScanProgressBodyMinHeight,
        ),
        child: _buildBody(context, state, thumbnailProgress),
      ),
      actions: showClose
          ? <Widget>[
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      _kScanProgressDialogRadius,
                    ),
                  ),
                ),
                child: Text(showError ? '关闭' : '确定'),
              ),
            ]
          : <Widget>[
              TextButton(
                onPressed: () {
                  ref.read(scanLibraryControllerProvider.notifier).cancel();
                  if (context.mounted) Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      _kScanProgressDialogRadius,
                    ),
                  ),
                ),
                child: const Text('取消'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  ref
                      .read(scanLibraryControllerProvider.notifier)
                      .setRunInBackground(true);
                  if (context.mounted) Navigator.of(context).pop();
                },
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      _kScanProgressDialogRadius,
                    ),
                  ),
                ),
                child: const Text('后台扫描'),
              ),
            ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    ScanLibraryState state,
    ThumbnailBackgroundProgress thumbnailProgress,
  ) {
    if (state.error != null) {
      return _buildError(context, state.error!);
    }
    if (!state.running || state.progress?.phase == SyncLibraryPhase.done) {
      return _buildDone(
        context,
        state.cancelled,
        state.progress,
        thumbnailProgress,
      );
    }
    return _buildRunning(context, state.progress);
  }

  Widget _buildRunning(BuildContext context, SyncLibraryProgress? progress) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TerminalSpinner(color: cs.primary),
        const SizedBox(width: 12),
        Expanded(
          child: progress == null
              ? Text(
                  '准备中…',
                  style: TextStyle(fontSize: 14, color: cs.hentai.textPrimary),
                )
              : _buildRunningContent(context, progress),
        ),
      ],
    );
  }

  Widget _buildRunningContent(
    BuildContext context,
    SyncLibraryProgress progress,
  ) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextStyle primaryStyle = TextStyle(
      fontSize: 14,
      color: cs.hentai.textPrimary,
    );
    final TextStyle secondaryStyle = TextStyle(
      fontSize: 13,
      color: cs.hentai.textSecondary,
    );
    final TextStyle tertiaryStyle = TextStyle(
      fontSize: 13,
      color: cs.hentai.textTertiary,
    );

    if (progress.route == SyncLibraryRoute.withRoots &&
        progress.phase == SyncLibraryPhase.generatingThumbnails) {
      final int total = progress.thumbnailTotal ?? 0;
      final int done = progress.thumbnailDone ?? 0;
      final int failed = progress.thumbnailFailedCount ?? 0;
      final String? path = progress.currentPath;
      final double? progressValue = total > 0 ? done / total : null;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('正在生成缩略图…', style: primaryStyle),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progressValue,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 8),
          Text(
            '$done / $total${failed > 0 ? ' · 失败 $failed' : ''}',
            style: secondaryStyle,
          ),
          if (path != null && path.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              path,
              style: tertiaryStyle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      );
    }

    final String stageLabel = _runningStagePrimaryLabel(progress);
    final String? detail = _runningStageDetail(progress);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(stageLabel, style: primaryStyle),
        if (detail != null && detail.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            detail,
            style: secondaryStyle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  String _runningStagePrimaryLabel(SyncLibraryProgress progress) {
    switch (progress.route) {
      case SyncLibraryRoute.noRootsNoop:
        return '同步中…';
      case SyncLibraryRoute.noRootsCleared:
        return progress.phase == SyncLibraryPhase.writingDb
            ? '正在写入数据库…'
            : '正在清空漫画库…';
      case SyncLibraryRoute.withRoots:
        return switch (progress.phase) {
          SyncLibraryPhase.clearingLibrary => '正在清空漫画库…',
          SyncLibraryPhase.scanning => '正在扫描文件…',
          SyncLibraryPhase.writingDb => '正在写入数据库…',
          SyncLibraryPhase.generatingThumbnails => '正在生成缩略图…',
          SyncLibraryPhase.done => '同步完成',
          SyncLibraryPhase.failed => '同步失败',
        };
    }
  }

  String? _runningStageDetail(SyncLibraryProgress progress) {
    if (progress.route != SyncLibraryRoute.withRoots) {
      return null;
    }
    if (progress.phase != SyncLibraryPhase.scanning) {
      return null;
    }
    final String? path = progress.currentPath;
    if (path == null || path.isEmpty) {
      return null;
    }
    return path;
  }

  Widget _buildDone(
    BuildContext context,
    bool cancelled,
    SyncLibraryProgress? progress,
    ThumbnailBackgroundProgress thumbnailProgress,
  ) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextStyle bodyStyle = TextStyle(
      fontSize: 14,
      color: cs.hentai.textSecondary,
    );
    final TextStyle tertiaryStyle = TextStyle(
      fontSize: 13,
      color: cs.hentai.textTertiary,
    );

    if (cancelled) {
      return Text('已取消扫描', style: bodyStyle);
    }

    final String label = _doneSummaryLabel(progress);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(label, style: bodyStyle),
        if (thumbnailProgress.isActive) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            '后台生成缩略图 ${thumbnailProgress.done} / ${thumbnailProgress.total}'
            '${thumbnailProgress.failed > 0 ? ' · 失败 ${thumbnailProgress.failed}' : ''}',
            style: tertiaryStyle,
          ),
        ],
      ],
    );
  }

  String _doneSummaryLabel(SyncLibraryProgress? progress) {
    if (progress == null) {
      return '同步完成';
    }

    switch (progress.route) {
      case SyncLibraryRoute.noRootsNoop:
        return '未配置有效路径，库中无漫画，同步已完成。';
      case SyncLibraryRoute.noRootsCleared:
        return '已清空现有漫画数据。';
      case SyncLibraryRoute.withRoots:
        final int? removed = progress.removedCount;
        final int? added = progress.addedCount;
        final int? kept = progress.keptCount;
        final int? thumbFailed = progress.thumbnailFailedCount;
        if (removed != null && added != null && kept != null) {
          final String thumbSuffix = thumbFailed != null && thumbFailed > 0
              ? ' · 缩略图失败 $thumbFailed'
              : '';
          return '同步完成 · 移除 $removed · 新增 $added · 保留 $kept$thumbSuffix';
        }
        return '同步完成';
    }
  }

  Widget _buildError(BuildContext context, String error) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(LucideIcons.circleAlert, size: 20, color: cs.error),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            error,
            style: TextStyle(fontSize: 13, color: cs.hentai.textSecondary),
          ),
        ),
      ],
    );
  }
}
