import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/ui/core/widgets/form/multi_select.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 全库作者多选：字段内 chip + 内联输入；浮层列出未选字典项。
class AuthorLibraryMultiSelectField extends ConsumerWidget {
  const AuthorLibraryMultiSelectField({
    super.key,
    required this.label,
    required this.icon,
    required this.selectedNames,
    required this.onAdd,
    required this.onRemove,
    this.compactTrigger = false,
  });

  final String label;
  final IconData icon;
  final List<String> selectedNames;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  /// When true, shortens the field chrome (e.g. metadata dialog).
  final bool compactTrigger;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return MultiSelect<Author>(
      label: label,
      icon: icon,
      selectedNames: selectedNames,
      onAdd: onAdd,
      onRemove: onRemove,
      compactTrigger: compactTrigger,
      itemsProvider: allAuthorsProvider,
      onRetry: () => ref.invalidate(allAuthorsProvider),
      resolveName: (Author author) => author.name,
      copy: MultiSelectCopy(
        inputPlaceholder: l10n.formAuthorSelectPlaceholder,
        listLoadFailed: l10n.formAuthorListLoadFailed,
        emptyCatalog: l10n.formAuthorEmptyCatalog,
        emptyRemaining: l10n.formAuthorEmptyRemaining,
      ),
    );
  }
}
