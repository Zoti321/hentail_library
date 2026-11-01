import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 详情摘要区年龄限制标记（Lab MD3E 风，非生产 [R18RatingChip]）。
class Md3eComicDetailAgeRestrictionChip extends StatelessWidget {
  const Md3eComicDetailAgeRestrictionChip({super.key});

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ETypeScale type = theme.typeScale;
    final M3ESpacing spacing = theme.spacing;

    final Color foreground = scheme.onErrorContainer;
    final TextStyle labelStyle = type.labelSmall.copyWith(
      fontWeight: FontWeight.w600,
      color: foreground,
      height: 1.1,
      letterSpacing: 0.2,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(spacing.xs),
        border: Border.all(
          color: scheme.error.withValues(alpha: 0.28),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.sm,
          vertical: spacing.xs - 1,
        ),
        child: Text('R18', style: labelStyle),
      ),
    );
  }
}
