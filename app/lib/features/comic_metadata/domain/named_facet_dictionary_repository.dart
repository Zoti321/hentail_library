/// Junction-backed named metadata facet without management-page CRUD.
///
/// [parody] / [character] share dictionary list + library-scoped distinct.
/// Tag / Author keep their own repositories. Language is a
/// closed-set JSON column, not a junction facet.
enum NamedFacetKind { parody, character }

/// Dictionary + attachment listing for a [NamedFacetKind].
abstract class NamedFacetDictionaryRepository {
  Future<List<String>> listAll();

  Future<List<String>> listDistinct({String? libraryId});
}
