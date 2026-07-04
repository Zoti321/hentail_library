import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/library/view_models/library_age_restriction_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_view_model_providers.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_filter_sort_providers.dart';
import 'package:hentai_library/ui/features/library/views/desktop/library_page/widgets/library_filter_sort_drawer.dart';
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
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryDisplayTargetProvider,
    );
    final LibraryAgeRestrictionFilter selected = ref.watch(
      libraryActiveAgeRestrictionFilterProvider,
    );

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
          Column(
            children: LibraryAgeRestrictionFilter.selectableOptions
                .map(
                  (LibraryAgeRestrictionFilter option) =>
                      _AgeRestrictionOptionRow(
                        label: option.label,
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
      ],
    );
  }
}

class _AgeRestrictionOptionRow extends StatelessWidget {
  const _AgeRestrictionOptionRow({
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
