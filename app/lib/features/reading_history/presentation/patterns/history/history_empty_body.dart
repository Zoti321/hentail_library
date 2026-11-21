import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 阅读历史页无记录时的正文占位。
class HistoryEmptyBody extends StatelessWidget {
  const HistoryEmptyBody({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final String? custom = message?.trim();
    final String title = (custom != null && custom.isNotEmpty)
        ? custom
        : context.l10n.historyEmpty;

    return Padding(
      padding: EdgeInsets.only(
        top: PageLayoutSpec.of(context).stateTopInset,
        bottom: theme.spacing.xl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Symbols.history, size: 48, color: scheme.outline),
              SizedBox(height: theme.spacing.sm),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.typeScale.titleMedium.copyWith(
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
