import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/util/open_downloaded_file.dart';
import 'package:hentai_library/domain/models/app_release_info.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/app_update_download_dialog.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/hentai_dialog.dart';
import 'package:hentai_library/ui/features/settings/view_models/settings_notifier.dart';
import 'package:hentai_library/ui/features/shell/di/services.dart';
import 'package:intl/intl.dart';

Future<void> showAppUpdateDialog({
  required BuildContext context,
  required AppReleaseInfo release,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AppUpdateDialog(release: release);
    },
  );
}

class AppUpdateDialog extends ConsumerWidget {
  const AppUpdateDialog({super.key, required this.release});

  final AppReleaseInfo release;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final String publishedLabel = DateFormat(
      'yyyy-MM-dd',
    ).format(release.publishedAt.toLocal());
    return HentaiDialog(
      title: '发现新版本 v${release.version}',
      width: 480,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '发布于 $publishedLabel',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.hentai.textTertiary,
            ),
          ),
          if (release.releaseNotes.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            ...release.releaseNotes.map(
              (String note) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '- $note',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: colorScheme.hentai.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () async {
            await ref
                .read(settingsProvider.notifier)
                .setDismissedUpdateVersion(release.version);
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: const Text('稍后提醒'),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop();
            try {
              await openReleasePage(release.htmlUrl);
            } catch (error) {
              if (context.mounted) {
                showErrorToast(context, error);
              }
            }
          },
          child: const Text('查看详情'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () async {
            Navigator.of(context).pop();
            final AppReleaseAsset? asset = ref
                .read(appUpdateServiceProvider)
                .findPlatformAsset(release.assets);
            if (asset == null) {
              try {
                await openReleasePage(release.htmlUrl);
              } catch (error) {
                if (context.mounted) {
                  showErrorToast(context, error);
                }
                return;
              }
              if (context.mounted) {
                showInfoToast(context, '请手动下载适合您系统的安装包');
              }
              return;
            }
            if (!context.mounted) {
              return;
            }
            await showAppUpdateDownloadDialog(
              context: context,
              asset: asset,
            );
          },
          child: const Text('立即更新'),
        ),
      ],
    );
  }
}
