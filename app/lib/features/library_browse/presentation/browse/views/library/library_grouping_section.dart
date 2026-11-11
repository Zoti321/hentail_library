import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_comic_filters_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_series_filters_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/views/library/library_sort_section.dart';
import 'package:hentai_library/features/comic/public.dart';
import 'package:hentai_library/features/series/public.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';

/// 库页筛选排序抽屉中的「分组」区（MD3E 生产实现）。
///
/// 漫画 Tab：不分组 / 按系列分组（单选）；系列 Tab：不分组 / 按连载状态分组（单选）。
class LibraryGroupingSection extends ConsumerWidget {
  const LibraryGroupingSection({super.key});

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
    final LibraryComicGrouping selected = ref.watch(
      libraryComicFiltersProvider.select(
        (AsyncValue<LibraryComicFiltersState> state) =>
            state.value?.grouping ?? LibraryComicGrouping.defaultValue,
      ),
    );
    final notifier = ref.read(libraryComicFiltersProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _GroupingRadioRow(
          label: context.l10n.libraryGroupNone,
          selected: selected == LibraryComicGrouping.none,
          onSelected: () => notifier.setGrouping(LibraryComicGrouping.none),
        ),
        _GroupingRadioRow(
          label: context.l10n.libraryGroupBySeries,
          selected: selected == LibraryComicGrouping.bySeries,
          onSelected: () => notifier.setGrouping(LibraryComicGrouping.bySeries),
        ),
      ],
    );
  }
}

class _SeriesGroupingSection extends ConsumerWidget {
  const _SeriesGroupingSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibrarySeriesGrouping selected = ref.watch(
      librarySeriesTabGroupingProvider,
    );
    final notifier = ref.read(librarySeriesFiltersProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _GroupingRadioRow(
          label: context.l10n.libraryGroupNone,
          selected: selected == LibrarySeriesGrouping.none,
          onSelected: () => notifier.setGrouping(LibrarySeriesGrouping.none),
        ),
        _GroupingRadioRow(
          label: context.l10n.libraryGroupBySerializationStatus,
          selected: selected == LibrarySeriesGrouping.bySerializationStatus,
          onSelected: () =>
              notifier.setGrouping(LibrarySeriesGrouping.bySerializationStatus),
        ),
      ],
    );
  }
}

class _GroupingRadioRow extends StatelessWidget {
  const _GroupingRadioRow({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return InkWell(
      onTap: onSelected,
      hoverColor: theme.hoverColor,
      splashColor: theme.splashColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kLibrarySortSectionInset,
          vertical: 8,
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 24,
              height: 24,
              child: Radio<bool>(
                value: true,
                groupValue: selected,
                onChanged: (_) => onSelected(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          ],
        ),
      ),
    );
  }
}
