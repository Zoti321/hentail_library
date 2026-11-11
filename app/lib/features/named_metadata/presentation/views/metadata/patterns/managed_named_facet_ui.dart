import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/shared/ui/widgets/selection/segmented_capsule_bar.dart';
import 'package:hentai_library/features/named_metadata/domain/named_facet_management_repository.dart';
import 'package:hentai_library/features/named_metadata/public/ui/l10n/named_metadata_l10n.dart';

/// MD3E management toolbar helpers over [ManagedNamedFacetKind].
abstract final class ManagedNamedFacetUi {
  static List<SegmentedCapsuleSegment> capsuleSegments(AppLocalizations l10n) {
    return kManagedNamedFacetTabOrder
        .map(
          (ManagedNamedFacetKind kind) =>
              SegmentedCapsuleSegment(label: l10n.metadataTabLabel(kind)),
        )
        .toList();
  }

  static int indexOf(ManagedNamedFacetKind kind) {
    return kManagedNamedFacetTabOrder.indexOf(kind);
  }

  static ManagedNamedFacetKind facetAt(int index) {
    return kManagedNamedFacetTabOrder[index.clamp(
      0,
      kManagedNamedFacetTabOrder.length - 1,
    )];
  }

  static String countLabel(
    AppLocalizations l10n,
    ManagedNamedFacetKind kind,
    int count,
  ) {
    return l10n.managedNamedFacetCountLabel(kind, count);
  }
}
