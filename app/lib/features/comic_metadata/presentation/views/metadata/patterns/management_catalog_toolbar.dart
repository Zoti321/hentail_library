import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/comic_metadata/presentation/views/metadata/patterns/managed_named_facet_ui.dart';
import 'package:hentai_library/design-system/components/selection/segmented_capsule_bar.dart';
import 'package:hentai_library/features/comic_metadata/domain/named_facet_management_repository.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 元数据管理 Body 顶行：左侧互斥胶囊维度 + 右侧当前维度数量（生产与 Lab 共用）。
class ManagementCatalogToolbar extends StatelessWidget {
  const ManagementCatalogToolbar({
    super.key,
    required this.facet,
    required this.facetCount,
    required this.onFacetChanged,
  });

  final ManagedNamedFacetKind facet;
  final int facetCount;
  final ValueChanged<ManagedNamedFacetKind> onFacetChanged;

  void _handleSelected(int index) {
    onFacetChanged(ManagedNamedFacetUi.facetAt(index));
  }

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
          child: SegmentedCapsuleBar(
            segments: ManagedNamedFacetUi.capsuleSegments(l10n),
            selectedIndex: ManagedNamedFacetUi.indexOf(facet),
            onSelected: _handleSelected,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          ManagedNamedFacetUi.countLabel(l10n, facet, facetCount),
          style: type.labelLarge.copyWith(
            color: scheme.onSurfaceVariant,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
