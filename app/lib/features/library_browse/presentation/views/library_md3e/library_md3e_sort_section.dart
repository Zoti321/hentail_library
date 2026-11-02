import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_comic_grouping.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_comic_filters_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_series_filters_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_tab_filter_sort_providers.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_comic_sort_option.dart';
import 'package:hentai_library/features/library_browse/domain/series/library_series_sort_option.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 抽屉内容左缘内边距（与 Baseline 抽屉一致）。
const double kLibraryMd3eSortSectionInset = 16;

const double _kSortIconSlotWidth = 20;
const double _kSortIconLabelGap = 8;

/// 库页筛选排序抽屉中的「排序」区（MD3E 生产实现）。
///
/// 漫画 Tab：顶部「按系列分组」开关 + 漫画排序字段；
/// 系列 Tab：「优先根系列」开关 + 系列排序字段。
/// 行为与 Baseline 一致：点击选中字段，再点切换升降序；分组开启时漫画排序禁用。
class Md3eLibrarySortSection extends ConsumerWidget {
  const Md3eLibrarySortSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryDisplayTargetProvider,
    );
    return switch (displayTarget) {
      LibraryDisplayTarget.comics => const _ComicsSortSection(),
      LibraryDisplayTarget.series => const _SeriesSortSection(),
    };
  }
}

class _ComicsSortSection extends ConsumerWidget {
  const _ComicsSortSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool bySeries = ref.watch(
      libraryComicFiltersProvider.select(
        (AsyncValue<LibraryComicFiltersState> state) =>
            state.value?.grouping == LibraryComicGrouping.bySeries,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _ToggleRow(
          label: context.l10n.libraryExpandBySeries,
          value: bySeries,
          onChanged: (bool value) {
            ref
                .read(libraryComicFiltersProvider.notifier)
                .setGrouping(
                  value
                      ? LibraryComicGrouping.bySeries
                      : LibraryComicGrouping.none,
                );
          },
        ),
        for (final LibraryComicSortField field in LibraryComicSortField.values)
          _ComicSortRow(field: field),
      ],
    );
  }
}

class _SeriesSortSection extends ConsumerWidget {
  const _SeriesSortSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool preferRootSeries = ref.watch(
      librarySeriesTabPreferLibraryRootSeriesProvider,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _ToggleRow(
          label: context.l10n.libraryPreferLibraryRootSeries,
          value: preferRootSeries,
          onChanged: (bool value) {
            ref
                .read(librarySeriesFiltersProvider.notifier)
                .setPreferLibraryRootSeries(value);
          },
        ),
        for (final LibrarySeriesSortField field in kLibrarySeriesSortFields)
          _SeriesSortRow(field: field),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
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

class _SortRowShell extends StatelessWidget {
  const _SortRowShell({
    required this.label,
    required this.enabled,
    required this.isSelected,
    required this.isAscending,
    required this.comingSoon,
    this.onTap,
  });

  final String label;
  final bool enabled;
  final bool isSelected;
  final bool isAscending;
  final bool comingSoon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AppLocalizations l10n = context.l10n;
    final Color labelColor = enabled
        ? cs.onSurfaceVariant
        : cs.onSurface.withValues(alpha: 0.38);
    return InkWell(
      onTap: enabled ? onTap : null,
      hoverColor: enabled ? theme.hoverColor : null,
      splashColor: enabled ? theme.splashColor : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kLibraryMd3eSortSectionInset,
          vertical: 8,
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: _kSortIconSlotWidth,
              child: isSelected
                  ? Icon(
                      isAscending
                          ? LucideIcons.chevronUp
                          : LucideIcons.chevronDown,
                      size: 14,
                      color: enabled ? cs.primary : labelColor,
                    )
                  : null,
            ),
            const SizedBox(width: _kSortIconLabelGap),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(color: labelColor),
              ),
            ),
            if (comingSoon)
              Text(
                l10n.libraryComingSoon,
                style: theme.textTheme.labelSmall?.copyWith(color: labelColor),
              ),
          ],
        ),
      ),
    );
  }
}

class _ComicSortRow extends ConsumerWidget {
  const _ComicSortRow({required this.field});

  final LibraryComicSortField field;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool groupingOverridesSort = ref.watch(
      libraryComicFiltersProvider.select(
        (AsyncValue<LibraryComicFiltersState> state) =>
            state.value?.grouping.overridesSort ?? false,
      ),
    );
    final LibraryComicSortOption sortOption = ref.watch(
      libraryActiveComicSortOptionProvider,
    );
    final bool implemented = field.isImplemented;
    return _SortRowShell(
      label: context.l10n.libraryComicSortFieldLabel(field),
      enabled: implemented && !groupingOverridesSort,
      isSelected: sortOption.field == field,
      isAscending: !sortOption.descending,
      comingSoon: !implemented,
      onTap: () {
        ref.read(libraryComicFiltersProvider.notifier).setSortField(field);
      },
    );
  }
}

class _SeriesSortRow extends ConsumerWidget {
  const _SeriesSortRow({required this.field});

  final LibrarySeriesSortField field;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibrarySeriesSortOption sortOption = ref.watch(
      libraryActiveSeriesSortOptionProvider,
    );
    final bool implemented = field.isImplemented;
    return _SortRowShell(
      label: context.l10n.librarySeriesSortFieldLabel(field),
      enabled: implemented,
      isSelected: sortOption.field == field,
      isAscending: !sortOption.descending,
      comingSoon: !implemented,
      onTap: () {
        ref.read(librarySeriesFiltersProvider.notifier).setSortField(field);
      },
    );
  }
}
