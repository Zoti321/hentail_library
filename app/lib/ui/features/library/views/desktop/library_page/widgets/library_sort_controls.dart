import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/library/comic_list_query.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const double kLibrarySortIconSlotWidth = 20;

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
    final LibraryComicSortOption sortOption = ref.watch(
      libraryQueryIntentProvider.select(
        (LibraryQueryIntent s) => s.sortOption,
      ),
    );
    final bool isSelected = sortOption.field == field;
    final bool isImplemented = field.isImplemented;
    final bool isAscending = !sortOption.descending;

    return Material(
      color: isSelected
          ? cs.primaryContainer.withValues(alpha: 0.35)
          : Colors.transparent,
      child: InkWell(
        onTap: isImplemented
            ? () {
                ref
                    .read(libraryQueryIntentProvider.notifier)
                    .setSortField(field);
              }
            : null,
        hoverColor: isImplemented ? theme.hoverColor : null,
        splashColor: isImplemented ? theme.splashColor : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
              Expanded(
                child: Text(
                  field.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isImplemented
                        ? (isSelected
                              ? cs.hentai.textPrimary
                              : cs.hentai.textSecondary)
                        : cs.hentai.textTertiary,
                  ),
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
