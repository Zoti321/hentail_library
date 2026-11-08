import 'package:hentai_library/features/named_metadata/domain/named_facet_form_candidate.dart';
import 'package:hentai_library/features/named_metadata/domain/named_facet_management_repository.dart';
import 'package:hentai_library/shared/domain/models/managed_named_facet_kind.dart';

/// Named metadata facet 管理写用例：新增 / 重命名 / 删除 / 合并（ADR-0033）。
///
/// 无 Flutter / Riverpod / FRB；列表查询与合并 UI 态仍由 ViewModel 持有。
class NamedFacetManagementService {
  const NamedFacetManagementService({
    required NamedFacetManagementRepository repository,
  }) : _repository = repository;

  final NamedFacetManagementRepository _repository;

  Future<void> add(ManagedNamedFacetKind kind, String name) async {
    final String? trimmed = _normalizedNameOrNull(name);
    if (trimmed == null) {
      return;
    }
    await _repository.add(kind, trimmed);
  }

  Future<void> rename(
    ManagedNamedFacetKind kind,
    String oldName,
    String newName,
  ) async {
    final String? trimmed = _normalizedNameOrNull(newName);
    if (trimmed == null || trimmed == oldName) {
      return;
    }
    await _repository.rename(kind, oldName, trimmed);
  }

  Future<void> delete(ManagedNamedFacetKind kind, String name) async {
    await _repository.deleteByNames(kind, <String>[name]);
  }

  /// 将来源名依次合并到 [targetName]（每源一次 repository.merge）。
  Future<void> merge({
    required ManagedNamedFacetKind kind,
    required String targetName,
    required List<String> sourceNames,
  }) async {
    for (final String sourceName in sourceNames) {
      if (sourceName == targetName) {
        continue;
      }
      await _repository.merge(kind, sourceName, targetName);
    }
  }

  Future<int> countAttachments(ManagedNamedFacetKind kind, String name) {
    return _repository.countAttachments(kind, name);
  }

  Future<Map<String, int>> countAttachmentsBatch(
    ManagedNamedFacetKind kind,
    List<String> names,
  ) {
    return _repository.countAttachmentsBatch(kind, names);
  }

  String? _normalizedNameOrNull(String name) {
    if (validateNamedFacetFormCandidateName(name) != null) {
      return null;
    }
    return name.trim();
  }
}
