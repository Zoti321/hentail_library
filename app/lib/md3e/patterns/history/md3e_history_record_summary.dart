import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Body 顶部的记录总数与最长保留说明（[AppLocalizations.historyRecordSummary]）。
class Md3eHistoryRecordSummary extends StatelessWidget {
  const Md3eHistoryRecordSummary({
    super.key,
    required this.totalCount,
  });

  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;

    return Text(
      l10n.historyRecordSummary(totalCount),
      style: theme.typeScale.bodySmall.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
