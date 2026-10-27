import 'package:hentai_library/md3e/widgets/selection/md3e_segmented_capsule_bar.dart';

/// Named-metadata facet switcher on the MD3E management page (Lab).
enum Md3eManagementNamedFacet {
  authors,
  parodies,
  characters,
  tags;

  String get label => switch (this) {
    Md3eManagementNamedFacet.authors => '作者',
    Md3eManagementNamedFacet.parodies => '原作',
    Md3eManagementNamedFacet.characters => '角色',
    Md3eManagementNamedFacet.tags => '标签',
  };

  static const List<Md3eManagementNamedFacet> managementOrder =
      <Md3eManagementNamedFacet>[
        Md3eManagementNamedFacet.authors,
        Md3eManagementNamedFacet.parodies,
        Md3eManagementNamedFacet.characters,
        Md3eManagementNamedFacet.tags,
      ];

  static List<Md3eSegmentedCapsuleSegment> capsuleSegments() {
    return managementOrder
        .map(
          (Md3eManagementNamedFacet facet) =>
              Md3eSegmentedCapsuleSegment(label: facet.label),
        )
        .toList();
  }

  static int indexOf(Md3eManagementNamedFacet facet) {
    return managementOrder.indexOf(facet);
  }

  static Md3eManagementNamedFacet facetAt(int index) {
    return managementOrder[index.clamp(0, managementOrder.length - 1)];
  }
}
