import 'package:hentai_library/data/resources/local/database/dao.dart';
import 'package:hentai_library/data/resources/local/database/database.dart'
    as db;
import 'package:hentai_library/domain/entity/v2/library_comic.dart' as entity;
import 'package:hentai_library/domain/entity/v2/content_rating.dart' as entity;
import 'package:hentai_library/domain/entity/v2/library_tag.dart' as entity;
import 'package:hentai_library/domain/repository/v2/library_comic_repo.dart';
import 'package:drift/drift.dart';

class LibraryComicRepositoryImpl implements LibraryComicRepository {
  final LibraryComicDao _comicDao;

  LibraryComicRepositoryImpl(this._comicDao);

  Future<List<entity.LibraryComic>> _mapRows(
    List<db.LibraryComic> rows,
  ) async {
    final tagMap =
        await _comicDao.getTagNamesForComics(rows.map((e) => e.comicId));
    return rows
        .map((r) {
          final tagNames = tagMap[r.comicId] ?? const <String>[];
          return entity.LibraryComic(
            comicId: r.comicId,
            path: r.path,
            resourceType: r.resourceType,
            title: r.title,
            authors: r.authorsJson,
            contentRating: r.contentRating,
            tags: tagNames.map((n) => entity.LibraryTag(name: n)).toList(),
          );
        })
        .toList();
  }

  @override
  Stream<List<entity.LibraryComic>> watchAll() {
    return _comicDao.watchAllComics().asyncMap(_mapRows);
  }

  @override
  Future<List<entity.LibraryComic>> getAll() async {
    final rows = await _comicDao.getAllComics();
    return _mapRows(rows);
  }

  @override
  Future<entity.LibraryComic?> findById(String comicId) async {
    final row = await _comicDao.findById(comicId);
    if (row == null) return null;
    final tagNames = await _comicDao.getTagNamesForComic(comicId);
    return entity.LibraryComic(
      comicId: row.comicId,
      path: row.path,
      resourceType: row.resourceType,
      title: row.title,
      authors: row.authorsJson,
      contentRating: row.contentRating,
      tags: tagNames.map((n) => entity.LibraryTag(name: n)).toList(),
    );
  }

  @override
  Future<void> upsertMany(List<entity.LibraryComic> comics) async {
    final companions = comics
        .map(
          (c) => db.LibraryComicsCompanion.insert(
            comicId: c.comicId,
            path: c.path,
            resourceType: c.resourceType,
            title: c.title,
            authorsJson: Value(c.authors),
            contentRating: Value(c.contentRating),
          ),
        )
        .toList();

    await _comicDao.upsertMany(companions);

    // tags 单独写（每个 comic 替换其 tags）
    for (final c in comics) {
      await _comicDao.replaceComicTags(
        c.comicId,
        c.tags.map((t) => t.name).toList(),
      );
    }
  }

  @override
  Future<void> deleteByIds(List<String> comicIds) async {
    await _comicDao.deleteByIds(comicIds);
  }

  @override
  Future<void> updateUserMeta(
    String comicId, {
    String? title,
    List<String>? authors,
    entity.ContentRating? contentRating,
    List<entity.LibraryTag>? tags,
  }) async {
    await _comicDao.updateUserMeta(
      comicId,
      title: Value.absentIfNull(title),
      authors: authors == null ? const Value.absent() : Value(authors),
      contentRating: contentRating == null
          ? const Value.absent()
          : Value(contentRating),
    );
    if (tags != null) {
      await _comicDao.replaceComicTags(comicId, tags.map((e) => e.name).toList());
    }
  }

  @override
  Future<void> replaceByScan(List<entity.LibraryComic> scanned) async {
    // 简单实现：直接 upsertMany；后续再做真正 diff
    await upsertMany(scanned);
  }
}

