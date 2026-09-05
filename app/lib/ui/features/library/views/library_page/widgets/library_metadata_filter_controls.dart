import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/library/library_metadata_filter_selection.dart';
import 'package:hentai_library/domain/library/library_tri_state_pick.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_filter_accordion.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_filter_sort_drawer.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_tri_state_filter_checkbox.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

typedef LibraryMetadataFilterToggle = Future<void> Function(String name);
typedef LibraryMetadataIncludeModeChanged =
    Future<void> Function(LibraryMetadataIncludeMode mode);
typedef LibraryMetadataFilterClear = Future<void> Function();

class LibraryMetadataFilterControls extends HookConsumerWidget {
  const LibraryMetadataFilterControls({
    super.key,
    required this.title,
    required this.names,
    required this.selection,
    required this.onToggle,
    this.onIncludeModeChanged,
    required this.onClear,
    this.isLoading = false,
    this.includeOnly = false,
    this.labelFor,
  });

  final String title;
  final List<String> names;
  final LibraryMetadataFilterSelection selection;
  final LibraryMetadataFilterToggle onToggle;
  final LibraryMetadataIncludeModeChanged? onIncludeModeChanged;
  final LibraryMetadataFilterClear onClear;
  final bool isLoading;
  final bool includeOnly;
  final String Function(String name)? labelFor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ValueNotifier<bool> expanded = useState<bool>(false);
    final ValueNotifier<String> searchQuery = useState<String>('');
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final AppLocalizations l10n = context.l10n;
    final String query = searchQuery.value.trim().toLowerCase();
    final List<String> filteredNames = query.isEmpty
        ? names
        : names
              .where((String name) => name.toLowerCase().contains(query))
              .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => expanded.value = !expanded.value,
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
                      title,
                      style: TextStyle(
                        fontSize: tokens.text.bodySm,
                        fontWeight: FontWeight.w500,
                        color: cs.hentai.textPrimary,
                      ),
                    ),
                  ),
                  if (selection.isActive)
                    TextButton(
                      onPressed: () => onClear(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        l10n.libraryMetadataFilterClear,
                        style: TextStyle(fontSize: 12, color: cs.primary),
                      ),
                    ),
                  LibraryFilterAccordionChevron(expanded: expanded.value),
                ],
              ),
            ),
          ),
        ),
        LibraryFilterAccordionBody(
          expanded: expanded.value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (!includeOnly || names.length > 6)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  kLibraryFilterSortDrawerContentInset,
                  tokens.spacing.sm,
                  kLibraryFilterSortDrawerContentInset,
                  8,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        onChanged: (String value) => searchQuery.value = value,
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.hentai.textPrimary,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: l10n.libraryMetadataFilterSearchHint,
                          hintStyle: TextStyle(color: cs.hentai.textTertiary),
                          prefixIcon: Icon(
                            LucideIcons.search,
                            size: 16,
                            color: cs.hentai.iconSecondary,
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 32,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: cs.outlineVariant),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: cs.outlineVariant),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (!includeOnly && onIncludeModeChanged != null)
                      _IncludeModeIconButton(
                        mode: selection.includeMode,
                        onChanged: onIncludeModeChanged!,
                      ),
                  ],
                ),
              ),
              if (isLoading)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.primary,
                      ),
                    ),
                  ),
                )
              else if (filteredNames.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    kLibraryFilterSortDrawerContentInset,
                    0,
                    kLibraryFilterSortDrawerContentInset,
                    8,
                  ),
                  child: Text(
                    l10n.libraryMetadataFilterEmpty,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.hentai.textTertiary,
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 240,
                  child: ListView.builder(
                    itemExtent: 40,
                    itemCount: filteredNames.length,
                    itemBuilder: (BuildContext context, int index) {
                      final String name = filteredNames[index];
                      final LibraryTriStatePick state = selection.pickStateFor(
                        name,
                      );
                      final bool isIncluded =
                          state == LibraryTriStatePick.include;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => onToggle(name),
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
                                if (includeOnly)
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: Checkbox(
                                      value: isIncluded,
                                      onChanged: (_) => onToggle(name),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  )
                                else
                                  LibraryTriStateFilterCheckbox(
                                    state: state,
                                    onPressed: () => onToggle(name),
                                  ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    labelFor?.call(name) ?? name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: cs.hentai.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
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
      foregroundColor: isAll ? cs.primary : cs.hentai.iconSecondary,
      hoverColor: theme.hoverColor,
      overlayColor: theme.hoverColor,
      onPressed: () => onChanged(
        isAll ? LibraryMetadataIncludeMode.any : LibraryMetadataIncludeMode.all,
      ),
    );
  }
}
