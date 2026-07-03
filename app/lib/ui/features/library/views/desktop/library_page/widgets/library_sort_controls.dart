import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/library/comic_list_query.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 库页漫画列表排序控件，供侧边栏与旧版弹层复用。
class LibrarySortControls extends ConsumerWidget {
  const LibrarySortControls({super.key, this.showReset = true});

  final bool showReset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryComicSortOption sortOption = ref.watch(
      libraryQueryIntentProvider.select((LibraryQueryIntent s) => s.sortOption),
    );
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _LibrarySortSection(option: sortOption),
        if (showReset) ...<Widget>[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: GhostButton.iconText(
              icon: LucideIcons.rotateCcw,
              text: '重置',
              tooltip: '重置排序',
              semanticLabel: '重置排序',
              iconSize: 14,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              borderRadius: 7,
              foregroundColor: theme.colorScheme.primary,
              hoverColor: theme.colorScheme.primary.withAlpha(10),
              overlayColor: theme.colorScheme.primary.withAlpha(14),
              delayTooltipThreeSeconds: false,
              onPressed: () {
                ref.read(libraryQueryIntentProvider.notifier).resetSortOption();
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _LibrarySortSection extends ConsumerWidget {
  const _LibrarySortSection({required this.option});

  final LibraryComicSortOption option;

  bool get isAsc => !option.descending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              '主要规则',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: colorScheme.hentai.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            Material(
              color: isAsc
                  ? colorScheme.primaryContainer
                  : colorScheme.hentai.warning.withAlpha(24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(
                  color: isAsc
                      ? colorScheme.primary.withAlpha(70)
                      : colorScheme.hentai.warning.withAlpha(90),
                  width: 1,
                ),
              ),
              child: InkWell(
                onTap: () {
                  ref
                      .read(libraryQueryIntentProvider.notifier)
                      .setSortDescending(!option.descending);
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 4,
                    children: <Widget>[
                      Icon(
                        isAsc ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12,
                        color: isAsc
                            ? colorScheme.primary
                            : colorScheme.hentai.warning,
                      ),
                      Text(
                        isAsc ? '升序' : '降序',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isAsc
                              ? colorScheme.primary
                              : colorScheme.hentai.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        Row(
          spacing: 8,
          children: <Widget>[
            Flexible(
              child: _LibrarySortOption(
                key: Key(LibraryComicSortField.title.toString()),
                field: LibraryComicSortField.title,
                label: '标题',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LibrarySortOption extends ConsumerWidget {
  const _LibrarySortOption({
    super.key,
    required this.field,
    required this.label,
  });

  final LibraryComicSortField field;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isSelected =
        ref.watch(
          libraryQueryIntentProvider.select((LibraryQueryIntent s) => s.sortOption.field),
        ) ==
        field;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primary : colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.hentai.borderSubtle,
        ),
        boxShadow: isSelected
            ? <BoxShadow>[
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref.read(libraryQueryIntentProvider.notifier).setSortField(field);
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.hentai.textTertiary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
