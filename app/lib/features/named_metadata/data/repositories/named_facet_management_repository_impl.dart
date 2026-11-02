import 'package:hentai_library/shared/data/adapters/frb_call_guard.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/features/named_metadata/domain/named_facet_management_repository.dart';
import 'package:hentai_library/src/rust/api/comic.dart' as rust_comic;
import 'package:hentai_library/src/rust/api/named_facet.dart'
    as rust_named_facet;

class NamedFacetManagementRepositoryImpl
    implements NamedFacetManagementRepository {
  const NamedFacetManagementRepositoryImpl();

  @override
  Future<List<String>> listAll(ManagedNamedFacetKind kind) async {
    return guardFrb(
      () => rust_named_facet.listAllNamedFacetNamesFrb(facet: kind.toFrb()),
      fallbackMessage: namedFacetFallbackCopyOf(kind).list,
    );
  }

  @override
  Future<PagedResult<String>> fetchPage(
    ManagedNamedFacetKind kind,
    PageRequest request,
  ) async {
    final rust_named_facet.NamedFacetPagedNamesDto page = await guardFrb(
      () => rust_named_facet.fetchNamedFacetPageFrb(
        facet: kind.toFrb(),
        request: rust_comic.PageRequestDto(
          page: request.page,
          pageSize: request.pageSize,
        ),
      ),
      fallbackMessage: namedFacetFallbackCopyOf(kind).page,
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
      fallbackMessage: namedFacetFallbackCopyOf(kind).add,
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
      fallbackMessage: namedFacetFallbackCopyOf(kind).delete,
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
      fallbackMessage: namedFacetFallbackCopyOf(kind).rename,
    );
  }

  @override
  Future<void> merge(
    ManagedNamedFacetKind kind,
    String sourceName,
    String targetName,
  ) async {
    guardFrbSync(
      () => rust_named_facet.mergeNamedFacetNameFrb(
        facet: kind.toFrb(),
        sourceName: sourceName,
        targetName: targetName,
      ),
      fallbackMessage: namedFacetFallbackCopyOf(kind).merge,
    );
  }

  @override
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

/// 管理页 FRB 失败提示文案；每类 facet 的全部文案只在 [namedFacetFallbackCopyOf] 一处维护。
class NamedFacetFallbackCopy {
  const NamedFacetFallbackCopy({
    required this.list,
    required this.page,
    required this.add,
    required this.delete,
    required this.rename,
    required this.count,
    required this.merge,
  });

  final String list;
  final String page;
  final String add;
  final String delete;
  final String rename;
  final String count;
  final String merge;
}

NamedFacetFallbackCopy namedFacetFallbackCopyOf(ManagedNamedFacetKind kind) =>
    switch (kind) {
      ManagedNamedFacetKind.author => const NamedFacetFallbackCopy(
        list: '读取作者列表失败',
        page: '读取作者分页失败',
        add: '添加作者失败',
        delete: '删除作者失败',
        rename: '重命名作者失败',
        count: '读取作者 Named facet attachment count 失败',
        merge: '作者暂不支持合并',
      ),
      ManagedNamedFacetKind.tag => const NamedFacetFallbackCopy(
        list: '读取标签列表失败',
        page: '读取标签分页失败',
        add: '添加标签失败',
        delete: '删除标签失败',
        rename: '重命名标签失败',
        count: '读取标签 Named facet attachment count 失败',
        merge: '合并标签失败',
      ),
      ManagedNamedFacetKind.parody => const NamedFacetFallbackCopy(
        list: '读取原作列表失败',
        page: '读取原作分页失败',
        add: '添加原作失败',
        delete: '删除原作失败',
        rename: '重命名原作失败',
        count: '读取原作 Named facet attachment count 失败',
        merge: '合并原作失败',
      ),
      ManagedNamedFacetKind.character => const NamedFacetFallbackCopy(
        list: '读取角色列表失败',
        page: '读取角色分页失败',
        add: '添加角色失败',
        delete: '删除角色失败',
        rename: '重命名角色失败',
        count: '读取角色 Named facet attachment count 失败',
        merge: '合并角色失败',
      ),
    };
