import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/data/repositories/named_facet_form_listing.dart';
import 'package:hentai_library/domain/models/named_facet_form_candidate.dart';
import 'package:hentai_library/src/rust/api/named_facet.dart';
import 'package:hentai_library/ui/core/widgets/form/multi_select.dart';
import 'package:hentai_library/ui/core/widgets/form/named_facet_multi_select_field.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Name-ASC dictionary for management / non-form callers.
final allParodiesProvider =
    FutureProvider.autoDispose<List<String>>((Ref ref) {
  return ref.watch(parodyRepoProvider).listAll();
});

/// Snapshot of Parody candidates for Comic metadata form (attachment count order).
final parodiesForComicMetadataFormProvider =
    FutureProvider.autoDispose<List<NamedFacetFormCandidate>>((Ref ref) {
  return listNamedFacetForMetadataForm(JunctionNamedFacetFrb.parody);
});

/// Parody 多选：字段内 chip + 内联输入；浮层列出未选字典项（对齐 Author/Tag）。
class ParodyLibraryMultiSelectField extends ConsumerWidget {
  const ParodyLibraryMultiSelectField({
    super.key,
    required this.label,
    required this.icon,
    required this.selectedNames,
    required this.onAdd,
    required this.onRemove,
    this.labelTrailing,
    this.compactTrigger = false,
  });

  final String label;
  final Widget? labelTrailing;
  final IconData icon;
  final List<String> selectedNames;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  final bool compactTrigger;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return NamedFacetMultiSelectField(
      label: label,
      labelTrailing: labelTrailing,
      icon: icon,
      selectedNames: selectedNames,
      onAdd: onAdd,
      onRemove: onRemove,
      compactTrigger: compactTrigger,
      itemsProvider: parodiesForComicMetadataFormProvider,
      onRetry: () => ref.invalidate(parodiesForComicMetadataFormProvider),
      copy: MultiSelectCopy(
        inputPlaceholder: l10n.formParodySelectPlaceholder,
        listLoadFailed: l10n.formParodyListLoadFailed,
        emptyCatalog: l10n.formParodyEmptyCatalog,
        emptyRemaining: l10n.formParodyEmptyRemaining,
      ),
    );
  }
}
