import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/models/read_models/home_page_read_models.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/scan_progress_dialog.dart';
import 'package:hentai_library/ui/features/shell/view_models/home_alert_dismiss_notifier.dart';
import 'package:hentai_library/ui/features/shell/view_models/home_page_dashboard_notifier.dart';
import 'package:hentai_library/ui/features/shell/views/navigation/library_management_actions.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HomeLibraryAlertStack extends ConsumerWidget {
  const HomeLibraryAlertStack({super.key, required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!enabled) {
      return const SizedBox.shrink();
    }
    final AsyncValue<List<HomeLibraryAlert>> alertsAsync = ref.watch(
      homeLibraryAlertsStreamProvider,
    );
    return alertsAsync.when(
      data: (List<HomeLibraryAlert> alerts) {
        if (alerts.isEmpty) {
          return const SizedBox.shrink();
        }
        final AppThemeTokens tokens = context.tokens;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: alerts
              .map(
                (HomeLibraryAlert alert) => Padding(
                  padding: EdgeInsets.only(bottom: tokens.spacing.md),
                  child: _HomeLibraryAlertCard(alert: alert),
                ),
              )
              .toList(growable: false),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _HomeLibraryAlertCard extends ConsumerWidget {
  const _HomeLibraryAlertCard({required this.alert});

  final HomeLibraryAlert alert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final l10n = context.l10n;
    final bool isError =
        alert.kind == HomeLibraryAlertKind.remoteUnreachable ||
        alert.kind == HomeLibraryAlertKind.syncFailed;
    final Color accent = isError ? cs.hentai.error : cs.hentai.warning;
    final IconData icon = switch (alert.kind) {
      HomeLibraryAlertKind.remoteUnreachable => LucideIcons.cloudOff,
      HomeLibraryAlertKind.syncFailed => LucideIcons.circleAlert,
      HomeLibraryAlertKind.staleSync => LucideIcons.clock3,
      HomeLibraryAlertKind.pendingResourcesDetected => LucideIcons.filePlus,
    };
    final String message = switch (alert.kind) {
      HomeLibraryAlertKind.remoteUnreachable => l10n.homeAlertRemoteUnreachable(
        alert.displayName,
      ),
      HomeLibraryAlertKind.syncFailed => l10n.homeAlertSyncFailed(
        alert.displayName,
      ),
      HomeLibraryAlertKind.staleSync => l10n.homeAlertStaleSync(
        alert.displayName,
        alert.staleDays ?? 1,
      ),
      HomeLibraryAlertKind.pendingResourcesDetected =>
        l10n.homeAlertPendingResources(
          alert.displayName,
          alert.pendingResourceCount ?? 0,
        ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.alphaBlend(accent.withAlpha(18), cs.surface),
        borderRadius: BorderRadius.circular(tokens.radius.sm),
        border: Border.all(color: accent.withAlpha(120)),
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.spacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: accent, size: 20),
            SizedBox(width: tokens.spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    message,
                    style: TextStyle(
                      color: cs.hentai.textPrimary,
                      fontSize: tokens.text.bodySm,
                      height: 1.4,
                    ),
                  ),
                  if (alert.lastErrorMessage case final String detail
                      when detail.isNotEmpty &&
                          alert.kind == HomeLibraryAlertKind.syncFailed)
                    Padding(
                      padding: EdgeInsets.only(top: tokens.spacing.xs),
                      child: Text(
                        detail,
                        style: TextStyle(
                          color: cs.hentai.textSecondary,
                          fontSize: tokens.text.labelXs,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  SizedBox(height: tokens.spacing.sm),
                  Wrap(
                    spacing: tokens.spacing.sm,
                    runSpacing: tokens.spacing.xs,
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: () => _scanLibrary(context, ref),
                        icon: const Icon(LucideIcons.scanSearch, size: 16),
                        label: Text(l10n.homeScanLibrary),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref
                            .read(homeAlertDismissStoreProvider.notifier)
                            .dismiss(alert),
                        child: Text(l10n.homeAlertDismissLater),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scanLibrary(BuildContext context, WidgetRef ref) async {
    await LibraryManagementActions.scanLibrary(ref, context, alert.libraryId);
    if (!context.mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ScanProgressDialog(),
    );
    await ref
        .read(homeAlertDismissStoreProvider.notifier)
        .clearForLibrary(alert.libraryId);
  }
}
