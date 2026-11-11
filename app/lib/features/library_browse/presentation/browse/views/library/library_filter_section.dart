import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_comic_filters_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_filter_metadata_names_providers.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_series_filters_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_tab_filter_sort_providers.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/views/library/library_sort_section.dart';
import 'package:hentai_library/features/series/public.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_age_restriction_filter.dart';
import 'package:hentai_library/shared/domain/library/library_tri_state_pick.dart';
import 'package:hentai_library/shared/di/library_dictionary_providers.dart';
import 'package:hentai_library/shared/domain/library/library_media_type_filter.dart';
import 'package:hentai_library/shared/domain/library/library_metadata_filter_selection.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/author.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/value_objects/comic_language.dart';
import 'package:hentai_library/shared/util/name_pinyin_assisted_filter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:hentai_library/features/library_browse/public/l10n/library_browse_l10n.dart';
import 'package:hentai_library/features/series/public/l10n/series_l10n.dart';

const Duration _kFilterAccordionDuration = Duration(milliseconds: 200);
const Curve _kFilterAccordionCurve = Curves.easeOutCubic;
const double _kFilterOptionRowHeight = 40;
const double _kFilterMetadataListHeight = 240;
const double _kFilterMetadataSearchHeight = 36;
const double _kFilterMetadataSearchIconSize = 18;

typedef LibraryMetadataFilterToggle = Future<void> Function(String name);
typedef LibraryMetadataIncludeModeChanged = Future<void> Function(
  LibraryMetadataIncludeMode mode,
);

LibraryMetadataFilterSelection _includeOnlySelection(Set<String> names) {
  return LibraryMetadataFilterSelection(
    picks: <String, LibraryTriStatePick>{
      for (final String name in names) name: LibraryTriStatePick.include,
    },
  );
}

/// 库页筛选抽屉的「筛选」区（MD3E 生产实现，数据绑定 Riverpod）。
///
/// 漫画 Tab：年龄限制、媒体类型、语言、整理，底部成组为作者 → 原作 → 角色 → 标签；
/// 系列 Tab：年龄限制、连载状态。
class LibraryFilterSection extends StatelessWidget {
  const LibraryFilterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _AgeRestrictionFilterGroup(),
        _MediaTypeFilterGroup(),
        _SerializationStatusFilterGroup(),
        _LanguageFilterGroup(),
        _OrganizeFilterGroup(),
        _AuthorFilterGroup(),
        _ParodyFilterGroup(),
        _CharacterFilterGroup(),
        _TagFilterGroup(),
      ],
    );
  }
}

