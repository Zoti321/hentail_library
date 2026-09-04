import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/widgets/form/multi_select.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show ProviderListenable;

/// Shared multi-select chrome for string-named junction facets (Parody / Character).
class NamedFacetMultiSelectField extends ConsumerWidget {
  const NamedFacetMultiSelectField({
    super.key,
    required this.label,
    required this.icon,
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
  final IconData icon;
  final List<String> selectedNames;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  final ProviderListenable<AsyncValue<List<String>>> itemsProvider;
  final VoidCallback onRetry;
  final MultiSelectCopy copy;
  final bool compactTrigger;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MultiSelect<String>(
      label: label,
      labelTrailing: labelTrailing,
      icon: icon,
      selectedNames: selectedNames,
      onAdd: onAdd,
      onRemove: onRemove,
      compactTrigger: compactTrigger,
      itemsProvider: itemsProvider,
      onRetry: onRetry,
      resolveName: (String name) => name,
      copy: copy,
    );
  }
}
