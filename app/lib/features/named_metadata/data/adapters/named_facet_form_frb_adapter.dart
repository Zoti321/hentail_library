import 'package:hentai_library/features/named_metadata/data/adapters/named_facet_form_frb_adapter.dart';
import 'package:hentai_library/features/named_metadata/domain/named_facet_form_candidate.dart';
import 'package:hentai_library/shared/data/frb/frb_call_guard.dart';
import 'package:hentai_library/src/rust/api/named_facet/form.dart' as rust;
import 'package:hentai_library/src/rust/api/named_facet/types.dart'
    as rust_types;

/// Comic metadata form 候选列表 FRB 薄封装。
class NamedFacetFormFrbAdapter {
  const NamedFacetFormFrbAdapter();

  Future<List<rust_types.NamedFacetFormEntryFrbDto>> listForForm(
    NamedFacetFormKind facet,
  ) => guardFrb(
    () => rust.listNamedFacetForFormFrb(facet: facet.toJunctionFrb()),
    fallbackMessage: _fallbackMessage(facet),
  );
}

extension NamedFacetFormKindJunctionFrb on NamedFacetFormKind {
  rust_types.JunctionNamedFacetFrb toJunctionFrb() => switch (this) {
    NamedFacetFormKind.tag => rust_types.JunctionNamedFacetFrb.tag,
    NamedFacetFormKind.author => rust_types.JunctionNamedFacetFrb.author,
    NamedFacetFormKind.parody => rust_types.JunctionNamedFacetFrb.parody,
    NamedFacetFormKind.character => rust_types.JunctionNamedFacetFrb.character,
  };
}

String _fallbackMessage(NamedFacetFormKind facet) => switch (facet) {
  NamedFacetFormKind.tag => '读取标签列表失败',
  NamedFacetFormKind.author => '读取作者列表失败',
  NamedFacetFormKind.parody => '读取原作列表失败',
  NamedFacetFormKind.character => '读取角色列表失败',
};
