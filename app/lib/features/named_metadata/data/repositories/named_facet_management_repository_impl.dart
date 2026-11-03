import 'package:hentai_library/features/named_metadata/data/adapters/named_facet_management_frb_adapter.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/features/named_metadata/domain/named_facet_management_repository.dart';

class NamedFacetManagementRepositoryImpl
    implements NamedFacetManagementRepository {
  const NamedFacetManagementRepositoryImpl({
    NamedFacetManagementFrbAdapter? adapter,
  }) : _adapter = adapter ?? const NamedFacetManagementFrbAdapter();

  final NamedFacetManagementFrbAdapter _adapter;

  @override
  Future<List<String>> listAll(ManagedNamedFacetKind kind) =>
      _adapter.listAll(kind);

  @override
  Future<PagedResult<String>> fetchPage(
    ManagedNamedFacetKind kind,
    PageRequest request,
  ) async {
    final page = await _adapter.fetchPage(kind, request);
    return PagedResult<String>(
      items: page.items,
      totalCount: page.totalCount.toInt(),
      page: page.page,
      pageSize: page.pageSize,
    );
  }

  @override
  Future<void> add(ManagedNamedFacetKind kind, String name) async {
    _adapter.add(kind, name);
  }

  @override
  Future<void> deleteByNames(
    ManagedNamedFacetKind kind,
    List<String> names,
  ) async {
    _adapter.deleteByNames(kind, names);
  }

  @override
  Future<void> rename(
    ManagedNamedFacetKind kind,
    String oldName,
    String newName,
  ) async {
    _adapter.rename(kind, oldName, newName);
  }

  @override
  Future<void> merge(
    ManagedNamedFacetKind kind,
    String sourceName,
    String targetName,
  ) async {
    _adapter.merge(kind, sourceName, targetName);
  }

  @override
  Future<int> countAttachments(ManagedNamedFacetKind kind, String name) =>
      _adapter.countAttachments(kind, name);
}
