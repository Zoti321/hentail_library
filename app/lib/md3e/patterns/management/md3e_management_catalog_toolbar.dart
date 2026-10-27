import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/patterns/management/md3e_management_named_facet.dart';
import 'package:hentai_library/md3e/widgets/selection/md3e_segmented_capsule_bar.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Body 顶行：左侧互斥胶囊维度 + 右侧当前维度数量（随列表滚动）。
class Md3eManagementCatalogToolbar extends StatelessWidget {
  const Md3eManagementCatalogToolbar({
    super.key,
    required this.facet,
    required this.facetCount,
    required this.onFacetChanged,
  });

  final Md3eManagementNamedFacet facet;
  final int facetCount;
  final ValueChanged<Md3eManagementNamedFacet> onFacetChanged;

  static String countLabel(Md3eManagementNamedFacet facet, int count) {
    return switch (facet) {
      Md3eManagementNamedFacet.authors => '$count 位作者',
      Md3eManagementNamedFacet.parodies => '$count 部原作',
      Md3eManagementNamedFacet.characters => '$count 位角色',
      Md3eManagementNamedFacet.tags => '$count 个标签',
    };
  }

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ETypeScale type = theme.typeScale;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Md3eSegmentedCapsuleBar(
            segments: Md3eManagementNamedFacet.capsuleSegments(),
            selectedIndex: Md3eManagementNamedFacet.indexOf(facet),
            onSelected: (int index) {
              onFacetChanged(Md3eManagementNamedFacet.facetAt(index));
            },
          ),
        ),
        const SizedBox(width: 12),
        Text(
          countLabel(facet, facetCount),
          style: type.labelLarge.copyWith(
            color: scheme.onSurfaceVariant,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
