import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_comic_filters_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_distinct_metadata_providers.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_series_filters_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_tab_filter_sort_providers.dart';
import 'package:hentai_library/features/library_browse/presentation/views/library_md3e/library_md3e_sort_section.dart';
import 'package:hentai_library/shared/di/library_dictionary_providers.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_age_restriction_filter.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_media_type_filter.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_metadata_filter_selection.dart';
import 'package:hentai_library/features/library_browse/domain/series/library_serialization_status_filter.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_tri_state_pick.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/author.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/value_objects/comic_language.dart';
import 'package:hentai_library/shared/ui/widgets/actions/ghost_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const Duration _kFilterAccordionDuration = Duration(milliseconds: 200);
const Curve _kFilterAccordionCurve = Curves.easeOutCubic;
const double _kFilterOptionRowHeight = 40;
const double _kFilterMetadataListHeight = 240;

typedef LibraryMetadataFilterToggle = Future<void> Function(String name);
typedef LibraryMetadataIncludeModeChanged = Future<void> Function(
  LibraryMetadataIncludeMode mode,
);

final libraryFilterTagNamesProvider = Provider<AsyncValue<List<String>>>((
  Ref ref,
) {
  return ref
      .watch(libraryTagDictionaryStateProvider)
      .whenData(
        (List<Tag> tags) =>
            tags.map((Tag tag) => tag.name).toList(growable: false),
      );
});

/// 作者筛选的候选值为作者 id（显示名由 [LibraryAuthorFilterGroup] 的 labelFor 解析）。
final libraryFilterAuthorNamesProvider = Provider<AsyncValue<List<String>>>((
  Ref ref,
) {
  return ref.watch(libraryAuthorDictionaryStateProvider).whenData((
    List<Author> authors,
  ) {
    final List<Author> sorted = List<Author>.of(authors)
      ..sort((Author a, Author b) => a.name.compareTo(b.name));
    return sorted
        .where((Author author) => author.id != null)
        .map((Author author) => '${author.id}')
        .toList();
  });
});

LibraryMetadataFilterSelection _includeOnlySelection(Set<String> names) {
  return LibraryMetadataFilterSelection(
    picks: <String, LibraryTriStatePick>{
      for (final String name in names) name: LibraryTriStatePick.include,
    },
  );
}

/// 库页筛选抽屉的「筛选」区（MD3E 生产实现，数据绑定 Riverpod）。
///
/// 漫画 Tab：年龄限制、媒体类型、标签、作者、语言、同人、角色、整理；
/// 系列 Tab：年龄限制、连载状态。分组与顺序与 Baseline 抽屉一致。
class Md3eLibraryFilterSection extends StatelessWidget {
  const Md3eLibraryFilterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Md3eAgeRestrictionFilterGroup(),
        _Md3eMediaTypeFilterGroup(),
        _Md3eSerializationStatusFilterGroup(),
        _Md3eTagFilterGroup(),
        _Md3eAuthorFilterGroup(),
        _Md3eLanguageFilterGroup(),
        _Md3eParodyFilterGroup(),
        _Md3eCharacterFilterGroup(),
        _Md3eOrganizeFilterGroup(),
      ],
    );
  }
}

class _Md3eAgeRestrictionFilterGroup extends ConsumerWidget {
  const _Md3eAgeRestrictionFilterGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryDisplayTargetProvider,
    );
    final LibraryAgeRestrictionFilter selected = ref.watch(
      libraryActiveAgeRestrictionFilterProvider,
    );
    final AppLocalizations l10n = context.l10n;
    return _Md3eFilterAccordion(
      title: l10n.libraryAgeRestrictionFilter,
      child: Column(
        children: <Widget>[
          for (final LibraryAgeRestrictionFilter option
              in LibraryAgeRestrictionFilter.selectableOptions)
            _Md3eCheckboxOptionRow(
              label: l10n.libraryAgeRestrictionFilterLabel(option),
              selected: selected == option,
              onTap: () {
                switch (displayTarget) {
                  case LibraryDisplayTarget.comics:
                    ref
                        .read(libraryComicFiltersProvider.notifier)
                        .toggleAgeRestrictionOption(option);
                  case LibraryDisplayTarget.series:
                    ref
                        .read(librarySeriesFiltersProvider.notifier)
                        .toggleAgeRestrictionOption(option);
                }
              },
            ),
        ],
      ),
    );
  }
}

