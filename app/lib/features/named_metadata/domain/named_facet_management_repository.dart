import 'package:hentai_library/shared/domain/models/managed_named_facet_kind.dart';
export 'package:hentai_library/shared/domain/models/managed_named_facet_kind.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';

abstract class NamedFacetManagementRepository {
  Future<List<String>> listAll(ManagedNamedFacetKind kind);

  Future<PagedResult<String>> fetchPage(
    ManagedNamedFacetKind kind,
    PageRequest request,
  );

  Future<void> add(ManagedNamedFacetKind kind, String name);

  Future<void> deleteByNames(ManagedNamedFacetKind kind, List<String> names);

  Future<void> rename(
    ManagedNamedFacetKind kind,
    String oldName,
    String newName,
  );

  Future<void> merge(
    ManagedNamedFacetKind kind,
    String sourceName,
    String targetName,
  );

  Future<int> countAttachments(ManagedNamedFacetKind kind, String name);
}
