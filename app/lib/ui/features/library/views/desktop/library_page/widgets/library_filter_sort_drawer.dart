import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/library/views/desktop/library_page/widgets/library_filter_controls.dart';
import 'package:hentai_library/ui/features/library/views/desktop/library_page/widgets/library_sort_controls.dart';

/// 抽屉分区标题等内容相对左缘的内边距。
const double kLibraryFilterSortDrawerContentInset = 16;

class LibraryFilterSortDrawer extends StatelessWidget {
  const LibraryFilterSortDrawer({super.key});

  static double widthFor(BuildContext context) {
    return math.min(360, MediaQuery.sizeOf(context).width * 0.3);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return Drawer(
      width: widthFor(context),
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(
                  left: kLibraryFilterSortDrawerContentInset,
                ),
                child: Text(
                  '筛选',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.hentai.textSecondary,
                  ),
                ),
              ),
              SizedBox(height: tokens.spacing.sm),
              const LibraryFilterControls(),
              SizedBox(height: tokens.spacing.lg),
              Padding(
                padding: const EdgeInsets.only(
                  left: kLibraryFilterSortDrawerContentInset,
                ),
                child: Text(
                  '排序',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.hentai.textSecondary,
                  ),
                ),
              ),
              SizedBox(height: tokens.spacing.sm),
              const LibrarySortControls(),
            ],
          ),
        ),
      ),
    );
  }
}
