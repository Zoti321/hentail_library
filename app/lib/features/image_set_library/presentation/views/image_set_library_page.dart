import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Image set 库浏览占位（#585 前）：不展示 Comic 目录。
class ImageSetLibraryPage extends StatelessWidget {
  const ImageSetLibraryPage({super.key, required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final double horizontalInset = PageLayoutSpec.of(context).horizontalInset;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalInset,
        vertical: theme.spacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            displayName,
            style: theme.typeScale.titleLarge.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: theme.spacing.md),
          Text(
            l10n.imageSetLibraryPlaceholder,
            style: theme.typeScale.bodyMedium.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