class _Md3eMediaTypeFilterGroup extends ConsumerWidget {
  const _Md3eMediaTypeFilterGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryDisplayTargetProvider,
    );
    if (displayTarget != LibraryDisplayTarget.comics) {
      return const SizedBox.shrink();
    }
    final LibraryMediaTypeFilterSelection selected = ref.watch(
      libraryComicFiltersProvider.select(
        (AsyncValue<LibraryComicFiltersState> state) =>
            state.value?.mediaTypeFilter ??
            const LibraryMediaTypeFilterSelection(),
      ),
    );
    final AppLocalizations l10n = context.l10n;
    return _Md3eFilterAccordion(
      title: l10n.libraryMediaTypeFilter,
      child: Column(
        children: <Widget>[
          for (final LibraryMediaTypeFilterOption option
              in LibraryMediaTypeFilterOption.selectableOptions)
            _Md3eCheckboxOptionRow(
              label: l10n.libraryMediaTypeFilterLabel(option),
              selected: selected.selected.contains(option),
              onTap: () => ref
                  .read(libraryComicFiltersProvider.notifier)
                  .toggleMediaType(option),
            ),
        ],
      ),
    );
  }
}

class _Md3eSerializationStatusFilterGroup extends ConsumerWidget {
  const _Md3eSerializationStatusFilterGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryDisplayTargetProvider,
    );
    if (displayTarget != LibraryDisplayTarget.series) {
      return const SizedBox.shrink();
    }
    final LibrarySerializationStatusFilter selected = ref.watch(
      librarySeriesTabSerializationStatusFilterProvider,
    );
    final AppLocalizations l10n = context.l10n;
    return _Md3eFilterAccordion(
      title: l10n.librarySerializationStatusFilter,
      child: Column(
        children: <Widget>[
          for (final LibrarySerializationStatusFilter option
              in LibrarySerializationStatusFilter.selectableOptions)
            _Md3eCheckboxOptionRow(
              label: l10n.librarySerializationStatusFilterLabel(option),
              selected: selected == option,
              onTap: () => ref
                  .read(librarySeriesFiltersProvider.notifier)
                  .toggleSerializationStatusFilterOption(option),
            ),
        ],
      ),
    );
  }
}

class _Md3eTagFilterGroup extends ConsumerWidget {
  const _Md3eTagFilterGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryDisplayTargetProvider,
    );
    if (displayTarget != LibraryDisplayTarget.comics) {
      return const SizedBox.shrink();
    }
    final AsyncValue<List<String>> namesAsync = ref.watch(
      libraryFilterTagNamesProvider,
    );
    final LibraryMetadataFilterSelection selection = ref.watch(
      libraryComicFiltersProvider.select(
        (AsyncValue<LibraryComicFiltersState> state) =>
            state.value?.tagFilter ?? const LibraryMetadataFilterSelection(),
      ),
    );
    final List<String> names = namesAsync.value ?? const <String>[];
    final notifier = ref.read(libraryComicFiltersProvider.notifier);
    return _Md3eMetadataFilterGroup(
      title: context.l10n.libraryTagFilter,
      names: names,
      selection: selection,
      isLoading: namesAsync.isLoading && !namesAsync.hasValue,
      onToggle: notifier.toggleTag,
      onIncludeModeChanged: notifier.setTagIncludeMode,
    );
  }
}

class _Md3eAuthorFilterGroup extends ConsumerWidget {
  const _Md3eAuthorFilterGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryDisplayTargetProvider,
    );
    if (displayTarget != LibraryDisplayTarget.comics) {
      return const SizedBox.shrink();
    }
    final AsyncValue<List<String>> namesAsync = ref.watch(
      libraryFilterAuthorNamesProvider,
    );
    final LibraryMetadataFilterSelection selection = ref.watch(
      libraryComicFiltersProvider.select(
        (AsyncValue<LibraryComicFiltersState> state) =>
            state.value?.authorFilter ?? const LibraryMetadataFilterSelection(),
      ),
    );
    final List<String> names = namesAsync.value ?? const <String>[];
    final notifier = ref.read(libraryComicFiltersProvider.notifier);
    return _Md3eMetadataFilterGroup(
      title: context.l10n.libraryAuthorFilter,
      names: names,
      selection: selection,
      isLoading: namesAsync.isLoading && !namesAsync.hasValue,
      labelFor: (String id) {
        final List<Author> authors = ref
            .watch(libraryAuthorDictionaryStateProvider)
            .maybeWhen(
              data: (List<Author> value) => value,
              orElse: () => const <Author>[],
            );
        for (final Author author in authors) {
          if ('${author.id}' == id) {
            return author.name;
          }
        }
        return id;
      },
      onToggle: notifier.toggleAuthor,
      onIncludeModeChanged: notifier.setAuthorIncludeMode,
    );
  }
}

