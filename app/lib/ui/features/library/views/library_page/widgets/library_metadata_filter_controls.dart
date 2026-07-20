import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/library/library_metadata_filter_selection.dart';
import 'package:hentai_library/domain/library/library_tri_state_pick.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
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
    required this.onIncludeModeChanged,
    required this.onClear,
    this.isLoading = false,
  });

  final String title;
  final List<String> names;
  final LibraryMetadataFilterSelection selection;
  final LibraryMetadataFilterToggle onToggle;
  final LibraryMetadataIncludeModeChanged onIncludeModeChanged;
  final LibraryMetadataFilterClear onClear;
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
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  Icon(
                    expanded.value
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    size: 16,
                    color: cs.hentai.iconSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (expanded.value) ...<Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              kLibraryFilterSortDrawerContentInset,
              0,
              kLibraryFilterSortDrawerContentInset,
              8,
            ),
            child: _IncludeModeToggle(
              mode: selection.includeMode,
              onChanged: onIncludeModeChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              kLibraryFilterSortDrawerContentInset,
              0,
              kLibraryFilterSortDrawerContentInset,
              8,
            ),
            child: TextField(
              onChanged: (String value) => searchQuery.value = value,
              style: TextStyle(fontSize: 13, color: cs.hentai.textPrimary),
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
                style: TextStyle(fontSize: 12, color: cs.hentai.textTertiary),
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
                  final LibraryTriStatePick state = selection.pickStateFor(name);
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
                            LibraryTriStateFilterCheckbox(
                              state: state,
                              onPressed: () => onToggle(name),
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
      ],
    );
  }
}

class _IncludeModeToggle extends StatelessWidget {
  const _IncludeModeToggle({
    required this.mode,
    required this.onChanged,
  });

  final LibraryMetadataIncludeMode mode;
  final LibraryMetadataIncludeModeChanged onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Row(
      children: <Widget>[
        Expanded(
          child: _IncludeModeChip(
            label: l10n.libraryMetadataFilterIncludeAny,
            selected: mode == LibraryMetadataIncludeMode.any,
            onTap: () => onChanged(LibraryMetadataIncludeMode.any),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _IncludeModeChip(
            label: l10n.libraryMetadataFilterIncludeAll,
            selected: mode == LibraryMetadataIncludeMode.all,
            onTap: () => onChanged(LibraryMetadataIncludeMode.all),
          ),
        ),
      ],
    );
  }
}

class _IncludeModeChip extends StatelessWidget {
  const _IncludeModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Material(
      color: selected ? cs.primary.withAlpha(20) : cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? cs.primary : cs.hentai.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
