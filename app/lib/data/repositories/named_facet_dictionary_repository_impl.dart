import 'package:hentai_library/data/adapters/frb_call_guard.dart';
import 'package:hentai_library/domain/repositories/named_facet_dictionary_repository.dart';
import 'package:hentai_library/src/rust/api/character.dart' as rust_character;
import 'package:hentai_library/src/rust/api/parody.dart' as rust_parody;

class NamedFacetDictionaryRepositoryImpl
    implements NamedFacetDictionaryRepository {
  const NamedFacetDictionaryRepositoryImpl(this.kind);

  final NamedFacetKind kind;

  @override
  Future<List<String>> listAll() async {
    return guardFrbSync(_listAllFrb, fallbackMessage: _listFallbackMessage);
  }

  @override
  Future<List<String>> listDistinct({String? libraryId}) async {
    return guardFrbSync(
      () => _listDistinctFrb(libraryId),
      fallbackMessage: _listFallbackMessage,
    );
  }

  String get _listFallbackMessage => switch (kind) {
    NamedFacetKind.parody => '读取原作列表失败',
    NamedFacetKind.character => '读取角色列表失败',
  };

  List<String> _listAllFrb() => switch (kind) {
    NamedFacetKind.parody => rust_parody.listAllParodiesFrb(),
    NamedFacetKind.character => rust_character.listAllCharactersFrb(),
  };

  List<String> _listDistinctFrb(String? libraryId) => switch (kind) {
    NamedFacetKind.parody => rust_parody.listDistinctParodiesFrb(
      libraryId: libraryId,
    ),
    NamedFacetKind.character => rust_character.listDistinctCharactersFrb(
      libraryId: libraryId,
    ),
  };
}
