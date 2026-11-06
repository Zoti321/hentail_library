import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/series/presentation/views/series_detail/series_detail_view_object.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 系列详情连载状态（MD3E 描边胶囊，非生产 [SeriesSerializationChip]）。
class SeriesDetailSerializationChip extends StatelessWidget {
  const SeriesDetailSerializationChip({super.key, required this.status});

  final SeriesSerializationStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == SeriesSerializationStatus.unknown) {
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

  static Color _accentColor(
    M3EColorScheme scheme,
    SeriesSerializationStatus status,
  ) {
    return switch (status) {
      SeriesSerializationStatus.ongoing => scheme.primary,
      SeriesSerializationStatus.ended => scheme.onSurfaceVariant,
      SeriesSerializationStatus.hiatus => scheme.error,
      SeriesSerializationStatus.unknown => scheme.onSurfaceVariant,
    };
  }

  static String _label(
    AppLocalizations l10n,
    SeriesSerializationStatus status,
  ) {
    return switch (status) {
      SeriesSerializationStatus.ongoing => l10n.serializationStatusOngoing,
      SeriesSerializationStatus.ended => l10n.serializationStatusEnded,
      SeriesSerializationStatus.hiatus => l10n.serializationStatusHiatus,
      SeriesSerializationStatus.unknown => l10n.serializationStatusUnknown,
    };
  }
}
