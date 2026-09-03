import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/data/adapters/frb_call_guard.dart';
import 'package:hentai_library/src/rust/api/character.dart' as rust_character;
import 'package:hentai_library/ui/core/widgets/form/multi_select.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 全局 Character 名字典（无独立管理页；由 Comic 附着写入填充）。
final allCharactersProvider =
    FutureProvider.autoDispose<List<String>>((Ref ref) async {
  return guardFrbSync(
    rust_character.listAllCharactersFrb,
    fallbackMessage: '读取角色列表失败',
  );
});

/// Character 多选：字段内 chip + 内联输入；浮层列出未选字典项（对齐 Author/Tag/Parody）。
class CharacterLibraryMultiSelectField extends ConsumerWidget {
  const CharacterLibraryMultiSelectField({
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
    return MultiSelect<String>(
      label: label,
      labelTrailing: labelTrailing,
      icon: icon,
      selectedNames: selectedNames,
      onAdd: onAdd,
      onRemove: onRemove,
      compactTrigger: compactTrigger,
      itemsProvider: allCharactersProvider,
      onRetry: () => ref.invalidate(allCharactersProvider),
      resolveName: (String name) => name,
      copy: MultiSelectCopy(
        inputPlaceholder: l10n.formCharacterSelectPlaceholder,
        listLoadFailed: l10n.formCharacterListLoadFailed,
        emptyCatalog: l10n.formCharacterEmptyCatalog,
        emptyRemaining: l10n.formCharacterEmptyRemaining,
      ),
    );
  }
}
