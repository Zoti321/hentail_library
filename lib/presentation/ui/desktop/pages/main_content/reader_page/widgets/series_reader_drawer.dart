import 'package:flutter/material.dart';
import 'package:hentai_library/theme/theme.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/reader_page/widgets/reader_route_context.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SeriesReaderDrawer extends StatelessWidget {
  const SeriesReaderDrawer({
    super.key,
    required this.navContext,
    required this.comicId,
    required this.onSelectComic,
  });
  final ReaderNavContextData navContext;
  final String comicId;
  final void Function(String targetComicId) onSelectComic;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String drawerTitle = navContext.seriesName ?? '漫画列表';
    return Drawer(
      backgroundColor: cs.readerBackground,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '列表：$drawerTitle',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.readerTextIconPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: '关闭',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(LucideIcons.x, color: cs.readerTextIconPrimary),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: cs.readerPanelBorder),
            Expanded(
              child: ListView.builder(
                itemCount: navContext.items.length,
                itemBuilder: (BuildContext context, int index) {
                  final ReaderComicListItem item = navContext.items[index];
                  final bool isCurrent = item.comicId == comicId;
                  return ListTile(
                    selected: isCurrent,
                    selectedTileColor: cs.readerPanelSubtle,
                    title: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.readerTextIconPrimary,
                        fontWeight: isCurrent
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    leading: SizedBox(
                      width: 32,
                      child: Text(
                        '${index + 1}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.readerTextSecondary,
                        ),
                      ),
                    ),
                    onTap: isCurrent ? null : () => onSelectComic(item.comicId),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
