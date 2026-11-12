import 'package:hentai_library/features/series/domain/value_objects/serialization_status.dart';
import 'package:flutter/widgets.dart';
import 'package:hentai_library/features/comic/public/comic.dart';
import 'package:hentai_library/shared/domain/models/value_objects/author_ref.dart';

export 'package:hentai_library/features/series/domain/value_objects/serialization_status.dart';

/// 系列内单册预览项。
class SeriesDetailComicItem {
  const SeriesDetailComicItem({
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
class SeriesDetailViewObject {
  const SeriesDetailViewObject({
    required this.title,
    this.cover,
    this.serializationStatus = SerializationStatus.ongoing,
    this.languages = const <String>[],
    this.showAgeRestrictionChip = false,
    this.volumeCurrent = 0,
    this.volumeTotal,
    this.showMetadataBlock = true,
    this.parodies = const <String>[],
    this.authors = const <AuthorRef>[],
    this.characters = const <String>[],
    this.tags = const <String>[],
    this.comics = const <SeriesDetailComicItem>[],
    this.initialPage = 1,
    this.initialPageSize = 20,
  });

  final String title;
  final Widget? cover;
  final SerializationStatus serializationStatus;

  /// 已本地化的语言展示名（卷册语言并集；多数系列仅一项）。
  final List<String> languages;
  final bool showAgeRestrictionChip;
  final int volumeCurrent;
  final int? volumeTotal;
  final bool showMetadataBlock;
  final List<String> parodies;
  final List<AuthorRef> authors;
  final List<String> characters;
  final List<String> tags;
  final List<SeriesDetailComicItem> comics;
  final int initialPage;
  final int initialPageSize;

  SeriesDetailViewObject copyWith({
    bool? showAgeRestrictionChip,
    bool? showMetadataBlock,
    SerializationStatus? serializationStatus,
  }) {
    return SeriesDetailViewObject(
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
