import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hentai_library/shared/ui/widgets/foundation/toggle_switch.dart';
import 'package:hentai_library/features/library_browse/domain/library_comic_grouping.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_comic_filters_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/views/library_page/widgets/library_filter_sort_drawer.dart';

/// Comics Tab：按系列分组开关（排序区顶部）；文案沿用 `libraryExpandBySeries`（接口层重构，UI 不变）。
class LibraryExpandBySeriesControls extends ConsumerWidget {
  const LibraryExpandBySeriesControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryDisplayTargetProvider,
    );
    if (displayTarget != LibraryDisplayTarget.comics) {
      return const SizedBox.shrink();
    }

    final ThemeData theme = Theme.of(context);
    final AppThemeTokens tokens = context.tokens;
    final AppLocalizations l10n = context.l10n;
    final bool enabled = ref.watch(
      libraryComicFiltersProvider.select(
        (AsyncValue<LibraryComicFiltersState> state) =>
            state.value?.grouping == LibraryComicGrouping.bySeries,
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ref
              .read(libraryComicFiltersProvider.notifier)
              .setGrouping(
                enabled
                    ? LibraryComicGrouping.none
                    : LibraryComicGrouping.bySeries,
              );
        },
        hoverColor: theme.hoverColor,
        splashColor: theme.splashColor,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            kLibraryFilterSortDrawerContentInset,
            10,
            kLibraryFilterSortDrawerContentInset,
            10,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l10n.libraryExpandBySeries,
                  style: TextStyle(
                    fontSize: tokens.text.bodySm,
                    fontWeight: FontWeight.w500,
                    color: context.hentai.textPrimary,
                  ),
                ),
              ),
              IgnorePointer(child: ToggleSwitch(checked: enabled)),
            ],
          ),
        ),
      ),
    );
  }
}
