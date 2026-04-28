import 'package:flutter/material.dart';
import 'package:hentai_library/model/entity/comic/author.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/form/multi_select.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const MultiSelectCopy _kAuthorMultiSelectCopy = MultiSelectCopy(
  selectPrompt: '选择作者…',
  listLoadFailed: '作者列表加载失败',
  filterHint: '筛选作者…',
  emptyCatalog: '暂无作者',
);

/// 全库作者多选：一行「作者 + 下拉」，触发条展示已选数量；浮层内可滚动列表。
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

  /// When true, shortens the dropdown trigger bar (e.g. metadata dialog).
  final bool compactTrigger;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      copy: _kAuthorMultiSelectCopy,
    );
  }
}
