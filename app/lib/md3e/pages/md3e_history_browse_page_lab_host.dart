import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/pages/md3e_history_browse_entry.dart';
import 'package:hentai_library/md3e/pages/md3e_history_browse_page.dart';
import 'package:hentai_library/md3e/pages/md3e_history_browse_page_preview_data.dart';
import 'package:hentai_library/md3e/widgets/history/md3e_reading_history_list_item.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Lab / Widgetbook：preview 阅读历史 + 清空全部（M3E 确认 → 清内存列表，不写 FRB）。
class Md3eHistoryBrowsePageLabHost extends StatefulWidget {
  const Md3eHistoryBrowsePageLabHost({
    super.key,
    this.initialEntries,
    this.clock,
  });

  final List<Md3eHistoryBrowseEntry>? initialEntries;

  /// 分桶与相对时间展示的稳定参照（测试 / Widgetbook 可注入）。
  final DateTime? clock;

  @override
  State<Md3eHistoryBrowsePageLabHost> createState() =>
      _Md3eHistoryBrowsePageLabHostState();
}

class _Md3eHistoryBrowsePageLabHostState
    extends State<Md3eHistoryBrowsePageLabHost> {
  late List<Md3eHistoryBrowseEntry> _entries =
      List<Md3eHistoryBrowseEntry>.of(
        widget.initialEntries ??
            Md3eHistoryBrowsePagePreviewData.sampleEntries(
              clock: widget.clock,
            ),
      );

  void _clearAllPreviewEntries() {
    setState(() => _entries = <Md3eHistoryBrowseEntry>[]);
  }

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;

    return Md3eHistoryBrowsePage(
      entries: _entries,
      clock: widget.clock,
      onClearAll: _clearAllPreviewEntries,
      itemBuilder: (BuildContext context, Md3eHistoryBrowseEntry entry) {
        final int index = _entries.indexOf(entry);
        final String title = Md3eHistoryBrowsePagePreviewData.sampleTitles[
            index % Md3eHistoryBrowsePagePreviewData.sampleTitles.length];
        return Md3eReadingHistoryListItem(
          title: title,
          currentPage: 12 + index,
          totalPages: 48,
          lastReadTime: entry.lastReadTime,
          cover: ColoredBox(
            color: scheme.surfaceContainerHigh,
            child: Icon(
              Icons.image_outlined,
              color: scheme.onSurfaceVariant,
              size: 20,
            ),
          ),
        );
      },
    );
  }
}
