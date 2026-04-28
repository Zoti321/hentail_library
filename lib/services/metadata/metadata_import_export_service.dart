import 'dart:convert';
import 'dart:io';

import 'package:hentai_library/model/entity/comic/author.dart';
import 'package:hentai_library/model/entity/comic/comic.dart';
import 'package:hentai_library/model/entity/comic/series.dart';
import 'package:hentai_library/model/entity/comic/series_item.dart';
import 'package:hentai_library/model/entity/comic/tag.dart';
import 'package:hentai_library/repository/author_repository.dart';
import 'package:hentai_library/repository/comic_repository.dart';
import 'package:hentai_library/repository/series_repository.dart';
import 'package:hentai_library/repository/tag_repository.dart';
import 'package:hentai_library/services/metadata/metadata_io_exception.dart';
import 'package:hentai_library/services/metadata/metadata_io_models.dart';

abstract class MetadataImportExportService {
  Future<MetadataImportReport> importFromJsonFile(String jsonFilePath);

  Future<String> exportToJsonFile({required String targetFilePath});
}

class DefaultMetadataImportExportService
    implements MetadataImportExportService {
  DefaultMetadataImportExportService({
    required AuthorRepository authorRepository,
    required TagRepository tagRepository,
    required SeriesRepository seriesRepository,
    required ComicRepository comicRepository,
  }) : _authorRepository = authorRepository,
       _tagRepository = tagRepository,
       _seriesRepository = seriesRepository,
       _comicRepository = comicRepository;

  final AuthorRepository _authorRepository;
  final TagRepository _tagRepository;
  final SeriesRepository _seriesRepository;
  final ComicRepository _comicRepository;

  @override
  Future<MetadataImportReport> importFromJsonFile(String jsonFilePath) async {
    try {
      final String rawJson = await File(jsonFilePath).readAsString();
      final MetadataIoPayload payload = _parsePayload(rawJson);
      final ({int added, int skipped}) authorStats = await _importAuthors(
        payload.authors,
      );
      final ({int added, int skipped}) tagStats = await _importTags(payload.tags);
      final ({
        int addedSeries,
        int skippedSeries,
        int writtenItems,
        int skippedMissingComic,
        int skippedOccupied,
        int skippedOrderConflict,
      }) seriesStats = await _importSeries(payload.series);
      return MetadataImportReport(
        addedAuthors: authorStats.added,
        skippedAuthors: authorStats.skipped,
        addedTags: tagStats.added,
        skippedTags: tagStats.skipped,
        addedSeries: seriesStats.addedSeries,
        skippedSeries: seriesStats.skippedSeries,
        writtenSeriesItems: seriesStats.writtenItems,
        skippedSeriesItemsMissingComic: seriesStats.skippedMissingComic,
        skippedSeriesItemsOccupied: seriesStats.skippedOccupied,
        skippedSeriesItemsOrderConflict: seriesStats.skippedOrderConflict,
      );
    } on FormatException catch (error, stackTrace) {
      throw MetadataIoFormatException(
        '元数据文件格式不符合要求',
        cause: error,
        stackTrace: stackTrace,
      );
    } on MetadataIoFormatException {
      rethrow;
    } on MetadataImportException {
      rethrow;
    } catch (error, stackTrace) {
      throw MetadataImportException(
        '导入元数据失败',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<String> exportToJsonFile({required String targetFilePath}) async {
    try {
      final MetadataIoPayload payload = await _buildExportPayload();
      final File outputFile = File(targetFilePath);
      final String encoded = const JsonEncoder.withIndent(
        '  ',
      ).convert(payload.toJson());
      await outputFile.writeAsString(encoded, flush: true);
      return outputFile.path;
    } on MetadataExportException {
      rethrow;
    } catch (error, stackTrace) {
      throw MetadataExportException(
        '导出元数据失败',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<MetadataIoPayload> _buildExportPayload() async {
    final List<Comic> comics = await _comicRepository.getAll();
    final Map<String, Comic> comicsById = <String, Comic>{
      for (final Comic comic in comics) comic.comicId: comic,
    };
    final List<String> authors = (await _authorRepository.listAll())
        .map((author) => author.name)
        .toList();
    final List<String> tags = (await _tagRepository.listAll())
        .map((tag) => tag.name)
        .toList();
    final List<Series> seriesList = await _seriesRepository.getAll();
    final List<MetadataIoSeries> series = <MetadataIoSeries>[];
    for (final Series currentSeries in seriesList) {
      final List<MetadataIoSeriesItem> items = <MetadataIoSeriesItem>[];
      for (final SeriesItem item in currentSeries.items) {
        final Comic? comic = comicsById[item.comicId];
        if (comic == null) {
          continue;
        }
        items.add(
          MetadataIoSeriesItem(comicTitle: comic.title, order: item.order),
        );
      }
      series.add(MetadataIoSeries(name: currentSeries.name, items: items));
    }
    return MetadataIoPayload(authors: authors, tags: tags, series: series);
  }

  Future<({int added, int skipped})> _importAuthors(List<String> authors) async {
    final Set<String> existing = (await _authorRepository.listAll())
        .map((item) => item.name.trim())
        .where((item) => item.isNotEmpty)
        .toSet();
    int added = 0;
    int skipped = 0;
    for (final String name in authors.map((value) => value.trim())) {
      if (name.isEmpty || existing.contains(name)) {
        skipped++;
        continue;
      }
      await _authorRepository.add(Author(name: name));
      existing.add(name);
      added++;
    }
    return (added: added, skipped: skipped);
  }

  Future<({int added, int skipped})> _importTags(List<String> tags) async {
    final Set<String> existing = (await _tagRepository.listAll())
        .map((item) => item.name.trim())
        .where((item) => item.isNotEmpty)
        .toSet();
    int added = 0;
    int skipped = 0;
    for (final String name in tags.map((value) => value.trim())) {
      if (name.isEmpty || existing.contains(name)) {
        skipped++;
        continue;
      }
      await _tagRepository.add(Tag(name: name));
      existing.add(name);
      added++;
    }
    return (added: added, skipped: skipped);
  }

  Future<
    ({
      int addedSeries,
      int skippedSeries,
      int writtenItems,
      int skippedMissingComic,
      int skippedOccupied,
      int skippedOrderConflict,
    })
  >
  _importSeries(List<MetadataIoSeries> series) async {
    final List<Series> existingSeriesList = await _seriesRepository.getAll();
    final Set<String> existingSeriesNames = existingSeriesList
        .map((item) => item.name.trim())
        .where((item) => item.isNotEmpty)
        .toSet();
    int addedSeries = 0;
    int skippedSeries = 0;
    int writtenItems = 0;
    int skippedMissingComic = 0;
    int skippedOccupied = 0;
    int skippedOrderConflict = 0;
    for (final MetadataIoSeries currentSeries in series) {
      final String seriesName = currentSeries.name.trim();
      if (seriesName.isEmpty) {
        skippedSeries++;
        continue;
      }
      if (!existingSeriesNames.contains(seriesName)) {
        await _seriesRepository.create(seriesName);
        existingSeriesNames.add(seriesName);
        addedSeries++;
      } else {
        skippedSeries++;
      }
    }
    final List<Comic> allComics = await _comicRepository.getAll();
    final Map<String, Comic> comicsByNormalizedTitle = <String, Comic>{};
    for (final Comic comic in allComics) {
      final String normalizedTitle = _normalizeTitle(comic.title);
      comicsByNormalizedTitle.putIfAbsent(normalizedTitle, () => comic);
    }
    final List<Series> latestSeries = await _seriesRepository.getAll();
    final Map<String, Series> seriesByName = <String, Series>{
      for (final Series currentSeries in latestSeries)
        currentSeries.name: currentSeries,
    };
    final Set<String> occupiedComicIds = <String>{};
    for (final Series currentSeries in latestSeries) {
      for (final SeriesItem item in currentSeries.items) {
        occupiedComicIds.add(item.comicId);
      }
    }
    for (final MetadataIoSeries currentSeries in series) {
      final Series? targetSeries = seriesByName[currentSeries.name];
      if (targetSeries == null) {
        continue;
      }
      final Map<String, int> existingOrderByComicId = <String, int>{
        for (final SeriesItem item in targetSeries.items)
          item.comicId: item.order,
      };
      final List<MetadataIoSeriesItem> deduplicated = _dedupeByComicTitle(
        currentSeries.items,
      );
      deduplicated.sort((a, b) => a.order.compareTo(b.order));
      for (final MetadataIoSeriesItem seriesItem in deduplicated) {
        final Comic? matchedComic =
            comicsByNormalizedTitle[_normalizeTitle(seriesItem.comicTitle)];
        if (matchedComic == null) {
          skippedMissingComic++;
          continue;
        }
        final int? existingOrder = existingOrderByComicId[matchedComic.comicId];
        if (existingOrder != null) {
          skippedOrderConflict++;
          continue;
        }
        if (occupiedComicIds.contains(matchedComic.comicId)) {
          skippedOccupied++;
          continue;
        }
        await _seriesRepository.assignComicExclusive(
          comicId: matchedComic.comicId,
          targetSeriesName: targetSeries.name,
          order: seriesItem.order,
        );
        occupiedComicIds.add(matchedComic.comicId);
        writtenItems++;
      }
    }
    return (
      addedSeries: addedSeries,
      skippedSeries: skippedSeries,
      writtenItems: writtenItems,
      skippedMissingComic: skippedMissingComic,
      skippedOccupied: skippedOccupied,
      skippedOrderConflict: skippedOrderConflict,
    );
  }

  MetadataIoPayload _parsePayload(String rawJson) {
    final Object? decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw MetadataIoFormatException('元数据文件格式不符合要求');
    }
    final List<String> authors = _readStringList(decoded, key: 'authors');
    final List<String> tags = _readStringList(decoded, key: 'tags');
    final List<dynamic> rawSeries = _readDynamicList(decoded, key: 'series');
    final List<MetadataIoSeries> series = rawSeries.map((dynamic row) {
      if (row is! Map<String, dynamic>) {
        throw MetadataIoFormatException('series 项格式不符合要求');
      }
      final Object? rawName = row['name'];
      if (rawName is! String || rawName.trim().isEmpty) {
        throw MetadataIoFormatException('series.name 格式不符合要求');
      }
      final List<dynamic> rawItems = _readDynamicList(row, key: 'items');
      final List<MetadataIoSeriesItem> items = rawItems.map((dynamic itemRow) {
        if (itemRow is! Map<String, dynamic>) {
          throw MetadataIoFormatException('series.items 项格式不符合要求');
        }
        final Object? rawTitle = itemRow['comicTitle'];
        final Object? rawOrder = itemRow['order'];
        if (rawTitle is! String || rawTitle.trim().isEmpty) {
          throw MetadataIoFormatException('series.items.comicTitle 格式不符合要求');
        }
        if (rawOrder is! int) {
          throw MetadataIoFormatException('series.items.order 格式不符合要求');
        }
        return MetadataIoSeriesItem(
          comicTitle: rawTitle.trim(),
          order: rawOrder,
        );
      }).toList();
      return MetadataIoSeries(name: rawName.trim(), items: items);
    }).toList();
    return MetadataIoPayload(authors: authors, tags: tags, series: series);
  }

  List<String> _readStringList(
    Map<String, dynamic> root, {
    required String key,
  }) {
    final List<dynamic> values = _readDynamicList(root, key: key);
    final List<String> parsed = <String>[];
    for (final dynamic value in values) {
      if (value is! String) {
        throw MetadataIoFormatException('$key 格式不符合要求');
      }
      final String normalized = value.trim();
      if (normalized.isEmpty) {
        continue;
      }
      parsed.add(normalized);
    }
    return parsed;
  }

  List<dynamic> _readDynamicList(
    Map<String, dynamic> root, {
    required String key,
  }) {
    final Object? value = root[key];
    if (value is! List<dynamic>) {
      throw MetadataIoFormatException('$key 格式不符合要求');
    }
    return value;
  }

  List<MetadataIoSeriesItem> _dedupeByComicTitle(
    List<MetadataIoSeriesItem> items,
  ) {
    final Map<String, MetadataIoSeriesItem> unique =
        <String, MetadataIoSeriesItem>{};
    for (final MetadataIoSeriesItem item in items) {
      final String title = _normalizeTitle(item.comicTitle);
      unique.putIfAbsent(title, () => item);
    }
    return unique.values.toList();
  }

  String _normalizeTitle(String title) {
    return title.trim().toLowerCase();
  }
}