class _AgeRestrictionFilterGroup extends ConsumerWidget {
  const _AgeRestrictionFilterGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryDisplayTargetProvider,
    );
    final LibraryAgeRestrictionFilter selected = ref.watch(
      libraryActiveAgeRestrictionFilterProvider,
    );
    final AppLocalizations l10n = context.l10n;
    return _FilterAccordion(
      title: l10n.libraryAgeRestrictionFilter,
      child: Column(
        children: <Widget>[
          for (final LibraryAgeRestrictionFilter option
              in LibraryAgeRestrictionFilter.selectableOptions)
            _CheckboxOptionRow(
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

class _MediaTypeFilterGroup extends ConsumerWidget {
  const _MediaTypeFilterGroup();

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
    return _FilterAccordion(
      title: l10n.libraryMediaTypeFilter,
      child: Column(
        children: <Widget>[
          for (final LibraryMediaTypeFilterOption option
              in LibraryMediaTypeFilterOption.selectableOptions)
            _CheckboxOptionRow(
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

class _SerializationStatusFilterGroup extends ConsumerWidget {
  const _SerializationStatusFilterGroup();

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
    return _FilterAccordion(
      title: l10n.librarySerializationStatusFilter,
      child: Column(
        children: <Widget>[
          for (final LibrarySerializationStatusFilter option
              in LibrarySerializationStatusFilter.selectableOptions)
            _CheckboxOptionRow(
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

class _TagFilterGroup extends ConsumerWidget {
  const _TagFilterGroup();

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
    return _MetadataFilterGroup(
      title: context.l10n.libraryTagFilter,
      names: names,
      selection: selection,
      isLoading: namesAsync.isLoading && !namesAsync.hasValue,
      onToggle: notifier.toggleTag,
      onIncludeModeChanged: notifier.setTagIncludeMode,
    );
  }
}

class _AuthorFilterGroup extends ConsumerWidget {
  const _AuthorFilterGroup();

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
    return _MetadataFilterGroup(
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

class _LanguageFilterGroup extends ConsumerWidget {
  const _LanguageFilterGroup();

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
    return _MetadataFilterGroup(
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

class _ParodyFilterGroup extends ConsumerWidget {
  const _ParodyFilterGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryDisplayTargetProvider,
    );
    if (displayTarget != LibraryDisplayTarget.comics) {
      return const SizedBox.shrink();
    }
    final AsyncValue<List<String>> parodiesAsync = ref.watch(
      libraryFilterParodyNamesProvider,
    );
    final LibraryMetadataFilterSelection selection = ref.watch(
      libraryComicFiltersProvider.select(
        (AsyncValue<LibraryComicFiltersState> state) =>
            state.value?.parodyFilter ?? const LibraryMetadataFilterSelection(),
      ),
    );
    final List<String> names = parodiesAsync.value ?? const <String>[];
    final notifier = ref.read(libraryComicFiltersProvider.notifier);
    return _MetadataFilterGroup(
      title: context.l10n.libraryParodyFilter,
      names: names,
      selection: selection,
      isLoading: parodiesAsync.isLoading && !parodiesAsync.hasValue,
      onToggle: notifier.toggleParody,
      onIncludeModeChanged: notifier.setParodyIncludeMode,
    );
  }
}

class _CharacterFilterGroup extends ConsumerWidget {
  const _CharacterFilterGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryDisplayTargetProvider,
    );
    if (displayTarget != LibraryDisplayTarget.comics) {
      return const SizedBox.shrink();
    }
    final AsyncValue<List<String>> charactersAsync = ref.watch(
      libraryFilterCharacterNamesProvider,
    );
    final LibraryMetadataFilterSelection selection = ref.watch(
      libraryComicFiltersProvider.select(
        (AsyncValue<LibraryComicFiltersState> state) =>
            state.value?.characterFilter ??
            const LibraryMetadataFilterSelection(),
      ),
    );
    final List<String> names = charactersAsync.value ?? const <String>[];
    final notifier = ref.read(libraryComicFiltersProvider.notifier);
    return _MetadataFilterGroup(
      title: context.l10n.libraryCharacterFilter,
      names: names,
      selection: selection,
      isLoading: charactersAsync.isLoading && !charactersAsync.hasValue,
      onToggle: notifier.toggleCharacter,
      onIncludeModeChanged: notifier.setCharacterIncludeMode,
    );
  }
}

class _OrganizeFilterGroup extends ConsumerWidget {
  const _OrganizeFilterGroup();

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
    return _FilterAccordion(
      title: l10n.libraryOrganizeFilter,
      child: _CheckboxOptionRow(
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
class _FilterAccordion extends StatefulWidget {
  const _FilterAccordion({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  State<_FilterAccordion> createState() => _FilterAccordionState();
}

class _FilterAccordionState extends State<_FilterAccordion> {
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
              horizontal: kLibrarySortSectionInset,
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
class _OptionRow extends StatelessWidget {
  const _OptionRow({
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
          horizontal: kLibrarySortSectionInset,
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

class _CheckboxOptionRow extends StatelessWidget {
  const _CheckboxOptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _OptionRow(
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
class _MetadataFilterGroup extends StatefulWidget {
  const _MetadataFilterGroup({
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
  State<_MetadataFilterGroup> createState() => _MetadataFilterGroupState();
}

class _MetadataFilterGroupState extends State<_MetadataFilterGroup> {
  String _query = '';

  String _labelOf(String name) => widget.labelFor?.call(name) ?? name;

  bool _matches(String name) {
    final String haystack = _labelOf(name);
    if (!widget.enablePinyinAssistedNameMatch) {
      final String normalized = _query.trim().toLowerCase();
      return normalized.isEmpty || haystack.toLowerCase().contains(normalized);
    }
    return nameMatchesPinyinAssistedFilter(haystack, _query);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AppLocalizations l10n = context.l10n;
    final List<String> filteredNames = widget.names
        .where(_matches)
        .toList(growable: false);
    final bool showIncludeMode =
        !widget.includeOnly && widget.onIncludeModeChanged != null;

    return _FilterAccordion(
      title: widget.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              kLibrarySortSectionInset,
              8,
              kLibrarySortSectionInset,
              8,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _CompactMetadataSearchBar(
                    onChanged: (String value) => setState(() => _query = value),
                  ),
                ),
                if (showIncludeMode)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: _IncludeModeIconButton(
                      mode: widget.selection.includeMode,
                      onChanged: widget.onIncludeModeChanged!,
                    ),
                  ),
              ],
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
                kLibrarySortSectionInset,
                0,
                kLibrarySortSectionInset,
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
                  return _OptionRow(
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

/// 手风琴内小号 [M3ESearchBar]：无 hint，高度低于管理页 dense bar。
class _CompactMetadataSearchBar extends StatefulWidget {
  const _CompactMetadataSearchBar({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  State<_CompactMetadataSearchBar> createState() =>
      _CompactMetadataSearchBarState();
}

class _CompactMetadataSearchBarState extends State<_CompactMetadataSearchBar> {
  late final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleControllerTick);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerTick);
    _controller.dispose();
    super.dispose();
  }

  void _handleControllerTick() {
    if (mounted) {
      setState(() {});
    }
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3ESearchBarTheme compactTheme = theme.searchBarTheme.copyWith(
      minHeight: _kFilterMetadataSearchHeight,
      maxWidth: double.infinity,
      minWidth: 0,
      iconSize: _kFilterMetadataSearchIconSize,
      tapTargetSize: _kFilterMetadataSearchHeight,
      leadingSpace: 4,
      trailingSpace: 4,
      expandOnFocus: false,
    );
    final TextStyle textStyle = theme.typeScale.bodySmall.copyWith(
      color: theme.colorScheme.onSurface,
    );
    final bool showClear = _controller.text.isNotEmpty;

    return M3ETheme(
      data: theme.copyWith(searchBarTheme: compactTheme),
      child: SizedBox(
        height: _kFilterMetadataSearchHeight,
        child: M3ESearchBar(
          controller: _controller,
          onChanged: widget.onChanged,
          leading: const Icon(
            M3EIcons.search,
            size: _kFilterMetadataSearchIconSize,
          ),
          trailing: showClear
              ? <Widget>[
                  M3EIconButton(
                    icon: const Icon(M3EIcons.close, size: 16),
                    tooltip: 'Clear',
                    onPressed: _clear,
                    variant: M3EIconButtonVariant.standard,
                    size: M3EIconButtonSize.xs,
                  ),
                ]
              : null,
          expandOnFocus: false,
          showClearButton: false,
          margin: 0,
          focusedMargin: 0,
          textStyle: WidgetStatePropertyAll<TextStyle>(textStyle),
          constraints: const BoxConstraints(
            minWidth: 0,
            minHeight: _kFilterMetadataSearchHeight,
            maxHeight: _kFilterMetadataSearchHeight,
          ),
        ),
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
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppLocalizations l10n = context.l10n;
    final bool isAll = mode == LibraryMetadataIncludeMode.all;
    final String label = isAll
        ? l10n.libraryMetadataFilterIncludeAll
        : l10n.libraryMetadataFilterIncludeAny;
    return M3EIconButton(
      icon: Icon(
        isAll ? LucideIcons.listChecks : LucideIcons.circleDot,
        size: 16,
        color: isAll ? cs.primary : cs.onSurfaceVariant,
      ),
      tooltip: label,
      semanticLabel: label,
      onPressed: () => onChanged(
        isAll ? LibraryMetadataIncludeMode.any : LibraryMetadataIncludeMode.all,
      ),
      variant: M3EIconButtonVariant.standard,
      size: M3EIconButtonSize.sm,
    );
  }
}
