import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/patterns/management/md3e_managed_named_facet_ui.dart';
import 'package:hentai_library/md3e/widgets/selection/md3e_segmented_capsule_bar.dart';
import 'package:hentai_library/shared/domain/repositories/named_facet_management_repository.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Body 顶行：左侧互斥胶囊维度 + 右侧当前维度数量（随列表滚动）。
class Md3eManagementCatalogToolbar extends StatelessWidget {
  const Md3eManagementCatalogToolbar({
    super.key,
    required this.facet,
    required this.facetCount,
    required this.onFacetChanged,
  });

  final ManagedNamedFacetKind facet;
  final int facetCount;
  final ValueChanged<ManagedNamedFacetKind> onFacetChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ETypeScale type = theme.typeScale;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Md3eSegmentedCapsuleBar(
            segments: Md3eManagedNamedFacetUi.capsuleSegments(l10n),
            selectedIndex: Md3eManagedNamedFacetUi.indexOf(facet),
            onSelected: (int index) {
              onFacetChanged(Md3eManagedNamedFacetUi.facetAt(index));
            },
          ),
        ),
        const SizedBox(width: 12),
        Text(
          Md3eManagedNamedFacetUi.countLabel(l10n, facet, facetCount),
          style: type.labelLarge.copyWith(
            color: scheme.onSurfaceVariant,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
