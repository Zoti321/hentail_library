import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 阅读历史页无记录时的正文占位。
class HistoryEmptyBody extends StatelessWidget {
  const HistoryEmptyBody({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: theme.spacing.xl),
      child: Center(
        child: Text(
          message ?? context.l10n.historyEmpty,
          style: theme.typeScale.bodyMedium.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