class _Md3eLanguageFilterGroup extends ConsumerWidget {
  const _Md3eLanguageFilterGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryDisplayTargetProvider,
    );
    if (displayTarget != LibraryDisplayTarget.comics) {
      return const SizedBox.shrink();
    }
    final Set<String> selected = ref.watch(
      libraryComicFiltersProvider.select(
        (AsyncValue<LibraryComicFiltersState> state) =>
            state.value?.languageFilter ?? const <String>{},
      ),
    );
    final notifier = ref.read(libraryComicFiltersProvider.notifier);
    return _Md3eMetadataFilterGroup(
      title: context.l10n.libraryLanguageFilter,
      names: ComicLanguageNames.closedSet,
      selection: _includeOnlySelection(selected),
      includeOnly: true,
      enablePinyinAssistedNameMatch: false,
      labelFor: context.l10n.comicLanguageLabel,
      onToggle: (String name) =>
          notifier.toggleIncludeSet(LibraryIncludeSetKind.language, name),
    );
  }
}

class _Md3eParodyFilterGroup extends ConsumerWidget {
  const _Md3eParodyFilterGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryDisplayTargetProvider,
    );
    if (displayTarget != LibraryDisplayTarget.comics) {
      return const SizedBox.shrink();
    }
    final AsyncValue<List<String>> parodiesAsync = ref.watch(
      libraryDistinctParodiesProvider,
    );
    final Set<String> selected = ref.watch(
      libraryComicFiltersProvider.select(
        (AsyncValue<LibraryComicFiltersState> state) =>
            state.value?.parodyFilter ?? const <String>{},
      ),
    );
    final List<String> names =
        (parodiesAsync.value ?? const <String>[]).toList()..sort();
    final notifier = ref.read(libraryComicFiltersProvider.notifier);
    return _Md3eMetadataFilterGroup(
      title: context.l10n.libraryParodyFilter,
      names: names,
      selection: _includeOnlySelection(selected),
      includeOnly: true,
      isLoading: parodiesAsync.isLoading && !parodiesAsync.hasValue,
      onToggle: (String name) =>
          notifier.toggleIncludeSet(LibraryIncludeSetKind.parody, name),
    );
  }
}

class _Md3eCharacterFilterGroup extends ConsumerWidget {
  const _Md3eCharacterFilterGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryDisplayTargetProvider,
    );
    if (displayTarget != LibraryDisplayTarget.comics) {
      return const SizedBox.shrink();
    }
    final AsyncValue<List<String>> charactersAsync = ref.watch(
      libraryDistinctCharactersProvider,
    );
    final Set<String> selected = ref.watch(
      libraryComicFiltersProvider.select(
        (AsyncValue<LibraryComicFiltersState> state) =>
            state.value?.characterFilter ?? const <String>{},
      ),
    );
    final List<String> names =
        (charactersAsync.value ?? const <String>[]).toList()..sort();
    final notifier = ref.read(libraryComicFiltersProvider.notifier);
    return _Md3eMetadataFilterGroup(
      title: context.l10n.libraryCharacterFilter,
      names: names,
      selection: _includeOnlySelection(selected),
      includeOnly: true,
      isLoading: charactersAsync.isLoading && !charactersAsync.hasValue,
      onToggle: (String name) =>
          notifier.toggleIncludeSet(LibraryIncludeSetKind.character, name),
    );
  }
}

class _Md3eOrganizeFilterGroup extends ConsumerWidget {
  const _Md3eOrganizeFilterGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryDisplayTargetProvider,
    );
    if (displayTarget != LibraryDisplayTarget.comics) {
      return const SizedBox.shrink();
    }
    final bool needsMetadataOnly = ref.watch(
      libraryComicFiltersProvider.select(
        (AsyncValue<LibraryComicFiltersState> state) =>
            state.value?.needsMetadataOnly ?? false,
      ),
    );
    final AppLocalizations l10n = context.l10n;
    return _Md3eFilterAccordion(
      title: l10n.libraryOrganizeFilter,
      child: _Md3eCheckboxOptionRow(
        label: l10n.libraryNeedsMetadataOnlyFilter,
        selected: needsMetadataOnly,
        onTap: () => ref
            .read(libraryComicFiltersProvider.notifier)
            .setNeedsMetadataOnly(!needsMetadataOnly),
      ),
    );
  }
}

/// 可折叠筛选分组：标题行 + chevron，展开时高度动画显示 [child]。
class _Md3eFilterAccordion extends StatefulWidget {
  const _Md3eFilterAccordion({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  State<_Md3eFilterAccordion> createState() => _Md3eFilterAccordionState();
}

class _Md3eFilterAccordionState extends State<_Md3eFilterAccordion> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
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
                    widget.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: _kFilterAccordionDuration,
                  curve: _kFilterAccordionCurve,
                  child: Icon(
                    LucideIcons.chevronDown,
                    size: 16,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: _kFilterAccordionDuration,
          curve: _kFilterAccordionCurve,
          alignment: Alignment.topCenter,
          child: _expanded ? widget.child : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// 单行选项：复选框 + 标签，整行可点击。
class _Md3eOptionRow extends StatelessWidget {
  const _Md3eOptionRow({
    required this.label,
    required this.checkbox,
    required this.onTap,
    this.height,
  });

  final String label;
  final Widget checkbox;
  final VoidCallback onTap;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Widget row = InkWell(
      onTap: onTap,
      hoverColor: theme.hoverColor,
      splashColor: theme.splashColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kLibraryMd3eSortSectionInset,
          vertical: 8,
        ),
        child: Row(
          children: <Widget>[
            SizedBox(width: 20, height: 20, child: checkbox),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          ],
        ),
      ),
    );
    return height == null ? row : SizedBox(height: height, child: row);
  }
}

