import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/core/util/open_downloaded_file.dart';
import 'package:hentai_library/core/util/utils.dart';
import 'package:hentai_library/domain/models/app_release_info.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/hentai_dialog.dart';
import 'package:hentai_library/ui/features/shell/di/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Future<void> showAppUpdateDownloadDialog({
  required BuildContext context,
  required AppReleaseAsset asset,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AppUpdateDownloadDialog(asset: asset);
    },
  );
}

class AppUpdateDownloadDialog extends HookConsumerWidget {
  const AppUpdateDownloadDialog({super.key, required this.asset});

  final AppReleaseAsset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final ValueNotifier<double?> progress = useState<double?>(0);
    final ValueNotifier<int> receivedBytes = useState<int>(0);
    final ValueNotifier<int> totalBytes = useState<int>(asset.size);
    final ValueNotifier<bool> isDownloading = useState<bool>(true);
    final ValueNotifier<bool> hasFailed = useState<bool>(false);
    final ObjectRef<CancelToken?> cancelTokenRef = useRef<CancelToken?>(null);
    Future<void> startDownload() async {
      isDownloading.value = true;
      hasFailed.value = false;
      progress.value = 0;
      receivedBytes.value = 0;
      totalBytes.value = asset.size;
      final CancelToken cancelToken = CancelToken();
      cancelTokenRef.value = cancelToken;
      try {
        final String savedPath = await ref
            .read(appUpdateServiceProvider)
            .downloadAsset(
              asset: asset,
              cancelToken: cancelToken,
              onProgress: (int received, int total) {
                receivedBytes.value = received;
                if (total > 0) {
                  totalBytes.value = total;
                  progress.value = received / total;
                }
              },
            );
        if (!context.mounted) {
          return;
        }
        Navigator.of(context).pop();
        await openDownloadedUpdateFile(savedPath);
      } on DioException catch (error) {
        if (CancelToken.isCancel(error)) {
          return;
        }
        hasFailed.value = true;
        isDownloading.value = false;
      } catch (_) {
        hasFailed.value = true;
        isDownloading.value = false;
      } finally {
        cancelTokenRef.value = null;
      }
    }

    useEffect(() {
      unawaited(startDownload());
      return () {
        cancelTokenRef.value?.cancel();
      };
    }, const <Object?>[]);
    final String progressLabel = totalBytes.value > 0
        ? '${receivedBytes.value.toReadableSize()} / ${totalBytes.value.toReadableSize()}'
        : receivedBytes.value.toReadableSize();
    return HentaiDialog(
      title: '正在下载更新',
      width: 420,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            asset.name,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.hentai.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: hasFailed.value ? null : progress.value,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 8),
          Text(
            hasFailed.value ? '下载失败，请重试' : progressLabel,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.hentai.textTertiary,
            ),
          ),
        ],
      ),
      actions: <Widget>[
        if (isDownloading.value)
          TextButton(
            onPressed: () {
              cancelTokenRef.value?.cancel();
              Navigator.of(context).pop();
            },
            child: const Text('取消'),
          )
        else if (hasFailed.value) ...<Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => unawaited(startDownload()),
            child: const Text('重试'),
          ),
        ],
      ],
    );
  }
}
