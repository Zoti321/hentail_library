import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/md3e/widgets/selection/md3e_segmented_capsule_bar.dart';
import 'package:hentai_library/shared/domain/repositories/named_facet_management_repository.dart';

/// MD3E management toolbar helpers over [ManagedNamedFacetKind].
abstract final class Md3eManagedNamedFacetUi {
  static List<Md3eSegmentedCapsuleSegment> capsuleSegments(
    AppLocalizations l10n,
  ) {
    return kManagedNamedFacetTabOrder
        .map(
          (ManagedNamedFacetKind kind) => Md3eSegmentedCapsuleSegment(
            label: l10n.metadataTabLabel(kind),
          ),
        )
        .toList();
  }

  static int indexOf(ManagedNamedFacetKind kind) {
    return kManagedNamedFacetTabOrder.indexOf(kind);
  }

  static ManagedNamedFacetKind facetAt(int index) {
    return kManagedNamedFacetTabOrder[
        index.clamp(0, kManagedNamedFacetTabOrder.length - 1)];
  }

  static String countLabel(
    AppLocalizations l10n,
    ManagedNamedFacetKind kind,
    int count,
  ) {
    return l10n.managedNamedFacetCountLabel(kind, count);
  }
}
