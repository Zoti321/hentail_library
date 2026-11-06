import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_comic_filters_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_series_filters_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_tab_filter_sort_providers.dart';
import 'package:hentai_library/features/library_browse/presentation/integrations/comic_presentation_bridge.dart';
import 'package:hentai_library/features/library_browse/presentation/integrations/series_presentation_bridge.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 抽屉内容左缘内边距（与 Baseline 抽屉一致）。
const double kLibrarySortSectionInset = 16;

const double _kSortIconSlotWidth = 20;
const double _kSortIconLabelGap = 8;

/// 库页筛选排序抽屉中的「排序」区（MD3E 生产实现）。
///
/// 漫画 Tab：漫画排序字段；系列 Tab：系列排序字段。
/// 行为与 Baseline 一致：点击选中字段，再点切换升降序。
class LibrarySortSection extends ConsumerWidget {
  const LibrarySortSection({super.key});

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

class _ComicsSortSection extends StatelessWidget {
  const _ComicsSortSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final LibraryComicSortField field in LibraryComicSortField.values)
          _ComicSortRow(field: field),
      ],
    );
  }
}

class _SeriesSortSection extends StatelessWidget {
  const _SeriesSortSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final LibrarySeriesSortField field in kLibrarySeriesSortFields)
          _SeriesSortRow(field: field),
      ],
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
    final l10n = context.l10n;
    final Color labelColor = enabled
        ? cs.onSurfaceVariant
        : cs.onSurface.withValues(alpha: 0.38);
    return InkWell(
      onTap: enabled ? onTap : null,
      hoverColor: enabled ? theme.hoverColor : null,
      splashColor: enabled ? theme.splashColor : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kLibrarySortSectionInset,
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
    final LibraryComicSortOption sortOption = ref.watch(
      libraryActiveComicSortOptionProvider,
    );
    final bool implemented = field.isImplemented;
    return _SortRowShell(
      label: context.l10n.libraryComicSortFieldLabel(field),
      enabled: implemented,
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
