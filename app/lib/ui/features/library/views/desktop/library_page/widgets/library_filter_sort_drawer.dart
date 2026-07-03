import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/features/library/views/desktop/library_page/widgets/library_sort_controls.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LibraryFilterSortDrawer extends StatelessWidget {
  const LibraryFilterSortDrawer({super.key});

  static double widthFor(BuildContext context) {
    return math.min(360, MediaQuery.sizeOf(context).width * 0.3);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return Drawer(
      width: widthFor(context),
      backgroundColor: cs.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '筛选与排序',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: cs.hentai.textPrimary,
                      ),
                    ),
                  ),
                  GhostButton.icon(
                    icon: LucideIcons.x,
                    tooltip: '关闭',
                    semanticLabel: '关闭',
                    iconSize: 16,
                    size: 32,
                    borderRadius: 8,
                    foregroundColor: cs.hentai.iconDefault,
                    hoverColor: theme.hoverColor,
                    overlayColor: theme.hoverColor,
                    delayTooltipThreeSeconds: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: cs.hentai.borderSubtle),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '筛选',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.hentai.textSecondary,
                      ),
                    ),
                    SizedBox(height: tokens.spacing.sm),
                    Text(
                      '高级筛选（标签、类型、内容分级等）将在后续版本提供。',
                      style: TextStyle(
                        fontSize: tokens.text.bodySm,
                        height: 1.5,
                        color: cs.hentai.textTertiary,
                      ),
                    ),
                    SizedBox(height: tokens.spacing.lg),
                    Divider(height: 1, color: cs.hentai.borderSubtle),
                    SizedBox(height: tokens.spacing.lg),
                    Text(
                      '排序',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.hentai.textSecondary,
                      ),
                    ),
                    SizedBox(height: tokens.spacing.md),
                    const LibrarySortControls(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
