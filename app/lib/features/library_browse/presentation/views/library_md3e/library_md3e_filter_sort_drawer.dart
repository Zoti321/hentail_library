import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_page_facade_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/views/library_md3e/library_md3e_filter_section.dart';
import 'package:hentai_library/features/library_browse/presentation/views/library_md3e/library_md3e_sort_section.dart';
import 'package:hentai_library/features/library_browse/presentation/views/library_page/widgets/library_layout_constants.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';

/// 库页筛选排序抽屉（MD3E 生产实现）：筛选区 + 排序区。
class Md3eLibraryFilterSortDrawer extends ConsumerWidget {
  const Md3eLibraryFilterSortDrawer({super.key});

  static double widthFor(BuildContext context) {
    return libraryFilterSortDrawerWidthForViewport(
      MediaQuery.sizeOf(context).width,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final bool isCustomized = ref.watch(
      libraryPageFacadeProvider.select(
        (LibraryPageFacadeState state) => state.isFilterSortCustomized,
      ),
    );
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
                padding: const EdgeInsets.symmetric(
                  horizontal: kLibraryMd3eSortSectionInset,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        context.l10n.libraryFilterSection,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (isCustomized)
                      TextButton(
                        onPressed: () => ref
                            .read(libraryPageFacadeProvider.notifier)
                            .resetFilters(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          context.l10n.libraryResetAllFilters,
                          style: TextStyle(fontSize: 12, color: cs.primary),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: tokens.spacing.sm),
              const Md3eLibraryFilterSection(),
              SizedBox(height: tokens.spacing.lg),
              Padding(
                padding: const EdgeInsets.only(
                  left: kLibraryMd3eSortSectionInset,
                ),
                child: Text(
                  context.l10n.librarySortSection,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(height: tokens.spacing.sm),
              const Md3eLibrarySortSection(),
            ],
          ),
        ),
      ),
    );
  }
}
