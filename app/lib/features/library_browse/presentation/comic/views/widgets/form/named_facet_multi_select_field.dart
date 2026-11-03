import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_browse/domain/comic/smart_facet_match.dart';
import 'package:hentai_library/shared/ui/widgets/inputs/md3e_named_facet_multi_select_copy.dart';
import 'package:hentai_library/shared/ui/widgets/inputs/md3e_named_facet_multi_select_field.dart';
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
    required this.itemsProvider,
    required this.onRetry,
    required this.copy,
    this.labelTrailing,
    this.compactTrigger = false,
  });

  final String label;
  final Widget? labelTrailing;
  final List<String> selectedNames;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  final ProviderListenable<AsyncValue<List<SmartFacetMatchCandidate>>>
  itemsProvider;
  final VoidCallback onRetry;
  final Md3eNamedFacetMultiSelectCopy copy;
  final bool compactTrigger;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String tooltip = context.l10n.smartFacetMatchHintTooltip;
    return Md3eNamedFacetMultiSelectField<SmartFacetMatchCandidate>(
      label: label,
      selectedNames: selectedNames,
      onAdd: onAdd,
      onRemove: onRemove,
      itemsProvider: itemsProvider,
      onRetry: onRetry,
      resolveName: (SmartFacetMatchCandidate item) => item.name,
      resolveSmartMatched: (SmartFacetMatchCandidate item) => item.smartMatched,
      smartMatchedTooltip: tooltip,
      copy: copy,
      maxWidth: double.infinity,
    );
  }
}
