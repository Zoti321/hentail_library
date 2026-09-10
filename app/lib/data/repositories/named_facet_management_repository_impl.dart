import 'package:hentai_library/data/adapters/frb_call_guard.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/domain/repositories/named_facet_management_repository.dart';
import 'package:hentai_library/src/rust/api/comic.dart' as rust_comic;
import 'package:hentai_library/src/rust/api/named_facet.dart'
    as rust_named_facet;

class NamedFacetManagementRepositoryImpl
    implements NamedFacetManagementRepository {
  const NamedFacetManagementRepositoryImpl();

  @override
  Future<List<String>> listAll(ManagedNamedFacetKind kind) async {
    return guardFrbSync(
      () => rust_named_facet.listAllNamedFacetNamesFrb(facet: kind.toFrb()),
      fallbackMessage: _listFallbackMessage(kind),
    );
  }

  @override
  Future<PagedResult<String>> fetchPage(
    ManagedNamedFacetKind kind,
    PageRequest request,
  ) async {
    final rust_named_facet.NamedFacetPagedNamesDto page = guardFrbSync(
      () => rust_named_facet.fetchNamedFacetPageFrb(
        facet: kind.toFrb(),
        request: rust_comic.PageRequestDto(
          page: request.page,
          pageSize: request.pageSize,
        ),
      ),
      fallbackMessage: _pageFallbackMessage(kind),
    );
    return PagedResult<String>(
      items: page.items,
      totalCount: page.totalCount.toInt(),
      page: page.page,
      pageSize: page.pageSize,
    );
  }

  @override
  Future<void> add(ManagedNamedFacetKind kind, String name) async {
    guardFrbSync(
      () => rust_named_facet.addNamedFacetNameFrb(
        facet: kind.toFrb(),
        name: name,
      ),
      fallbackMessage: _addFallbackMessage(kind),
    );
  }

  @override
  Future<void> deleteByNames(
    ManagedNamedFacetKind kind,
    List<String> names,
  ) async {
    guardFrbSync(
      () => rust_named_facet.deleteNamedFacetByNamesFrb(
        facet: kind.toFrb(),
        names: names,
      ),
      fallbackMessage: _deleteFallbackMessage(kind),
    );
  }

  @override
  Future<void> rename(
    ManagedNamedFacetKind kind,
    String oldName,
    String newName,
  ) async {
    guardFrbSync(
      () => rust_named_facet.renameNamedFacetNameFrb(
        facet: kind.toFrb(),
        oldName: oldName,
        newName: newName,
      ),
      fallbackMessage: _renameFallbackMessage(kind),
    );
  }

  @override
  Future<int> countAttachments(ManagedNamedFacetKind kind, String name) async {
    final result = guardFrbSync(
      () => rust_named_facet.countNamedFacetAttachmentsFrb(
        facet: kind.toFrb(),
        name: name,
      ),
      fallbackMessage: _countFallbackMessage(kind),
    );
    return result.toInt();
  }
}

extension on ManagedNamedFacetKind {
  rust_named_facet.JunctionNamedFacetFrb toFrb() => switch (this) {
    ManagedNamedFacetKind.author =>
      rust_named_facet.JunctionNamedFacetFrb.author,
    ManagedNamedFacetKind.tag => rust_named_facet.JunctionNamedFacetFrb.tag,
    ManagedNamedFacetKind.parody =>
      rust_named_facet.JunctionNamedFacetFrb.parody,
    ManagedNamedFacetKind.character =>
      rust_named_facet.JunctionNamedFacetFrb.character,
  };
}

String _listFallbackMessage(ManagedNamedFacetKind kind) => switch (kind) {
  ManagedNamedFacetKind.author => '读取作者列表失败',
  ManagedNamedFacetKind.tag => '读取标签列表失败',
  ManagedNamedFacetKind.parody => '读取原作列表失败',
  ManagedNamedFacetKind.character => '读取角色列表失败',
};

String _pageFallbackMessage(ManagedNamedFacetKind kind) => switch (kind) {
  ManagedNamedFacetKind.author => '读取作者分页失败',
  ManagedNamedFacetKind.tag => '读取标签分页失败',
  ManagedNamedFacetKind.parody => '读取原作分页失败',
  ManagedNamedFacetKind.character => '读取角色分页失败',
};

String _addFallbackMessage(ManagedNamedFacetKind kind) => switch (kind) {
  ManagedNamedFacetKind.author => '添加作者失败',
  ManagedNamedFacetKind.tag => '添加标签失败',
  ManagedNamedFacetKind.parody => '添加原作失败',
  ManagedNamedFacetKind.character => '添加角色失败',
};

String _deleteFallbackMessage(ManagedNamedFacetKind kind) => switch (kind) {
  ManagedNamedFacetKind.author => '删除作者失败',
  ManagedNamedFacetKind.tag => '删除标签失败',
  ManagedNamedFacetKind.parody => '删除原作失败',
  ManagedNamedFacetKind.character => '删除角色失败',
};

String _renameFallbackMessage(ManagedNamedFacetKind kind) => switch (kind) {
  ManagedNamedFacetKind.author => '重命名作者失败',
  ManagedNamedFacetKind.tag => '重命名标签失败',
  ManagedNamedFacetKind.parody => '重命名原作失败',
  ManagedNamedFacetKind.character => '重命名角色失败',
};

String _countFallbackMessage(ManagedNamedFacetKind kind) => switch (kind) {
  ManagedNamedFacetKind.author => '读取作者 Named facet attachment count 失败',
  ManagedNamedFacetKind.tag => '读取标签 Named facet attachment count 失败',
  ManagedNamedFacetKind.parody => '读取原作 Named facet attachment count 失败',
  ManagedNamedFacetKind.character => '读取角色 Named facet attachment count 失败',
};
