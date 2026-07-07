import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_floating_panel.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_route_context.dart';

const double kReaderSeriesMenuWidth = 320;
const double kReaderSeriesMenuMaxHeight = 360;

class ReaderSeriesMenu extends StatelessWidget {
  const ReaderSeriesMenu({
    super.key,
    required this.navContext,
    required this.onSelect,
  });

  final ReaderNavContextData navContext;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return ReaderFloatingMenuPanel(
      width: kReaderSeriesMenuWidth,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: kReaderSeriesMenuMaxHeight,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: navContext.items
                .map(
                  (ReaderComicListItem item) => _ReaderSeriesMenuItem(
                    item: item,
                    displayIndex: navContext.items.indexOf(item) + 1,
                    isCurrent:
                        item.comicId ==
                        navContext.items[navContext.currentIndex].comicId,
                    onTap: () => onSelect(item.comicId),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _ReaderSeriesMenuItem extends StatelessWidget {
  const _ReaderSeriesMenuItem({
    required this.item,
    required this.displayIndex,
    required this.isCurrent,
    required this.onTap,
  });

  final ReaderComicListItem item;
  final int displayIndex;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final String label = '$displayIndex-${item.title}';
    final TextStyle textStyle = TextStyle(
      fontSize: tokens.text.bodySm,
      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
      color: isCurrent ? cs.primary : cs.hentai.readerTextIconPrimary,
      height: 1.35,
    );
    return Material(
      color: isCurrent ? cs.primary.withAlpha(14) : Colors.transparent,
      child: InkWell(
        onTap: isCurrent ? null : onTap,
        hoverColor: isCurrent ? Colors.transparent : cs.primary.withAlpha(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Tooltip(
            message: label,
            waitDuration: const Duration(milliseconds: 500),
            child: Text(
              label,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
        ),
      ),
    );
  }
}
