import 'package:flutter/widgets.dart';

/// Lab 连载状态（与生产 [SerializationStatus] 语义对齐，无领域依赖）。
enum Md3eSeriesSerializationStatus {
  unknown,
  ongoing,
  ended,
  hiatus,
}

/// 系列内单册预览项。
class Md3eSeriesDetailComicItem {
  const Md3eSeriesDetailComicItem({
    required this.title,
    this.pageCount,
    this.readProgress,
  });

  final String title;
  final int? pageCount;
  final double? readProgress;
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
