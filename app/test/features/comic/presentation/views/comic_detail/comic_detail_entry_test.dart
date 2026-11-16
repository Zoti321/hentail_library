import 'package:hentai_library/features/comic/public/comic_metadata_types.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/shared/domain/models/value_objects/author_ref.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/comic/presentation/views/comic_detail/comic_detail_entry.dart';
import 'package:hentai_library/features/comic/domain/comic.dart';
import 'package:hentai_library/features/comic_metadata/public/comic_metadata_entities.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';

Comic _comic({
  ContentRating contentRating = ContentRating.safe,
  int pageCount = 24,
}) {
  return Comic.restore(
    comicId: 'c1',
    path: r'D:\lib\c1.zip',
    resourceType: ResourceType.zip,
    resourceSize: 2048,
    createdAt: DateTime.utc(2026, 1, 2),
    lastUpdatedAt: DateTime.utc(2026, 1, 3),
    title: '示例漫画',
    pageCount: pageCount,
    description: '简介',
    authors: <AuthorRef>[AuthorRef(id: 7, name: '作者甲')],
    tags: <Tag>[Tag(name: 'tag-a')],
    parodies: <String>['原作'],
    characters: <String>['角色'],
    contentRating: contentRating,
  );
}

void main() {
  group('comicDetailEntry', () {
    test('maps domain fields to Lab entry', () {
      final entry = comicDetailEntry(
        comic: _comic(),
        cover: const SizedBox(),
        pageCount: 24,
        publishedLabel: '2026年1月1日',
        addedAtLabel: 'added',
        updatedAtLabel: 'updated',
        seriesTitles: const <String>['第一话', '第二话'],
        seriesCurrentIndex: 1,
        showSeriesNav: true,
      );

      expect(entry.title, '示例漫画');
      expect(entry.description, '简介');
      expect(entry.pageCount, 24);
      expect(entry.authors, <AuthorRef>[AuthorRef(id: 7, name: '作者甲')]);
      expect(entry.tags, <String>['tag-a']);
      expect(entry.parodies, <String>['原作']);
      expect(entry.characters, <String>['角色']);
      expect(entry.resourceFormat, 'ZIP');
      expect(entry.resourceSizeLabel, '2.0 KB');
      expect(entry.resourcePath, r'D:\lib\c1.zip');
      expect(entry.seriesCatalog, <String>['第一话', '第二话']);
      expect(entry.seriesCurrentIndex, 1);
      expect(entry.showSeriesNav, isTrue);
      expect(entry.showAgeRestrictionChip, isFalse);
    });

    test('treats zero page count as unknown', () {
      final entry = comicDetailEntry(
        comic: _comic(pageCount: 0),
        cover: const SizedBox(),
        pageCount: 0,
        publishedLabel: null,
        addedAtLabel: null,
        updatedAtLabel: null,
        seriesTitles: const <String>[],
        seriesCurrentIndex: 0,
        showSeriesNav: false,
      );

      expect(entry.pageCount, isNull);
      expect(entry.showSeriesNav, isFalse);
    });

    test('shows age restriction chip only for r18 content', () {
      final entry = comicDetailEntry(
        comic: _comic(contentRating: ContentRating.r18),
        cover: const SizedBox(),
        pageCount: null,
        publishedLabel: null,
        addedAtLabel: null,
        updatedAtLabel: null,
        seriesTitles: const <String>[],
        seriesCurrentIndex: 0,
        showSeriesNav: false,
      );

      expect(entry.showAgeRestrictionChip, isTrue);
    });
  });
}
