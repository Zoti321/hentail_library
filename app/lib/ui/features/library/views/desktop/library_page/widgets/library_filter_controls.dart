import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/library/views/desktop/library_page/widgets/library_filter_sort_drawer.dart';
import 'package:hentai_library/ui/features/library/view_models/library_age_restriction_notifier.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
    final AsyncValue<LibraryAgeRestrictionFilter> filterAsync = ref.watch(
      libraryAgeRestrictionFilterProvider,
    );
    final LibraryAgeRestrictionFilter selected =
        filterAsync.value ?? LibraryAgeRestrictionFilter.unrestricted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Material(
          color: cs.surfaceContainerHighest,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
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
                      '年龄限制',
                      style: TextStyle(
                        fontSize: tokens.text.bodySm,
                        fontWeight: FontWeight.w500,
                        color: cs.hentai.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 16,
                    color: cs.hentai.iconSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_expanded)
          ColoredBox(
            color: cs.surface,
            child: Column(
              children: LibraryAgeRestrictionFilter.values
                  .map(
                    (LibraryAgeRestrictionFilter option) => _AgeRestrictionOptionTile(
                      label: option.label,
                      selected: selected == option,
                      onChanged: () {
                        ref
                            .read(
                              libraryAgeRestrictionFilterProvider.notifier,
                            )
                            .setFilter(option);
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

class _AgeRestrictionOptionTile extends StatelessWidget {
  const _AgeRestrictionOptionTile({
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final bool selected;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return CheckboxListTile(
      value: selected,
      onChanged: (_) => onChanged(),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: kLibraryFilterSortDrawerContentInset,
      ),
      dense: true,
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: cs.hentai.textPrimary,
        ),
      ),
    );
  }
}
