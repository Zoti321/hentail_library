import 'dart:async';

import 'package:hentai_library/shared/application/cancellation_token.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/core/logging/app_log.dart';
import 'package:hentai_library/core/util/open_downloaded_file.dart';
import 'package:hentai_library/core/util/utils.dart';
import 'package:hentai_library/features/app_settings/presentation/providers/app_update_providers.dart';
import 'package:hentai_library/features/app_settings/domain/app_release_info.dart';
import 'package:hentai_library/shared/ui/patterns/dialog/lab_dialog_presenter.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

Future<void> showAppUpdateDownloadDialog({
  required BuildContext context,
  required AppReleaseAsset asset,
}) {
  final M3EThemeData m3e = withAppFontFamily(M3ETheme.of(context));
  return LabDialogPresenter.showBasic<void>(
    context,
    barrierDismissible: false,
    dialog: M3ETheme(
      data: m3e,
      child: AppUpdateDownloadDialog(asset: asset),
    ),
  );
}

class AppUpdateDownloadDialog extends HookConsumerWidget {
  const AppUpdateDownloadDialog({super.key, required this.asset});

  final AppReleaseAsset asset;

  void _handleCancelDownload(
    BuildContext context,
    ObjectRef<CancellationToken?> cancelTokenRef,
  ) {
    cancelTokenRef.value?.cancel();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ESpacing spacing = theme.spacing;
    final TextStyle actionLabelStyle = labButtonLabelStyle(
      theme,
      M3EButtonSize.sm,
    );
    final ValueNotifier<double?> progress = useState<double?>(0);
    final ValueNotifier<int> receivedBytes = useState<int>(0);
    final ValueNotifier<int> totalBytes = useState<int>(asset.size);
    final ValueNotifier<bool> isDownloading = useState<bool>(true);
    final ValueNotifier<bool> hasFailed = useState<bool>(false);
    final ObjectRef<CancellationToken?> cancelTokenRef =
        useRef<CancellationToken?>(null);

    Future<void> startDownload() async {
      isDownloading.value = true;
      hasFailed.value = false;
      progress.value = 0;
      receivedBytes.value = 0;
      totalBytes.value = asset.size;
      final CancellationToken cancelToken = CancellationToken();
      cancelTokenRef.value = cancelToken;
      try {
        final String savedPath = await ref
            .read(appUpdateGatewayProvider)
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
      } on OperationCancelledException {
        return;
      } catch (error, stackTrace) {
        logError(AppLog.ui('appUpdate'), '下载更新失败', error, stackTrace);
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

    return M3EDialog(
      title: l10n.updateDownloadingTitle,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            asset.name,
            style: theme.typeScale.bodyMedium.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: spacing.lg),
          M3EProgressIndicator.linear(
            value: hasFailed.value ? null : progress.value,
            color: hasFailed.value ? scheme.error : scheme.primary,
            trackColor: scheme.surfaceContainerHighest,
          ),
          SizedBox(height: spacing.sm),
          Text(
            hasFailed.value ? l10n.updateDownloadFailed : progressLabel,
            style: theme.typeScale.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      bottomDivider: true,
      actions: <Widget>[
        if (isDownloading.value)
          M3EButton(
            onPressed: () => _handleCancelDownload(context, cancelTokenRef),
            style: M3EButtonStyle.text,
            decoration: M3EButtonDecoration(textStyle: actionLabelStyle),
            label: Text(l10n.commonCancel),
          )
        else if (hasFailed.value) ...<Widget>[
          M3EButton(
            onPressed: () => Navigator.of(context).pop(),
            style: M3EButtonStyle.text,
            decoration: M3EButtonDecoration(textStyle: actionLabelStyle),
            label: Text(l10n.commonClose),
          ),
          M3EButton(
            onPressed: () => unawaited(startDownload()),
            style: M3EButtonStyle.filled,
            decoration: M3EButtonDecoration(textStyle: actionLabelStyle),
            label: Text(l10n.commonRetry),
          ),
        ],
      ],
    );
  }
}
