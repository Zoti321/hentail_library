import 'package:hentai_library/features/comic_metadata/domain/named_facet_form_candidate.dart';
import 'package:hentai_library/features/comic_metadata/domain/managed_named_facet_kind.dart';
export 'package:hentai_library/features/comic_metadata/domain/managed_named_facet_kind.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';

abstract class NamedFacetManagementRepository {
  Future<List<String>> listAll(ManagedNamedFacetKind kind);

  /// Dictionary facets include real [NamedFacetFormCandidate.attachmentCount];
  /// Author rows use `0`.
  Future<PagedResult<NamedFacetFormCandidate>> fetchPage(
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

  /// Batch attachment counts (missing names → 0). Author returns all zeros.
  Future<Map<String, int>> countAttachmentsBatch(
    ManagedNamedFacetKind kind,
    List<String> names,
  );
}
