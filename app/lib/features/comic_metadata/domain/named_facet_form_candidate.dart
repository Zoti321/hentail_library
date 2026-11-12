/// Junction Named metadata facet kind for Comic metadata form candidate listing.
enum NamedFacetFormKind { tag, author, parody, character }

/// Comic metadata form Named facet picker row (core owns sort).
typedef NamedFacetFormCandidate = ({String name, int attachmentCount});

NamedFacetFormCandidate namedFacetFormCandidate({
  required String name,
  required int attachmentCount,
}) => (name: name.trim(), attachmentCount: attachmentCount);

/// 表单候选名非空规约。
String? validateNamedFacetFormCandidateName(String name) {
  final String trimmed = name.trim();
  if (trimmed.isEmpty) {
    return '名称不能为空';
  }
  return null;
}
