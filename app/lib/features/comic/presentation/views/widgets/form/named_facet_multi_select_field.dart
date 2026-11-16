import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/comic/domain/smart_facet_match.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show ProviderListenable;

/// Shared MD3E multi-select for Named metadata facets in Comic metadata form.
class NamedFacetMultiSelectField extends ConsumerWidget {
  const NamedFacetMultiSelectField({
    super.key,
    required this.label,
    required this.selectedNames,
    required this.onAdd,
    required this.onRemove,
    this.onClearAll,
    required this.itemsProvider,
    required this.onRetry,
    required this.copy,
  });

  final String label;
  final List<String> selectedNames;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  final VoidCallback? onClearAll;
  final ProviderListenable<AsyncValue<List<SmartFacetMatchCandidate>>>
  itemsProvider;
  final VoidCallback onRetry;
  final NamedFacetMultiSelectCopy copy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String tooltip = context.l10n.smartFacetMatchHintTooltip;
    final candidates = ref
        .watch(itemsProvider)
        .when(
          data: (items) => (items: items, loading: false, error: false),
          loading: () => (
            items: <SmartFacetMatchCandidate>[],
            loading: true,
            error: false,
          ),
          error: (_, _) => (
            items: <SmartFacetMatchCandidate>[],
            loading: false,
            error: true,
          ),
        );
    return FacetMultiSelectField<SmartFacetMatchCandidate>(
      label: label,
      selectedNames: selectedNames,
      onAdd: onAdd,
      onRemove: onRemove,
      onClearAll: onClearAll,
      items: candidates.items,
      isLoading: candidates.loading,
      hasLoadError: candidates.error,
      onRetry: onRetry,
      resolveName: (SmartFacetMatchCandidate item) => item.name,
      resolveSmartMatched: (SmartFacetMatchCandidate item) => item.smartMatched,
      smartMatchedTooltip: tooltip,
      copy: copy,
      maxWidth: double.infinity,
    );
  }
}
