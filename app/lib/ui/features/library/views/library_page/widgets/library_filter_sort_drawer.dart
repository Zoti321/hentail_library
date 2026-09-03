import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/ui/features/library/view_models/library_comics_filter_reset_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_series_filter_reset_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_filter_sort_providers.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_filter_controls.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_metadata_filter_section.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_layout_constants.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_sort_controls.dart';

/// 抽屉分区标题等内容相对左缘的内边距。
const double kLibraryFilterSortDrawerContentInset = 16;

class LibraryFilterSortDrawer extends ConsumerWidget {
  const LibraryFilterSortDrawer({super.key});

  static double widthFor(BuildContext context) {
    return libraryFilterSortDrawerWidthForViewport(
      MediaQuery.sizeOf(context).width,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final AppLocalizations l10n = context.l10n;
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryDisplayTargetProvider,
    );
    final bool isCustomized = ref.watch(
      libraryActiveFilterSortIsCustomizedProvider,
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
                padding: const EdgeInsets.fromLTRB(
                  kLibraryFilterSortDrawerContentInset,
                  0,
                  kLibraryFilterSortDrawerContentInset,
                  0,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        l10n.libraryFilterSection,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.hentai.textSecondary,
                        ),
                      ),
                    ),
                    if (isCustomized)
                      TextButton(
                        onPressed: () {
                          switch (displayTarget) {
                            case LibraryDisplayTarget.comics:
                              ref
                                  .read(
                                    libraryComicsFilterResetProvider.notifier,
                                  )
                                  .resetAll();
                            case LibraryDisplayTarget.series:
                              ref
                                  .read(
                                    librarySeriesFilterResetProvider.notifier,
                                  )
                                  .resetAll();
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          l10n.libraryResetAllFilters,
                          style: TextStyle(fontSize: 12, color: cs.primary),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: tokens.spacing.sm),
              const LibraryFilterControls(),
              const LibraryMediaTypeFilterControls(),
              const LibrarySerializationStatusFilterControls(),
              const LibraryLanguageFilterControls(),
              const LibraryParodyFilterControls(),
              const LibraryCharacterFilterControls(),
              const LibraryTagFilterControls(),
              const LibraryAuthorFilterControls(),
              SizedBox(height: tokens.spacing.lg),
              Padding(
                padding: const EdgeInsets.only(
                  left: kLibraryFilterSortDrawerContentInset,
                ),
                child: Text(
                  l10n.librarySortSection,
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
