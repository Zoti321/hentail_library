import 'package:flutter/material.dart';
import 'package:hentai_library/domain/entity/comic/tag.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/form/multi_select.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const MultiSelectCopy _kTagMultiSelectCopy = MultiSelectCopy(
  selectPrompt: '选择标签…',
  listLoadFailed: '标签列表加载失败',
  filterHint: '筛选标签…',
  emptyCatalog: '暂无标签',
);

/// 全库标签多选：一行「标签 + 下拉」，触发条展示已选数量；浮层内可滚动列表。
class TagLibraryMultiSelectField extends ConsumerWidget {
  const TagLibraryMultiSelectField({
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
    return MultiSelect<Tag>(
      label: label,
      icon: icon,
      selectedNames: selectedNames,
      onAdd: onAdd,
      onRemove: onRemove,
      compactTrigger: compactTrigger,
      itemsProvider: allTagsProvider,
      onRetry: () => ref.invalidate(allTagsProvider),
      resolveName: (Tag tag) => tag.name,
      copy: _kTagMultiSelectCopy,
    );
  }
}
