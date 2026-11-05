import 'package:flutter/widgets.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/ui/models/series_serialization_status.dart';

export 'package:hentai_library/shared/ui/models/series_serialization_status.dart';

/// 系列内单册预览项。
class Md3eSeriesDetailComicItem {
  const Md3eSeriesDetailComicItem({
    required this.title,
    this.pageCount,
    this.readProgress,
    this.cover,
    this.comic,
  });

  final String title;
  final int? pageCount;
  final double? readProgress;

  /// 单册封面；为空时网格显示占位图标。
  final Widget? cover;

  /// 生产页右键菜单；Lab 占位项可为 null。
  final Comic? comic;
}

/// Lab 系列详情数据。
class Md3eSeriesDetailEntry {
  const Md3eSeriesDetailEntry({
    required this.title,
    this.cover,
    this.serializationStatus = Md3eSeriesSerializationStatus.ongoing,
    this.languages = const <String>[],
    this.showAgeRestrictionChip = false,
    this.volumeCurrent = 0,
    this.volumeTotal,
    this.showMetadataBlock = true,
    this.parodies = const <String>[],
    this.authors = const <String>[],
    this.characters = const <String>[],
    this.tags = const <String>[],
    this.comics = const <Md3eSeriesDetailComicItem>[],
    this.initialPage = 1,
    this.initialPageSize = 20,
  });

  final String title;
  final Widget? cover;
  final Md3eSeriesSerializationStatus serializationStatus;

  /// 已本地化的语言展示名（卷册语言并集；多数系列仅一项）。
  final List<String> languages;
  final bool showAgeRestrictionChip;
  final int volumeCurrent;
  final int? volumeTotal;
  final bool showMetadataBlock;
  final List<String> parodies;
  final List<String> authors;
  final List<String> characters;
  final List<String> tags;
  final List<Md3eSeriesDetailComicItem> comics;
  final int initialPage;
  final int initialPageSize;

  Md3eSeriesDetailEntry copyWith({
    bool? showAgeRestrictionChip,
    bool? showMetadataBlock,
    Md3eSeriesSerializationStatus? serializationStatus,
  }) {
    return Md3eSeriesDetailEntry(
      title: title,
      cover: cover,
      serializationStatus: serializationStatus ?? this.serializationStatus,
      languages: languages,
      showAgeRestrictionChip:
          showAgeRestrictionChip ?? this.showAgeRestrictionChip,
      volumeCurrent: volumeCurrent,
      volumeTotal: volumeTotal,
      showMetadataBlock: showMetadataBlock ?? this.showMetadataBlock,
      parodies: parodies,
      authors: authors,
      characters: characters,
      tags: tags,
      comics: comics,
      initialPage: initialPage,
      initialPageSize: initialPageSize,
    );
  }
}
