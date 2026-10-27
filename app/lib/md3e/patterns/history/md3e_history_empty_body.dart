import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 阅读历史页无记录时的正文占位。
class Md3eHistoryEmptyBody extends StatelessWidget {
  const Md3eHistoryEmptyBody({super.key});

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: theme.spacing.xl),
      child: Center(
        child: Text(
          context.l10n.historyEmpty,
          style: theme.typeScale.bodyMedium.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
