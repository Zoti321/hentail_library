import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/widgets/inputs/md3e_named_facet_multi_select_copy.dart';
import 'package:hentai_library/features/library_browse/presentation/comic/views/widgets/form/named_facet_multi_select_field.dart';
import 'package:hentai_library/features/library_browse/presentation/comic/view_models/comic_metadata_smart_facet_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Parody 多选：字段内 chip + 内联输入；浮层列出未选字典项（对齐 Author/Tag）。
class ParodyLibraryMultiSelectField extends ConsumerWidget {
  const ParodyLibraryMultiSelectField({
    super.key,
    required this.label,
    required this.icon,
    required this.selectedNames,
    required this.onAdd,
    required this.onRemove,
    this.onClearAll,
    required this.scope,
    this.labelTrailing,
    this.compactTrigger = false,
  });

  final String label;
  final Widget? labelTrailing;
  final IconData icon;
  final List<String> selectedNames;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  final VoidCallback? onClearAll;
  final ComicMetadataSmartFacetScope scope;
  final bool compactTrigger;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return NamedFacetMultiSelectField(
      label: label,
      labelTrailing: labelTrailing,
      selectedNames: selectedNames,
      onAdd: onAdd,
      onRemove: onRemove,
      onClearAll: onClearAll,
      compactTrigger: compactTrigger,
      itemsProvider: parodiesSmartForComicMetadataFormProvider(scope),
      onRetry: () =>
          ref.invalidate(parodiesSmartForComicMetadataFormProvider(scope)),
      copy: Md3eNamedFacetMultiSelectCopy(
        listLoadFailed: l10n.formParodyListLoadFailed,
        emptyCatalog: l10n.formParodyEmptyCatalog,
        emptyRemaining: l10n.formParodyEmptyRemaining,
      ),
    );
  }
}
