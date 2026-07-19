import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
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
    final l10n = context.l10n;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final String publishedLabel = DateFormat(
      'yyyy-MM-dd',
    ).format(release.publishedAt.toLocal());
    return HentaiDialog(
      title: l10n.updateNewVersionTitle(release.version),
      width: 480,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            l10n.updatePublishedOn(publishedLabel),
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
          child: Text(l10n.updateRemindLater),
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
          child: Text(l10n.updateViewDetails),
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
                showInfoToast(context, l10n.updateManualDownloadToast);
              }
              return;
            }
            if (!context.mounted) {
              return;
            }
            await showAppUpdateDownloadDialog(context: context, asset: asset);
          },
          child: Text(l10n.updateNow),
        ),
      ],
    );
  }
}
