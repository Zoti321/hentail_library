import 'package:flutter/widgets.dart';
import 'package:hentai_library/shared/domain/models/value_objects/author_ref.dart';

/// Lab 漫画详情数据（无 [Comic] 领域类型）。
class ComicDetailViewObject {
  const ComicDetailViewObject({
    required this.title,
    this.description,
    this.pageCount,
    this.publishedLabel,
    this.parodies = const <String>[],
    this.authors = const <AuthorRef>[],
    this.characters = const <String>[],
    this.tags = const <String>[],
    this.resourceFormat = 'ZIP',
    this.resourceSizeLabel = '—',
    this.resourcePath = '—',
    this.addedAtLabel,
    this.updatedAtLabel,
    this.cover,
    this.showSeriesNav = true,
    this.seriesCatalog = const <String>[],
    this.seriesCurrentIndex = 0,
    this.showAgeRestrictionChip = true,
  });

  final String title;
  final String? description;
  final int? pageCount;
  final String? publishedLabel;
  final List<String> parodies;
  final List<AuthorRef> authors;
  final List<String> characters;
  final List<String> tags;
  final String resourceFormat;
  final String resourceSizeLabel;
  final String resourcePath;
  final String? addedAtLabel;
  final String? updatedAtLabel;
  final Widget? cover;
  final bool showSeriesNav;
  final List<String> seriesCatalog;
  final int seriesCurrentIndex;
  final bool showAgeRestrictionChip;

  ComicDetailViewObject copyWith({
    String? title,
    int? seriesCurrentIndex,
    bool? showAgeRestrictionChip,
  }) {
    return ComicDetailViewObject(
      title: title ?? this.title,
      description: description,
      pageCount: pageCount,
      publishedLabel: publishedLabel,
      parodies: parodies,
      authors: authors,
      characters: characters,
      tags: tags,
      resourceFormat: resourceFormat,
      resourceSizeLabel: resourceSizeLabel,
      resourcePath: resourcePath,
      addedAtLabel: addedAtLabel,
      updatedAtLabel: updatedAtLabel,
      cover: cover,
      showSeriesNav: showSeriesNav,
      seriesCatalog: seriesCatalog,
      seriesCurrentIndex: seriesCurrentIndex ?? this.seriesCurrentIndex,
      showAgeRestrictionChip:
          showAgeRestrictionChip ?? this.showAgeRestrictionChip,
    );
  }
}
