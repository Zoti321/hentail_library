import 'package:hentai_library/features/named_metadata/domain/named_facet_management_repository.dart';
import 'package:hentai_library/src/rust/api/named_facet/types.dart'
    as rust_named_facet;

extension ManagedNamedFacetKindFrb on ManagedNamedFacetKind {
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
