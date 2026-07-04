import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/library/comic_list_query.dart';
import 'package:hentai_library/domain/library/library_comic_sort_option.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_view_model_providers.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_filter_sort_providers.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_sort_notifier.dart';
import 'package:hentai_library/ui/features/library/views/desktop/library_page/widgets/library_filter_sort_drawer.dart';
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
    final List<LibraryComicSortField> fields = switch (displayTarget) {
      LibraryDisplayTarget.comics => LibraryComicSortField.values,
      LibraryDisplayTarget.series => const <LibraryComicSortField>[
        LibraryComicSortField.title,
      ],
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: fields
          .map(
            (LibraryComicSortField field) =>
                _LibrarySortListRow(field: field),
          )
          .toList(),
    );
  }
}

class _LibrarySortListRow extends ConsumerWidget {
  const _LibrarySortListRow({required this.field});

  final LibraryComicSortField field;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryDisplayTargetProvider,
    );
    final LibraryComicSortOption sortOption = ref.watch(
      libraryActiveSortOptionProvider,
    );
    final bool isSelected = sortOption.field == field;
    final bool isImplemented = field.isImplemented;
    final bool isAscending = !sortOption.descending;
    final TextStyle labelStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: isImplemented
          ? cs.hentai.textSecondary
          : cs.hentai.textTertiary,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isImplemented
            ? () {
                ref
                    .read(libraryTabSortProvider.notifier)
                    .setSortField(displayTarget, field);
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
                child: Text(
                  field.label,
                  style: labelStyle,
                ),
              ),
              if (!isImplemented)
                Text(
                  '即将推出',
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.hentai.textTertiary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
