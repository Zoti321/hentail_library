part of 'dao.dart';

@DriftAccessor(tables: [Tags, ComicTags])
class TagDao extends DatabaseAccessor<AppDatabase> with _$TagDaoMixin {
  TagDao(super.db);

  Future<List<DbTag>> listAll() => select(tags).get();

  Future<void> addTag(String name) async {
    await into(
      tags,
    ).insert(TagsCompanion.insert(name: name), mode: InsertMode.insertOrIgnore);
  }

  Future<int> deleteByNames(List<String> names) {
    if (names.isEmpty) return Future<int>.value(0);
    return (delete(tags)..where((t) => t.name.isIn(names))).go();
  }

  Future<void> renameTag(String oldName, String newName) async {
    await transaction(() async {
      await into(tags).insert(
        TagsCompanion.insert(name: newName),
        mode: InsertMode.insertOrIgnore,
      );
      await (update(comicTags)..where((t) => t.tagName.equals(oldName))).write(
        ComicTagsCompanion(tagName: Value(newName)),
      );
      await (delete(tags)..where((t) => t.name.equals(oldName))).go();
    });
  }
}

@DriftAccessor(tables: [Authors, ComicAuthors])
class AuthorDao extends DatabaseAccessor<AppDatabase> with _$AuthorDaoMixin {
  AuthorDao(super.db);

  Future<List<DbAuthor>> listAll() => select(authors).get();

  Stream<List<DbAuthor>> watchAll() {
    return (select(authors)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  }

  Future<void> addAuthor(String name) async {
    await into(
      authors,
    ).insert(AuthorsCompanion.insert(name: name), mode: InsertMode.insertOrIgnore);
  }

  Future<int> deleteByNames(List<String> names) {
    if (names.isEmpty) return Future<int>.value(0);
    return (delete(authors)..where((t) => t.name.isIn(names))).go();
  }

  Future<void> renameAuthor(String oldName, String newName) async {
    await transaction(() async {
      await into(authors).insert(
        AuthorsCompanion.insert(name: newName),
        mode: InsertMode.insertOrIgnore,
      );
      await (update(comicAuthors)..where((t) => t.authorName.equals(oldName)))
          .write(ComicAuthorsCompanion(authorName: Value(newName)));
      await (delete(authors)..where((t) => t.name.equals(oldName))).go();
    });
  }
}
