import 'package:flutter/material.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_sync_outcome.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 同步终态提示：警告与失败只描述结果，不暗示已提交的目录被回滚。
class ImageSetSyncStatusBanner extends StatelessWidget {
  const ImageSetSyncStatusBanner({super.key, required this.outcome});

  final ImageSetSyncOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final (IconData icon, Color color, String text) = switch (outcome) {
      ImageSetSyncSucceeded(:final int addedCount, :final int removedCount) => (
        Icons.check_circle_outline,
        theme.colorScheme.onSurfaceVariant,
        l10n.imageSetLibrarySyncSuccess(addedCount, removedCount),
      ),
      ImageSetSyncWarned(:final String message) => (
        Icons.warning_amber_outlined,
        theme.colorScheme.tertiary,
        l10n.imageSetLibrarySyncWarning(message),
      ),
      ImageSetSyncFailed(:final String message) => (
        Icons.error_outline,
        theme.colorScheme.error,
        l10n.imageSetLibrarySyncFailed(message),
      ),
      ImageSetSyncCancelled() => (
        Icons.cancel_outlined,
        theme.colorScheme.onSurfaceVariant,
        l10n.imageSetLibrarySyncCancelled,
      ),
    };

    return Row(
      key: const ValueKey<String>('imageSetSyncStatus'),
      children: <Widget>[
        Icon(icon, color: color, size: 18),
        SizedBox(width: theme.spacing.sm),
        Expanded(
          child: Text(
            text,
            style: theme.typeScale.bodyMedium.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
