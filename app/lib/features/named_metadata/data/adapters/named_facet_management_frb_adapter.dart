import 'package:hentai_library/shared/data/frb/frb_call_guard.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/features/named_metadata/data/mappers/named_facet_frb_mapper.dart';
import 'package:hentai_library/features/named_metadata/domain/named_facet_management_repository.dart';
import 'package:hentai_library/src/rust/api/comic.dart' as rust_comic;
import 'package:hentai_library/src/rust/api/named_facet.dart'
    as rust_named_facet;

/// Named facet 管理页 FRB 薄封装（owner：`src/rust/api/named_facet.dart`）。
class NamedFacetManagementFrbAdapter {
  const NamedFacetManagementFrbAdapter();

  Future<List<String>> listAll(ManagedNamedFacetKind kind) => guardFrb(
    () => rust_named_facet.listAllNamedFacetNamesFrb(facet: kind.toFrb()),
    fallbackMessage: namedFacetFallbackCopyOf(kind).list,
  );

  Future<rust_named_facet.NamedFacetPagedNamesDto> fetchPage(
    ManagedNamedFacetKind kind,
    PageRequest request,
  ) => guardFrb(
    () => rust_named_facet.fetchNamedFacetPageFrb(
      facet: kind.toFrb(),
      request: rust_comic.PageRequestDto(
        page: request.page,
        pageSize: request.pageSize,
      ),
    ),
    fallbackMessage: namedFacetFallbackCopyOf(kind).page,
  );

  void add(ManagedNamedFacetKind kind, String name) {
    guardFrbSync(
      () => rust_named_facet.addNamedFacetNameFrb(
        facet: kind.toFrb(),
        name: name,
      ),
      fallbackMessage: namedFacetFallbackCopyOf(kind).add,
    );
  }

  void deleteByNames(ManagedNamedFacetKind kind, List<String> names) {
    guardFrbSync(
      () => rust_named_facet.deleteNamedFacetByNamesFrb(
        facet: kind.toFrb(),
        names: names,
      ),
      fallbackMessage: namedFacetFallbackCopyOf(kind).delete,
    );
  }

  void rename(ManagedNamedFacetKind kind, String oldName, String newName) {
    guardFrbSync(
      () => rust_named_facet.renameNamedFacetNameFrb(
        facet: kind.toFrb(),
        oldName: oldName,
        newName: newName,
      ),
      fallbackMessage: namedFacetFallbackCopyOf(kind).rename,
    );
  }

  void merge(ManagedNamedFacetKind kind, String sourceName, String targetName) {
    guardFrbSync(
      () => rust_named_facet.mergeNamedFacetNameFrb(
        facet: kind.toFrb(),
        sourceName: sourceName,
        targetName: targetName,
      ),
      fallbackMessage: namedFacetFallbackCopyOf(kind).merge,
    );
  }

  Future<int> countAttachments(ManagedNamedFacetKind kind, String name) async {
    final result = await guardFrb(
      () => rust_named_facet.countNamedFacetAttachmentsFrb(
        facet: kind.toFrb(),
        name: name,
      ),
      fallbackMessage: namedFacetFallbackCopyOf(kind).count,
    );
    return result.toInt();
  }
}
