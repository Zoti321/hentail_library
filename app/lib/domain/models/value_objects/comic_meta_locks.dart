import 'package:flutter/foundation.dart';

/// Comic 元数据字段锁（Komga 式）；默认全部未锁。
@immutable
class ComicMetaLocks {
  const ComicMetaLocks({
    this.title = false,
    this.description = false,
    this.publishedAt = false,
    this.contentRating = false,
    this.authors = false,
    this.tags = false,
    this.languages = false,
    this.parodies = false,
  });

  static const ComicMetaLocks unlocked = ComicMetaLocks();

  final bool title;
  final bool description;
  final bool publishedAt;
  final bool contentRating;
  final bool authors;
  final bool tags;
  final bool languages;
  final bool parodies;

  ComicMetaLocks copyWith({
    bool? title,
    bool? description,
    bool? publishedAt,
    bool? contentRating,
    bool? authors,
    bool? tags,
    bool? languages,
    bool? parodies,
  }) {
    return ComicMetaLocks(
      title: title ?? this.title,
      description: description ?? this.description,
      publishedAt: publishedAt ?? this.publishedAt,
      contentRating: contentRating ?? this.contentRating,
      authors: authors ?? this.authors,
      tags: tags ?? this.tags,
      languages: languages ?? this.languages,
      parodies: parodies ?? this.parodies,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComicMetaLocks &&
          title == other.title &&
          description == other.description &&
          publishedAt == other.publishedAt &&
          contentRating == other.contentRating &&
          authors == other.authors &&
          tags == other.tags &&
          languages == other.languages &&
          parodies == other.parodies;

  @override
  int get hashCode => Object.hash(
    title,
    description,
    publishedAt,
    contentRating,
    authors,
    tags,
    languages,
    parodies,
  );
}
