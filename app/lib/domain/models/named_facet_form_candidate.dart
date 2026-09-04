/// Junction Named metadata facet kind for Comic metadata form candidate listing.
enum NamedFacetFormKind { tag, author, parody, character }

/// Comic metadata form Named facet picker row (core owns sort).
typedef NamedFacetFormCandidate = ({String name, int attachmentCount});

NamedFacetFormCandidate namedFacetFormCandidate({
  required String name,
  required int attachmentCount,
}) => (name: name, attachmentCount: attachmentCount);
