import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_filter_accordion.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_filter_sort_drawer.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

typedef IncludeSetToggle = Future<void> Function(String name);
typedef IncludeSetClear = Future<void> Function();

/// Simplified filter section for include-only (OR) set filters
/// (language, parody, character). No exclude, no include mode toggle.
class LibraryIncludeSetFilterControls extends HookConsumerWidget {
  const LibraryIncludeSetFilterControls({
    super.key,
    required this.title,
    required this.names,
    required this.selected,
    required this.onToggle,
    required this.onClear,
    this.isLoading = false,
  });

  final String title;
  final List<String> names;
  final Set<String> selected;
  final IncludeSetToggle onToggle;
  final IncludeSetClear onClear;
  final bool isLoading;

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
                  if (selected.isNotEmpty)
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
              if (names.length > 6)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    kLibraryFilterSortDrawerContentInset,
                    tokens.spacing.sm,
                    kLibraryFilterSortDrawerContentInset,
                    8,
                  ),
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
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredNames.length,
                    itemBuilder: (BuildContext context, int index) {
                      final String name = filteredNames[index];
                      final bool isSelected = selected.contains(name);
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
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: Checkbox(
                                    value: isSelected,
                                    onChanged: (_) => onToggle(name),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    name,
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
