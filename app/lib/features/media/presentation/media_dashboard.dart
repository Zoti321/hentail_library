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
    final writeable = summary.total - summary.disabled;
    final coverage = writeable <= 0
        ? 0.0
        : (summary.completed / writeable).clamp(0.0, 1.0);
    final stats = [
      (
        label: l10n.mediaResourceTotal,
        count: summary.total,
        caption: l10n.mediaLocalScope(summary.localLibraries),
        icon: Symbols.perm_media,
        color: scheme.primaryContainer,
        foreground: scheme.onPrimaryContainer,
        radius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(28),
        ),
        emphasis: true,
      ),
      (
        label: l10n.mediaWritten,
        count: summary.completed,
        caption: l10n.mediaWrittenCaption,
        icon: Symbols.check_circle,
        color: scheme.secondaryContainer,
        foreground: scheme.onSecondaryContainer,
        radius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(28),
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(12),
        ),
        emphasis: false,
      ),
      (
        label: l10n.mediaNotEnabled,
        count: summary.disabled,
        caption: l10n.mediaNotEnabledCaption,
        icon: Symbols.pause_circle,
        color: scheme.surfaceContainerHigh,
        foreground: scheme.onSurface,
        radius: BorderRadius.circular(16),
        emphasis: false,
      ),
    ];
    final statuses = [
      (
        label: l10n.writebackPending,
        count: summary.pending,
        caption: l10n.mediaPendingCaption,
        icon: Symbols.schedule,
        tone: _StatusTone.neutral,
      ),
      (
        label: l10n.writebackProcessing,
        count: summary.processing,
        caption: l10n.mediaProcessingCaption,
        icon: Symbols.sync,
        tone: _StatusTone.active,
      ),
      (
        label: l10n.writebackFailed,
        count: summary.failed,
        caption: l10n.mediaFailedCaption,
        icon: Symbols.error_outline,
        tone: _StatusTone.error,
      ),
      (
        label: l10n.writebackUnsupported,
        count: summary.unsupported,
        caption: l10n.mediaUnsupportedCaption,
        icon: Symbols.info,
        tone: _StatusTone.neutral,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final scaler = MediaQuery.textScalerOf(context).scale(1);
            final columns = switch ((constraints.maxWidth, scaler)) {
              (final w, final s) when w >= 960 && s <= 1.5 => 3,
              (final w, final s) when w >= 560 && s <= 1.8 => 2,
              _ => 1,
            };
            final gap = theme.spacing.md;
            final width =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
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
                      borderRadius: stat.radius,
                      emphasis: stat.emphasis,
                    ),
                  ),
              ],
            );
          },
        ),
        if (writeable > 0) ...[
          SizedBox(height: theme.spacing.md),
          _WriteCoverageStrip(
            label: l10n.mediaWritten,
            detail: '${format.format(summary.completed)} / '
                '${format.format(writeable)}',
            progress: coverage,
          ),
        ],
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
        SplitListGroup(
          children: [
            for (final status in statuses)
              _StatusRow(
                label: status.label,
                caption: status.caption,
                count: format.format(status.count),
                icon: status.icon,
                tone: status.tone,
                hasCount: status.count > 0,
              ),
          ],
        ),
      ],
    );
  }
}

enum _StatusTone { neutral, active, error }

class _WriteCoverageStrip extends StatelessWidget {
  const _WriteCoverageStrip({
    required this.label,
    required this.detail,
    required this.progress,
  });

  final String label;
  final String detail;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      label: '$label, $detail',
      child: TonalSurface(
        padding: EdgeInsets.fromLTRB(
          theme.spacing.lg,
          theme.spacing.md,
          theme.spacing.lg,
          theme.spacing.md + 2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.typeScale.titleSmall.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  detail,
                  style: theme.typeScale.labelLarge.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            SizedBox(height: theme.spacing.sm + 2),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: scheme.surfaceContainerHighest,
                color: scheme.primary,
              ),
            ),
          ],
        ),
      ),
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
    required this.borderRadius,
    required this.emphasis,
  });
  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;
  final Color foreground;
  final BorderRadius borderRadius;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final type = theme.typeScale;
    final valueSize = emphasis ? 36.0 : 28.0;
    return Semantics(
      container: true,
      label: '$label, $value, $caption',
      excludeSemantics: true,
      child: Material(
        color: color,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 132),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              theme.spacing.lg,
              theme.spacing.md + 2,
              theme.spacing.lg,
              theme.spacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: emphasis ? 40 : 36,
                      height: emphasis ? 40 : 36,
                      decoration: BoxDecoration(
                        color: foreground.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: emphasis ? 22 : 20,
                        color: foreground,
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.end,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: type.labelLarge.copyWith(
                          color: foreground.withValues(alpha: 0.88),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: theme.spacing.md),
                Text(
                  value,
                  style: type.headlineLarge.copyWith(
                    fontSize: valueSize,
                    height: 1.05,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                    color: foreground,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                SizedBox(height: theme.spacing.xs),
                Text(
                  caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: type.bodySmall.copyWith(
                    color: foreground.withValues(alpha: 0.72),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.caption,
    required this.count,
    required this.icon,
    required this.tone,
    required this.hasCount,
  });

  final String label;
  final String caption;
  final String count;
  final IconData icon;
  final _StatusTone tone;
  final bool hasCount;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final (Color accent, Color countColor) = switch ((tone, hasCount)) {
      (_StatusTone.error, true) => (scheme.error, scheme.error),
      (_StatusTone.active, true) => (scheme.primary, scheme.onSurface),
      (_StatusTone.neutral, true) => (
        scheme.onSurfaceVariant,
        scheme.onSurface,
      ),
      (_, false) => (
        scheme.onSurfaceVariant.withValues(alpha: 0.72),
        scheme.onSurfaceVariant,
      ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          SizedBox(width: theme.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.typeScale.titleMedium.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                SizedBox(height: theme.spacing.xs),
                Text(
                  caption,
                  style: theme.typeScale.bodyMedium.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: theme.spacing.sm),
          Text(
            count,
            style: theme.typeScale.titleLarge.copyWith(
              color: countColor,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
