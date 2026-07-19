import 'package:flutter/material.dart';
import 'package:hentai_library/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/ui/core/widgets/form/multi_select.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const MultiSelectCopy _kTagMultiSelectCopy = MultiSelectCopy(
  inputPlaceholder: '选择或输入标签…',
  listLoadFailed: '标签列表加载失败',
  emptyCatalog: '暂无标签',
  emptyRemaining: '没有更多可选',
);

/// 全库标签多选：字段内 chip + 内联输入；浮层列出未选字典项。
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

  /// When true, shortens the field chrome (e.g. metadata dialog).
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
