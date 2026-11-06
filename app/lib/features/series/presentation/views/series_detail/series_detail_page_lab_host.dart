import 'package:flutter/material.dart';
import 'package:hentai_library/features/series/presentation/views/series_detail/series_detail_layout.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

export 'package:hentai_library/features/series/presentation/views/series_detail/series_detail_layout.dart';
export 'package:hentai_library/features/series/presentation/views/series_detail/series_detail_view_object.dart';

/// Lab / Widgetbook 宿主：在调用方切片并维护页码；[SeriesDetailLayout] 只渲染当前页。
class SeriesDetailPageLabHost extends StatefulWidget {
  const SeriesDetailPageLabHost({
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

  /// 完整漫画列表；宿主按页切片后传入 [SeriesDetailLayout]。
  final SeriesDetailViewObject entry;
  final VoidCallback? onBack;
  final VoidCallback? onEdit;
  final List<M3EMenuNode>? moreMenuEntries;
  final ValueChanged<String>? onMetadataChipTap;
  final ValueChanged<int>? onComicTap;
  final ValueChanged<String>? onAuthorTap;
  final ScrollController? scrollController;

  @override
  State<SeriesDetailPageLabHost> createState() =>
      _SeriesDetailPageLabHostState();
}

class _SeriesDetailPageLabHostState
    extends State<SeriesDetailPageLabHost> {
  late int _pageSize;
  late int _page;

  static int _totalPagesFor(SeriesDetailViewObject entry, int pageSize) {
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

  List<SeriesDetailComicItem> _pageItems() {
    final List<SeriesDetailComicItem> comics = widget.entry.comics;
    if (comics.isEmpty) {
      return const <SeriesDetailComicItem>[];
    }
    final int start = (_page - 1) * _pageSize;
    if (start >= comics.length) {
      return const <SeriesDetailComicItem>[];
    }
    final int end = (start + _pageSize).clamp(0, comics.length);
    return comics.sublist(start, end);
  }

  @override
  void didUpdateWidget(covariant SeriesDetailPageLabHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry != widget.entry) {
      _pageSize = widget.entry.initialPageSize;
      _page = widget.entry.initialPage.clamp(
        1,
        _totalPagesFor(widget.entry, _pageSize),
      );
    }
  }

  SeriesDetailViewObject _pageEntry() {
    return SeriesDetailViewObject(
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
    return SeriesDetailLayout(
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
