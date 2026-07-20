import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/domain/library/library_media_type_filter.dart';
import 'package:hentai_library/domain/library/library_serialization_status_filter.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/library/view_models/library_age_restriction_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/ui/features/library/view_models/library_media_type_filter_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_serialization_status_filter_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_filter_sort_providers.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_filter_accordion.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_filter_sort_drawer.dart';

/// 库页抽屉筛选控件（年龄限制手风琴）。
class LibraryFilterControls extends ConsumerStatefulWidget {
  const LibraryFilterControls({super.key});

  @override
  ConsumerState<LibraryFilterControls> createState() =>
      _LibraryFilterControlsState();
}

class _LibraryFilterControlsState extends ConsumerState<LibraryFilterControls> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryDisplayTargetProvider,
    );
    final LibraryAgeRestrictionFilter selected = ref.watch(
      libraryActiveAgeRestrictionFilterProvider,
    );
    final AppLocalizations l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
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
                      l10n.libraryAgeRestrictionFilter,
                      style: TextStyle(
                        fontSize: tokens.text.bodySm,
                        fontWeight: FontWeight.w500,
                        color: cs.hentai.textPrimary,
                      ),
                    ),
                  ),
                  LibraryFilterAccordionChevron(expanded: _expanded),
                ],
              ),
            ),
          ),
        ),
        LibraryFilterAccordionBody(
          expanded: _expanded,
          child: Column(
            children: LibraryAgeRestrictionFilter.selectableOptions
                .map(
                  (LibraryAgeRestrictionFilter option) =>
                      _FilterCheckboxOptionRow(
                        label: l10n.libraryAgeRestrictionFilterLabel(option),
                        selected: selected == option,
                        onTap: () {
                          ref
                              .read(
                                libraryAgeRestrictionFilterProvider.notifier,
                              )
                              .toggleFilterOption(displayTarget, option);
                        },
                      ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

/// 库页抽屉筛选控件（漫画 Tab 媒体类型手风琴）。
class LibraryMediaTypeFilterControls extends ConsumerStatefulWidget {
  const LibraryMediaTypeFilterControls({super.key});

  @override
  ConsumerState<LibraryMediaTypeFilterControls> createState() =>
      _LibraryMediaTypeFilterControlsState();
}

class _LibraryMediaTypeFilterControlsState
    extends ConsumerState<LibraryMediaTypeFilterControls> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryDisplayTargetProvider,
    );
    if (displayTarget != LibraryDisplayTarget.comics) {
      return const SizedBox.shrink();
    }

    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final LibraryMediaTypeFilterSelection selected = ref.watch(
      libraryComicsTabMediaTypeFilterProvider,
    );

    final AppLocalizations l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
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
                      l10n.libraryMediaTypeFilter,
                      style: TextStyle(
                        fontSize: tokens.text.bodySm,
                        fontWeight: FontWeight.w500,
                        color: cs.hentai.textPrimary,
                      ),
                    ),
                  ),
                  LibraryFilterAccordionChevron(expanded: _expanded),
                ],
              ),
            ),
          ),
        ),
        LibraryFilterAccordionBody(
          expanded: _expanded,
          child: Column(
            children: LibraryMediaTypeFilterOption.selectableOptions
                .map(
                  (LibraryMediaTypeFilterOption option) =>
                      _FilterCheckboxOptionRow(
                        label: l10n.libraryMediaTypeFilterLabel(option),
                        selected: selected.selected.contains(option),
                        onTap: () {
                          ref
                              .read(libraryMediaTypeFilterProvider.notifier)
                              .toggleOption(option);
                        },
                      ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

/// 库页抽屉筛选控件（系列 Tab 连载状态手风琴）。
class LibrarySerializationStatusFilterControls extends ConsumerStatefulWidget {
  const LibrarySerializationStatusFilterControls({super.key});

  @override
  ConsumerState<LibrarySerializationStatusFilterControls> createState() =>
      _LibrarySerializationStatusFilterControlsState();
}

class _LibrarySerializationStatusFilterControlsState
    extends ConsumerState<LibrarySerializationStatusFilterControls> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryDisplayTargetProvider,
    );
    if (displayTarget != LibraryDisplayTarget.series) {
      return const SizedBox.shrink();
    }

    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final LibrarySerializationStatusFilter selected = ref.watch(
      librarySeriesTabSerializationStatusFilterProvider,
    );

    final AppLocalizations l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
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
                      l10n.librarySerializationStatusFilter,
                      style: TextStyle(
                        fontSize: tokens.text.bodySm,
                        fontWeight: FontWeight.w500,
                        color: cs.hentai.textPrimary,
                      ),
                    ),
                  ),
                  LibraryFilterAccordionChevron(expanded: _expanded),
                ],
              ),
            ),
          ),
        ),
        LibraryFilterAccordionBody(
          expanded: _expanded,
          child: Column(
            children: LibrarySerializationStatusFilter.selectableOptions
                .map(
                  (LibrarySerializationStatusFilter option) =>
                      _FilterCheckboxOptionRow(
                        label: l10n.librarySerializationStatusFilterLabel(
                          option,
                        ),
                        selected: selected == option,
                        onTap: () {
                          ref
                              .read(
                                librarySerializationStatusFilterProvider
                                    .notifier,
                              )
                              .toggleFilterOption(option);
                        },
                      ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _FilterCheckboxOptionRow extends StatelessWidget {
  const _FilterCheckboxOptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: theme.hoverColor,
        splashColor: theme.splashColor,
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
                width: 20,
                height: 20,
                child: Checkbox(
                  value: selected,
                  onChanged: (_) => onTap(),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 13, color: cs.hentai.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
