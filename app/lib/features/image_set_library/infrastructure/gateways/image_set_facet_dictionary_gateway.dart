import 'package:hentai_library/features/image_set_library/domain/image_set_named_facet_kind.dart';
import 'package:hentai_library/infrastructure/frb/frb_call_guard.dart';
import 'package:hentai_library/src/rust/api/author.dart' as author_rust;
import 'package:hentai_library/src/rust/api/named_facet/management.dart'
    as facet_rust;
import 'package:hentai_library/src/rust/api/named_facet/types.dart'
    as facet_types;
import 'package:hentai_library/src/rust/api/named_facet_dictionary.dart'
    as dictionary_rust;

/// Image set 表单 facet 字典读取（FRB 直调；不经过 Comic metadata 写用例）。
class ImageSetFacetDictionaryGateway {
  const ImageSetFacetDictionaryGateway();

  Future<List<String>> listAll(ImageSetNamedFacetKind kind) => guardFrb(
    () => _listAll(kind),
    fallbackMessage: _fallbackMessage(kind),
  );

  String _fallbackMessage(ImageSetNamedFacetKind kind) => switch (kind) {
    ImageSetNamedFacetKind.author => '读取作者列表失败',
    ImageSetNamedFacetKind.tag => '读取标签列表失败',
    ImageSetNamedFacetKind.parody => '读取原作列表失败',
    ImageSetNamedFacetKind.character => '读取角色列表失败',
  };

  Future<List<String>> _listAll(ImageSetNamedFacetKind kind) async {
    switch (kind) {
      case ImageSetNamedFacetKind.author:
        final List<author_rust.AuthorIdentityFrbDto> authors =
            await author_rust.listAllAuthorsFrb();
        return authors.map((author_rust.AuthorIdentityFrbDto a) => a.name).toList()
          ..sort();
      case ImageSetNamedFacetKind.tag:
        return facet_rust.listAllNamedFacetNamesFrb(
          facet: facet_types.JunctionNamedFacetFrb.tag,
        );
      case ImageSetNamedFacetKind.parody:
        return dictionary_rust.listAllParodiesFrb();
      case ImageSetNamedFacetKind.character:
        return dictionary_rust.listAllCharactersFrb();
    }
  }
}