import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/pages/md3e_series_detail_entry.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 系列详情连载状态（MD3E 描边胶囊，非生产 [SeriesSerializationChip]）。
class Md3eSeriesDetailSerializationChip extends StatelessWidget {
  const Md3eSeriesDetailSerializationChip({
    super.key,
    required this.status,
  });

  final Md3eSeriesSerializationStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == Md3eSeriesSerializationStatus.unknown) {
      return const SizedBox.shrink();
    }
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ESpacing spacing = theme.spacing;
    final Color accent = _accentColor(scheme, status);
    final String label = _label(l10n, status);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(spacing.xs),
        border: Border.all(color: accent.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.sm,
          vertical: spacing.xs - 1,
        ),
        child: Text(
          label,
          style: theme.typeScale.labelSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: accent,
            height: 1.1,
          ),
        ),
      ),
    );
  }

  static Color _accentColor(M3EColorScheme scheme, Md3eSeriesSerializationStatus status) {
    return switch (status) {
      Md3eSeriesSerializationStatus.ongoing => scheme.primary,
      Md3eSeriesSerializationStatus.ended => scheme.onSurfaceVariant,
      Md3eSeriesSerializationStatus.hiatus => scheme.error,
      Md3eSeriesSerializationStatus.unknown => scheme.onSurfaceVariant,
    };
  }

  static String _label(AppLocalizations l10n, Md3eSeriesSerializationStatus status) {
    return switch (status) {
      Md3eSeriesSerializationStatus.ongoing => l10n.serializationStatusOngoing,
      Md3eSeriesSerializationStatus.ended => l10n.serializationStatusEnded,
      Md3eSeriesSerializationStatus.hiatus => l10n.serializationStatusHiatus,
      Md3eSeriesSerializationStatus.unknown => l10n.serializationStatusUnknown,
    };
  }
}
