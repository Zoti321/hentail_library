enum ManagedNamedFacetKind { author, tag, parody, character }

/// Metadata management UI tab order (authors → tags → parodies → characters).
const List<ManagedNamedFacetKind> kManagedNamedFacetTabOrder =
    <ManagedNamedFacetKind>[
      ManagedNamedFacetKind.author,
      ManagedNamedFacetKind.tag,
      ManagedNamedFacetKind.parody,
      ManagedNamedFacetKind.character,
    ];
