import 'package:drift/drift.dart';
import 'package:hentai_library/domain/library/library_comic_filter.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/models/value_objects/library_tag_pick.dart';

/// [LibraryComicFilter] → SQL WHERE 条件（DAO 层单一映射）。
class ComicPageSqlCriteria {
  const ComicPageSqlCriteria({
    required this.showR18,
    this.query,
    this.resourceTypes,
    this.contentRatings,
    this.tagsAll = const <String>{},
    this.tagsAny = const <String>{},
    this.tagsExclude = const <String>{},
    this.excludeComicsInAnySeries = false,
  });

  final bool showR18;
  final String? query;
  final Set<ResourceType>? resourceTypes;
  final Set<ContentRating>? contentRatings;
  final Set<String> tagsAll;
  final Set<String> tagsAny;
  final Set<String> tagsExclude;
  final bool excludeComicsInAnySeries;

  factory ComicPageSqlCriteria.fromFilter(LibraryComicFilter filter) {
    return ComicPageSqlCriteria(
      showR18: filter.showR18,
      query: _normalizeQuery(filter.query),
      resourceTypes: filter.resourceTypes,
      contentRatings: filter.contentRatings,
      tagsAll: _normalizeTagPicks(filter.tagsAll),
      tagsAny: _normalizeTagPicks(filter.tagsAny),
      tagsExclude: _normalizeTagPicks(filter.tagsExclude),
      excludeComicsInAnySeries:
          filter.comicIdsExcludedBySeriesMembership != null,
    );
  }

  static String? _normalizeQuery(String? raw) {
    if (raw == null) {
      return null;
    }
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed.toLowerCase();
  }

  static Set<String> _normalizeTagPicks(Set<LibraryTagPick>? picks) {
    if (picks == null || picks.isEmpty) {
      return <String>{};
    }
    return picks
        .map((LibraryTagPick pick) => pick.name.trim().toLowerCase())
        .where((String name) => name.isNotEmpty)
        .toSet();
  }
}

class ComicPageSqlQuery {
  const ComicPageSqlQuery({required this.sql, required this.variables});

  final String sql;
  final List<Variable<Object>> variables;
}

class ComicPageSqlBuilder {
  static ComicPageSqlQuery buildCountQuery(ComicPageSqlCriteria criteria) {
    final List<Variable<Object>> variables = <Variable<Object>>[];
    final String whereClause = _buildWhereClause(criteria, variables);
    return ComicPageSqlQuery(
      sql: 'SELECT COUNT(*) AS c FROM comics c WHERE $whereClause',
      variables: variables,
    );
  }

  static ComicPageSqlQuery buildIdsPageQuery({
    required ComicPageSqlCriteria criteria,
    required bool sortDescending,
    required int limit,
    required int offset,
  }) {
    final List<Variable<Object>> variables = <Variable<Object>>[];
    final String whereClause = _buildWhereClause(criteria, variables);
    final String order = sortDescending ? 'DESC' : 'ASC';
    variables.add(Variable<Object>(limit));
    variables.add(Variable<Object>(offset));
    return ComicPageSqlQuery(
      sql:
          'SELECT c.comic_id AS comic_id FROM comics c '
          'WHERE $whereClause '
          'ORDER BY lower(c.title) $order '
          'LIMIT ? OFFSET ?',
      variables: variables,
    );
  }

  static String _buildWhereClause(
    ComicPageSqlCriteria criteria,
    List<Variable<Object>> variables,
  ) {
    final List<String> parts = <String>['1=1'];
    if (!criteria.showR18) {
      parts.add("c.content_rating != 'r18'");
    }
    if (criteria.query != null) {
      final String pattern = '%${criteria.query!}%';
      parts.add(
        '(lower(c.title) LIKE ? OR EXISTS ('
        'SELECT 1 FROM comic_authors ca '
        'WHERE ca.comic_id = c.comic_id AND lower(ca.author_name) LIKE ?))',
      );
      variables.add(Variable<Object>(pattern));
      variables.add(Variable<Object>(pattern));
    }
    if (criteria.resourceTypes != null && criteria.resourceTypes!.isNotEmpty) {
      final List<String> placeholders = List<String>.filled(
        criteria.resourceTypes!.length,
        '?',
      );
      parts.add('c.resource_type IN (${placeholders.join(',')})');
      for (final ResourceType type in criteria.resourceTypes!) {
        variables.add(Variable<Object>(type.name));
      }
    }
    if (criteria.contentRatings != null &&
        criteria.contentRatings!.isNotEmpty) {
      final List<String> placeholders = List<String>.filled(
        criteria.contentRatings!.length,
        '?',
      );
      parts.add('c.content_rating IN (${placeholders.join(',')})');
      for (final ContentRating rating in criteria.contentRatings!) {
        variables.add(Variable<Object>(rating.name));
      }
    }
    for (final String tag in criteria.tagsAll) {
      parts.add(
        'EXISTS (SELECT 1 FROM comic_tags ct '
        'WHERE ct.comic_id = c.comic_id AND lower(ct.tag_name) = ?)',
      );
      variables.add(Variable<Object>(tag));
    }
    if (criteria.tagsAny.isNotEmpty) {
      final List<String> placeholders = List<String>.filled(
        criteria.tagsAny.length,
        '?',
      );
      parts.add(
        'EXISTS (SELECT 1 FROM comic_tags ct '
        'WHERE ct.comic_id = c.comic_id AND lower(ct.tag_name) IN (${placeholders.join(',')}))',
      );
      for (final String tag in criteria.tagsAny) {
        variables.add(Variable<Object>(tag));
      }
    }
    if (criteria.tagsExclude.isNotEmpty) {
      final List<String> placeholders = List<String>.filled(
        criteria.tagsExclude.length,
        '?',
      );
      parts.add(
        'NOT EXISTS (SELECT 1 FROM comic_tags ct '
        'WHERE ct.comic_id = c.comic_id AND lower(ct.tag_name) IN (${placeholders.join(',')}))',
      );
      for (final String tag in criteria.tagsExclude) {
        variables.add(Variable<Object>(tag));
      }
    }
    if (criteria.excludeComicsInAnySeries) {
      parts.add(
        'NOT EXISTS (SELECT 1 FROM series_items si WHERE si.comic_id = c.comic_id)',
      );
    }
    return parts.join(' AND ');
  }
}