class _Md3eCheckboxOptionRow extends StatelessWidget {
  const _Md3eCheckboxOptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Md3eOptionRow(
      label: label,
      onTap: onTap,
      checkbox: Checkbox(
        value: selected,
        onChanged: (_) => onTap(),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

/// 元数据筛选分组（标签 / 作者 / 语言 / 同人 / 角色）：可搜索列表 + 三态或仅包含复选。
class _Md3eMetadataFilterGroup extends StatefulWidget {
  const _Md3eMetadataFilterGroup({
    required this.title,
    required this.names,
    required this.selection,
    required this.onToggle,
    this.onIncludeModeChanged,
    this.isLoading = false,
    this.includeOnly = false,
    this.enablePinyinAssistedNameMatch = true,
    this.labelFor,
  });

  final String title;
  final List<String> names;
  final LibraryMetadataFilterSelection selection;
  final LibraryMetadataFilterToggle onToggle;
  final LibraryMetadataIncludeModeChanged? onIncludeModeChanged;
  final bool isLoading;
  final bool includeOnly;

  /// 语言等闭集筛选保持普通包含匹配（见 issue #87）。
  final bool enablePinyinAssistedNameMatch;
  final String Function(String name)? labelFor;

  @override
  State<_Md3eMetadataFilterGroup> createState() =>
      _Md3eMetadataFilterGroupState();
}

class _Md3eMetadataFilterGroupState extends State<_Md3eMetadataFilterGroup> {
  String _labelOf(String name) => widget.labelFor?.call(name) ?? name;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AppLocalizations l10n = context.l10n;
    final List<String> filteredNames = widget.names;

    return _Md3eFilterAccordion(
      title: widget.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (!widget.includeOnly && widget.onIncludeModeChanged != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                kLibraryMd3eSortSectionInset,
                8,
                kLibraryMd3eSortSectionInset,
                8,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: _IncludeModeIconButton(
                  mode: widget.selection.includeMode,
                  onChanged: widget.onIncludeModeChanged!,
                ),
              ),
            ),
          if (widget.isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (filteredNames.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                kLibraryMd3eSortSectionInset,
                0,
                kLibraryMd3eSortSectionInset,
                8,
              ),
              child: Text(
                l10n.libraryMetadataFilterEmpty,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            )
          else
            SizedBox(
              height: _kFilterMetadataListHeight,
              child: ListView.builder(
                itemExtent: _kFilterOptionRowHeight,
                itemCount: filteredNames.length,
                itemBuilder: (BuildContext context, int index) {
                  final String name = filteredNames[index];
                  final LibraryTriStatePick state = widget.selection
                      .pickStateFor(name);
                  return _Md3eOptionRow(
                    label: _labelOf(name),
                    height: _kFilterOptionRowHeight,
                    onTap: () => widget.onToggle(name),
                    checkbox: widget.includeOnly
                        ? Checkbox(
                            value: state == LibraryTriStatePick.include,
                            onChanged: (_) => widget.onToggle(name),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          )
                        : Checkbox(
                            value: state.checkboxValue,
                            tristate: true,
                            onChanged: (_) => widget.onToggle(name),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _IncludeModeIconButton extends StatelessWidget {
  const _IncludeModeIconButton({required this.mode, required this.onChanged});

  final LibraryMetadataIncludeMode mode;
  final LibraryMetadataIncludeModeChanged onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AppLocalizations l10n = context.l10n;
    final bool isAll = mode == LibraryMetadataIncludeMode.all;
    final String label = isAll
        ? l10n.libraryMetadataFilterIncludeAll
        : l10n.libraryMetadataFilterIncludeAny;
    return GhostButton.icon(
      icon: isAll ? LucideIcons.circleCheck : LucideIcons.circleDashed,
      tooltip: label,
      semanticLabel: label,
      iconSize: 16,
      size: 32,
      borderRadius: 8,
      foregroundColor: isAll ? cs.primary : cs.onSurfaceVariant,
      hoverColor: theme.hoverColor,
      overlayColor: theme.hoverColor,
      onPressed: () => onChanged(
        isAll ? LibraryMetadataIncludeMode.any : LibraryMetadataIncludeMode.all,
      ),
    );
  }
}
