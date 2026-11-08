import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/named_metadata/application/named_facet_management_service.dart';
import 'package:hentai_library/features/named_metadata/domain/named_facet_form_candidate.dart';
import 'package:hentai_library/features/named_metadata/domain/named_facet_management_repository.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';

class _RecordingRepo implements NamedFacetManagementRepository {
  final List<String> adds = <String>[];
  final List<(String, String)> renames = <(String, String)>[];
  final List<String> deletes = <String>[];
  final List<(String, String)> merges = <(String, String)>[];

  @override
  Future<void> add(ManagedNamedFacetKind kind, String name) async {
    adds.add(name);
  }

  @override
  Future<void> rename(
    ManagedNamedFacetKind kind,
    String oldName,
    String newName,
  ) async {
    renames.add((oldName, newName));
  }

  @override
  Future<void> deleteByNames(
    ManagedNamedFacetKind kind,
    List<String> names,
  ) async {
    deletes.addAll(names);
  }

  @override
  Future<void> merge(
    ManagedNamedFacetKind kind,
    String sourceName,
    String targetName,
  ) async {
    merges.add((sourceName, targetName));
  }

  @override
  Future<int> countAttachments(ManagedNamedFacetKind kind, String name) async {
    return 0;
  }

  @override
  Future<Map<String, int>> countAttachmentsBatch(
    ManagedNamedFacetKind kind,
    List<String> names,
  ) async {
    return <String, int>{for (final String name in names) name: 0};
  }

  @override
  Future<List<String>> listAll(ManagedNamedFacetKind kind) async =>
      const <String>[];

  @override
  Future<PagedResult<NamedFacetFormCandidate>> fetchPage(
    ManagedNamedFacetKind kind,
    PageRequest request,
  ) async {
    return PagedResult<NamedFacetFormCandidate>(
      items: const <NamedFacetFormCandidate>[],
      totalCount: 0,
      page: request.page,
      pageSize: request.pageSize,
    );
  }
}

void main() {
  late _RecordingRepo repo;
  late NamedFacetManagementService service;

  setUp(() {
    repo = _RecordingRepo();
    service = NamedFacetManagementService(repository: repo);
  });

  test('add trims and skips empty name', () async {
    await service.add(ManagedNamedFacetKind.tag, '  foo  ');
    await service.add(ManagedNamedFacetKind.tag, '   ');
    expect(repo.adds, <String>['foo']);
  });

  test('rename skips empty or unchanged', () async {
    await service.rename(ManagedNamedFacetKind.tag, 'a', 'b');
    await service.rename(ManagedNamedFacetKind.tag, 'a', 'a');
    await service.rename(ManagedNamedFacetKind.tag, 'a', '  ');
    expect(repo.renames, <(String, String)>[('a', 'b')]);
  });

  test('delete forwards single name', () async {
    await service.delete(ManagedNamedFacetKind.parody, 'x');
    expect(repo.deletes, <String>['x']);
  });

  test('merge skips self and applies each source', () async {
    await service.merge(
      kind: ManagedNamedFacetKind.tag,
      targetName: 'keep',
      sourceNames: <String>['a', 'keep', 'b'],
    );
    expect(repo.merges, <(String, String)>[('a', 'keep'), ('b', 'keep')]);
  });
}
