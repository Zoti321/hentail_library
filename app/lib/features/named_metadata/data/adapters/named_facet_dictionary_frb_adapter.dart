import 'package:hentai_library/shared/data/frb/frb_call_guard.dart';
import 'package:hentai_library/features/named_metadata/domain/named_facet_dictionary_repository.dart';
import 'package:hentai_library/src/rust/api/character.dart' as rust_character;
import 'package:hentai_library/src/rust/api/parody.dart' as rust_parody;

/// Parody / character 字典 FRB 薄封装。
class NamedFacetDictionaryFrbAdapter {
  const NamedFacetDictionaryFrbAdapter(this.kind);

  final NamedFacetKind kind;

  Future<List<String>> listAll() =>
      guardFrb(_listAllFrb, fallbackMessage: _listFallbackMessage);

  Future<List<String>> listDistinct({String? libraryId}) => guardFrb(
    () => _listDistinctFrb(libraryId),
    fallbackMessage: _listFallbackMessage,
  );

  String get _listFallbackMessage => switch (kind) {
    NamedFacetKind.parody => '读取原作列表失败',
    NamedFacetKind.character => '读取角色列表失败',
  };

  Future<List<String>> _listAllFrb() => switch (kind) {
    NamedFacetKind.parody => rust_parody.listAllParodiesFrb(),
    NamedFacetKind.character => rust_character.listAllCharactersFrb(),
  };

  Future<List<String>> _listDistinctFrb(String? libraryId) => switch (kind) {
    NamedFacetKind.parody => rust_parody.listDistinctParodiesFrb(
      libraryId: libraryId,
    ),
    NamedFacetKind.character => rust_character.listDistinctCharactersFrb(
      libraryId: libraryId,
    ),
  };
}
