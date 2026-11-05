import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_comic_filters_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_series_filters_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_tab_filter_sort_providers.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/views/library_md3e/library_md3e_sort_section.dart';
import 'package:hentai_library/features/library_browse/presentation/integrations/comic_presentation_bridge.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';

/// 库页筛选排序抽屉中的「分组」区（MD3E 生产实现）。
///
/// 漫画 Tab：按系列分组开关；系列 Tab：优先根系列开关。
class Md3eLibraryGroupingSection extends ConsumerWidget {
  const Md3eLibraryGroupingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryDisplayTargetProvider,
    );
    return switch (displayTarget) {
      LibraryDisplayTarget.comics => const _ComicsGroupingSection(),
      LibraryDisplayTarget.series => const _SeriesGroupingSection(),
    };
  }
}

class _ComicsGroupingSection extends ConsumerWidget {
  const _ComicsGroupingSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool bySeries = ref.watch(
      libraryComicFiltersProvider.select(
        (AsyncValue<LibraryComicFiltersState> state) =>
            state.value?.grouping == LibraryComicGrouping.bySeries,
      ),
    );
    return _GroupingToggleRow(
      label: context.l10n.libraryGroupBySeries,
      value: bySeries,
      onChanged: (bool value) {
        ref
            .read(libraryComicFiltersProvider.notifier)
            .setGrouping(
              value ? LibraryComicGrouping.bySeries : LibraryComicGrouping.none,
            );
      },
    );
  }
}

class _SeriesGroupingSection extends ConsumerWidget {
  const _SeriesGroupingSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool preferRootSeries = ref.watch(
      librarySeriesTabPreferLibraryRootSeriesProvider,
    );
    return _GroupingToggleRow(
      label: context.l10n.libraryPreferLibraryRootSeries,
      value: preferRootSeries,
      onChanged: (bool value) {
        ref
            .read(librarySeriesFiltersProvider.notifier)
            .setPreferLibraryRootSeries(value);
      },
    );
  }
}

class _GroupingToggleRow extends StatelessWidget {
  const _GroupingToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return InkWell(
      onTap: () => onChanged(!value),
      hoverColor: theme.hoverColor,
      splashColor: theme.splashColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kLibraryMd3eSortSectionInset,
          vertical: 10,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
