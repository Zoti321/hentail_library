import 'package:flutter/material.dart';
import 'package:hentai_library/features/resource_metadata/public/contracts.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';
import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

class MediaDashboard extends StatelessWidget {
  const MediaDashboard({super.key, required this.summary});
  final MediaOverview summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final format = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final stats = [
      (
        label: l10n.mediaResourceTotal,
        count: summary.total,
        caption: l10n.mediaLocalScope(summary.localLibraries),
        icon: Symbols.perm_media,
        color: scheme.primaryContainer,
        foreground: scheme.onPrimaryContainer,
      ),
      (
        label: l10n.mediaWritten,
        count: summary.completed,
        caption: l10n.mediaWrittenCaption,
        icon: Symbols.check_circle,
        color: scheme.secondaryContainer,
        foreground: scheme.onSecondaryContainer,
      ),
      (
        label: l10n.mediaNotEnabled,
        count: summary.disabled,
        caption: l10n.mediaNotEnabledCaption,
        icon: Symbols.pause_circle,
        color: scheme.surfaceContainerHigh,
        foreground: scheme.onSurface,
      ),
    ];
    final statuses = [
      (
        label: l10n.writebackPending,
        count: summary.pending,
        caption: l10n.mediaPendingCaption,
        icon: Symbols.schedule,
      ),
      (
        label: l10n.writebackProcessing,
        count: summary.processing,
        caption: l10n.mediaProcessingCaption,
        icon: Symbols.sync,
      ),
      (
        label: l10n.writebackFailed,
        count: summary.failed,
        caption: l10n.mediaFailedCaption,
        icon: Symbols.error_outline,
      ),
      (
        label: l10n.writebackUnsupported,
        count: summary.unsupported,
        caption: l10n.mediaUnsupportedCaption,
        icon: Symbols.info,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns =
                constraints.maxWidth >= 640 &&
                    MediaQuery.textScalerOf(context).scale(1) <= 1.5
                ? 3
                : 1;
            final width =
                (constraints.maxWidth - theme.spacing.md * (columns - 1)) /
                columns;
            return Wrap(
              spacing: theme.spacing.md,
              runSpacing: theme.spacing.md,
              children: [
                for (final stat in stats)
                  SizedBox(
                    width: width,
                    child: _MetricCard(
                      label: stat.label,
                      value: format.format(stat.count),
                      caption: stat.caption,
                      icon: stat.icon,
                      color: stat.color,
                      foreground: stat.foreground,
                    ),
                  ),
              ],
            );
          },
        ),
        SizedBox(height: theme.spacing.xl),
        Padding(
          padding: EdgeInsets.only(
            left: theme.spacing.lg,
            right: theme.spacing.lg,
            bottom: theme.spacing.sm,
          ),
          child: SettingsSectionHeader(
            title: Text(l10n.mediaWritingOverview),
            description: Text(
              l10n.mediaEnabledScope(
                summary.enabledLibraries,
                summary.localLibraries,
              ),
            ),
          ),
        ),
        M3EList(
          itemCount: statuses.length,
          itemBuilder: (context, index) {
            final status = statuses[index];
            return M3EListItem(
              headline: status.label,
              supportingText: status.caption,
              leading: Icon(
                status.icon,
                color: status.count > 0 && index == 2
                    ? scheme.error
                    : scheme.onSurfaceVariant,
              ),
              trailing: Text(
                format.format(status.count),
                style: theme.typeScale.titleLarge.copyWith(
                  color: status.count > 0 && index == 2
                      ? scheme.error
                      : scheme.onSurface,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
    required this.foreground,
  });
  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    return Semantics(
      container: true,
      label: '$label, $value, $caption',
      excludeSemantics: true,
      child: M3ECard(
        variant: M3ECardVariant.filled,
        color: color,
        padding: EdgeInsets.all(theme.spacing.lg),
        focusable: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: foreground),
                SizedBox(width: theme.spacing.sm),
                Expanded(
                  child: Text(
                    label,
                    style: theme.typeScale.titleMedium.copyWith(
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: theme.spacing.lg),
            Text(
              value,
              style: theme.typeScale.displaySmall.copyWith(color: foreground),
            ),
            SizedBox(height: theme.spacing.xs),
            Text(
              caption,
              style: theme.typeScale.bodyMedium.copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}
