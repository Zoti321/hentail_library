import 'package:flutter/material.dart';
import 'package:hentai_library/features/series/presentation/views/series_detail_md3e/series_detail_page.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Lab / Widgetbook 宿主：在调用方切片并维护页码；[Md3eSeriesDetailPage] 只渲染当前页。
class Md3eSeriesDetailPageLabHost extends StatefulWidget {
  const Md3eSeriesDetailPageLabHost({
    super.key,
    required this.entry,
    this.onBack,
    this.onEdit,
    this.moreMenuEntries,
    this.onMetadataChipTap,
    this.onComicTap,
    this.onAuthorTap,
    this.scrollController,
  });

  /// 完整漫画列表；宿主按页切片后传入 [Md3eSeriesDetailPage]。
  final Md3eSeriesDetailEntry entry;
  final VoidCallback? onBack;
  final VoidCallback? onEdit;
  final List<M3EMenuNode>? moreMenuEntries;
  final ValueChanged<String>? onMetadataChipTap;
  final ValueChanged<int>? onComicTap;
  final ValueChanged<String>? onAuthorTap;
  final ScrollController? scrollController;

  @override
  State<Md3eSeriesDetailPageLabHost> createState() =>
      _Md3eSeriesDetailPageLabHostState();
}

class _Md3eSeriesDetailPageLabHostState
    extends State<Md3eSeriesDetailPageLabHost> {
  late int _pageSize;
  late int _page;

  static int _totalPagesFor(Md3eSeriesDetailEntry entry, int pageSize) {
    final int count = entry.comics.length;
    if (count == 0) {
      return 1;
    }
    return (count / pageSize).ceil();
  }

  int get _totalPages => _totalPagesFor(widget.entry, _pageSize);

  @override
  void initState() {
    super.initState();
    _pageSize = widget.entry.initialPageSize;
    _page = widget.entry.initialPage.clamp(
      1,
      _totalPagesFor(widget.entry, _pageSize),
    );
  }

  List<Md3eSeriesDetailComicItem> _pageItems() {
    final List<Md3eSeriesDetailComicItem> comics = widget.entry.comics;
    if (comics.isEmpty) {
      return const <Md3eSeriesDetailComicItem>[];
    }
    final int start = (_page - 1) * _pageSize;
    if (start >= comics.length) {
      return const <Md3eSeriesDetailComicItem>[];
    }
    final int end = (start + _pageSize).clamp(0, comics.length);
    return comics.sublist(start, end);
  }

  @override
  void didUpdateWidget(covariant Md3eSeriesDetailPageLabHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry != widget.entry) {
      _pageSize = widget.entry.initialPageSize;
      _page = widget.entry.initialPage.clamp(
        1,
        _totalPagesFor(widget.entry, _pageSize),
      );
    }
  }

  Md3eSeriesDetailEntry _pageEntry() {
    return Md3eSeriesDetailEntry(
      title: widget.entry.title,
      cover: widget.entry.cover,
      serializationStatus: widget.entry.serializationStatus,
      languages: widget.entry.languages,
      showAgeRestrictionChip: widget.entry.showAgeRestrictionChip,
      volumeCurrent: widget.entry.volumeCurrent,
      volumeTotal: widget.entry.volumeTotal,
      showMetadataBlock: widget.entry.showMetadataBlock,
      parodies: widget.entry.parodies,
      authors: widget.entry.authors,
      characters: widget.entry.characters,
      tags: widget.entry.tags,
      comics: _pageItems(),
      initialPage: _page,
      initialPageSize: _pageSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Md3eSeriesDetailPage(
      entry: _pageEntry(),
      onBack: widget.onBack,
      onEdit: widget.onEdit,
      moreMenuEntries: widget.moreMenuEntries,
      onMetadataChipTap: widget.onMetadataChipTap,
      onComicTap: widget.onComicTap,
      onAuthorTap: widget.onAuthorTap,
      scrollController: widget.scrollController,
      page: _page,
      pageSize: _pageSize,
      totalPages: _totalPages,
      onPageChanged: (int target) => setState(() {
        _page = target.clamp(1, _totalPages);
      }),
      onPageSizeChanged: (int size) => setState(() {
        _pageSize = size;
        _page = _page.clamp(1, _totalPages);
      }),
    );
  }
}
