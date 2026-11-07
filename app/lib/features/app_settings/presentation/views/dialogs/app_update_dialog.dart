import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/core/util/open_downloaded_file.dart';
import 'package:hentai_library/features/app_settings/di/app_update_providers.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/settings_notifier.dart';
import 'package:hentai_library/features/app_settings/presentation/views/dialogs/app_update_download_dialog.dart';
import 'package:hentai_library/features/app_settings/domain/app_release_info.dart';
import 'package:hentai_library/shared/ui/patterns/dialog/lab_dialog_presenter.dart';
import 'package:hentai_library/shared/ui/theme/app_m3e_theme.dart';
import 'package:hentai_library/shared/ui/theme/lab_text.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/app_snackbar.dart';
import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

Future<void> showAppUpdateDialog({
  required BuildContext context,
  required AppReleaseInfo release,
}) {
  final M3EThemeData m3e = withAppFontFamily(M3ETheme.of(context));
  return LabDialogPresenter.showBasic<void>(
    context,
    dialog: M3ETheme(
      data: m3e,
      child: AppUpdateDialog(release: release),
    ),
  );
}

class AppUpdateDialog extends ConsumerWidget {
  const AppUpdateDialog({super.key, required this.release});

  final AppReleaseInfo release;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3ESpacing spacing = theme.spacing;
    final TextStyle actionLabelStyle = labButtonLabelStyle(
      theme,
      M3EButtonSize.sm,
    );
    final String publishedLabel = DateFormat('yyyy-MM-dd')
        .format(release.publishedAt.toLocal());

    return M3EDialog(
      title: l10n.updateNewVersionTitle(release.version),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            l10n.updatePublishedOn(publishedLabel),
            style: theme.typeScale.bodySmall.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (release.releaseNotes.isNotEmpty) ...<Widget>[
            SizedBox(height: spacing.md),
            ...release.releaseNotes.map(
              (String note) => Padding(
                padding: EdgeInsets.only(bottom: spacing.sm),
                child: Text(
                  '- $note',
                  style: theme.typeScale.bodyMedium.copyWith(
                    height: 1.4,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      bottomDivider: true,
      actions: <Widget>[
        M3EButton(
          onPressed: () async {
            await ref
                .read(settingsProvider.notifier)
                .setDismissedUpdateVersion(release.version);
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          style: M3EButtonStyle.text,
          decoration: M3EButtonDecoration(textStyle: actionLabelStyle),
          label: Text(l10n.updateRemindLater),
        ),
        M3EButton.icon(
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
                  showErrorSnackbar(context, error);
                }
                return;
              }
              if (context.mounted) {
                showInfoSnackbar(context, l10n.updateManualDownloadToast);
              }
              return;
            }
            if (!context.mounted) {
              return;
            }
            await showAppUpdateDownloadDialog(context: context, asset: asset);
          },
          style: M3EButtonStyle.filled,
          size: M3EButtonSize.sm,
          decoration: M3EButtonDecoration(textStyle: actionLabelStyle),
          icon: const Icon(Symbols.download, size: 18),
          label: Text(l10n.updateNow),
        ),
      ],
    );
  }
}
