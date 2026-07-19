import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/library/library_comic_sort_option.dart';
import 'package:hentai_library/domain/library/library_series_sort_option.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_filter_sort_providers.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_sort_notifier.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_filter_sort_drawer.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const double kLibrarySortIconSlotWidth = 20;
const double kLibrarySortIconLabelGap = 8;

/// 库页排序列表行控件，供抽屉复用。
class LibrarySortControls extends ConsumerWidget {
  const LibrarySortControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryDisplayTargetProvider,
    );
    return switch (displayTarget) {
      LibraryDisplayTarget.comics => const _ComicsSortControls(),
      LibraryDisplayTarget.series => const _SeriesSortControls(),
    };
  }
}

class _ComicsSortControls extends ConsumerWidget {
  const _ComicsSortControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: LibraryComicSortField.values
          .map((LibraryComicSortField field) => _ComicSortListRow(field: field))
          .toList(),
    );
  }
}

class _SeriesSortControls extends ConsumerWidget {
  const _SeriesSortControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: kLibrarySeriesSortFields
          .map(
            (LibrarySeriesSortField field) => _SeriesSortListRow(field: field),
          )
          .toList(),
    );
  }
}

class _ComicSortListRow extends ConsumerWidget {
  const _ComicSortListRow({required this.field});

  final LibraryComicSortField field;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final LibraryComicSortOption sortOption = ref.watch(
      libraryActiveComicSortOptionProvider,
    );
    final bool isSelected = sortOption.field == field;
    final bool isImplemented = field.isImplemented;
    final bool isAscending = !sortOption.descending;
    final AppLocalizations l10n = context.l10n;
    final TextStyle labelStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: isImplemented ? cs.hentai.textSecondary : cs.hentai.textTertiary,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isImplemented
            ? () {
                ref
                    .read(libraryTabSortProvider.notifier)
                    .setComicSortField(field);
              }
            : null,
        hoverColor: isImplemented ? theme.hoverColor : null,
        splashColor: isImplemented ? theme.splashColor : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            kLibraryFilterSortDrawerContentInset,
            8,
            kLibraryFilterSortDrawerContentInset,
            8,
          ),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: kLibrarySortIconSlotWidth,
                child: isSelected
                    ? Icon(
                        isAscending
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronDown,
                        size: 14,
                        color: cs.primary,
                      )
                    : null,
              ),
              const SizedBox(width: kLibrarySortIconLabelGap),
              Expanded(
                child: Text(l10n.libraryComicSortFieldLabel(field), style: labelStyle),
              ),
              if (!isImplemented)
                Text(
                  l10n.libraryComingSoon,
                  style: TextStyle(fontSize: 11, color: cs.hentai.textTertiary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeriesSortListRow extends ConsumerWidget {
  const _SeriesSortListRow({required this.field});

  final LibrarySeriesSortField field;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final LibrarySeriesSortOption sortOption = ref.watch(
      libraryActiveSeriesSortOptionProvider,
    );
    final bool isSelected = sortOption.field == field;
    final bool isImplemented = field.isImplemented;
    final bool isAscending = !sortOption.descending;
    final AppLocalizations l10n = context.l10n;
    final TextStyle labelStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: isImplemented ? cs.hentai.textSecondary : cs.hentai.textTertiary,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isImplemented
            ? () {
                ref
                    .read(libraryTabSortProvider.notifier)
                    .setSeriesSortField(field);
              }
            : null,
        hoverColor: isImplemented ? theme.hoverColor : null,
        splashColor: isImplemented ? theme.splashColor : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            kLibraryFilterSortDrawerContentInset,
            8,
            kLibraryFilterSortDrawerContentInset,
            8,
          ),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: kLibrarySortIconSlotWidth,
                child: isSelected
                    ? Icon(
                        isAscending
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronDown,
                        size: 14,
                        color: cs.primary,
                      )
                    : null,
              ),
              const SizedBox(width: kLibrarySortIconLabelGap),
              Expanded(
                child: Text(l10n.librarySeriesSortFieldLabel(field), style: labelStyle),
              ),
              if (!isImplemented)
                Text(
                  l10n.libraryComingSoon,
                  style: TextStyle(fontSize: 11, color: cs.hentai.textTertiary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
