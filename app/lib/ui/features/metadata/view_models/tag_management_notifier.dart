import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';

/// 全部标签列表（用于标签管理页面）
final allTagsProvider = FutureProvider<List<Tag>>((ref) async {
  final tags = await ref.watch(tagRepoProvider).listAll();
  tags.sort((a, b) => a.name.compareTo(b.name));
  return tags;
});

/// 标签搜索关键词
class TagFilterNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) {
    state = value;
  }

  void clear() {
    state = '';
  }
}

final tagFilterProvider = NotifierProvider<TagFilterNotifier, String>(
  TagFilterNotifier.new,
);

final filteredTagsProvider = Provider<List<Tag>>((ref) {
  final AsyncValue<List<Tag>> asyncTags = ref.watch(allTagsProvider);
  final String query = ref.watch(tagFilterProvider).trim().toLowerCase();
  final List<Tag> tags = asyncTags.maybeWhen(
    data: (List<Tag> value) => value,
    orElse: () => const <Tag>[],
  );
  if (query.isEmpty) {
    return tags;
  }
  return tags
      .where((Tag item) => item.name.toLowerCase().contains(query))
      .toList();
});

/// 标签管理操作封装（新增、删除、重命名）
class TagActions {
  TagActions(this._ref);

  final Ref _ref;

  Future<void> addTag(Tag tag) async {
    await _ref.read(tagRepoProvider).add(Tag(name: tag.name));
    _ref.invalidate(allTagsProvider);
  }

  Future<void> deleteTag(Tag tag) async {
    await _ref.read(tagRepoProvider).deleteByNames(<String>[tag.name]);
    _ref.invalidate(allTagsProvider);
  }

  Future<void> renameTag(Tag oldTag, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == oldTag.name) return;
    await _ref.read(tagRepoProvider).rename(oldTag.name, trimmed);
    _ref.invalidate(allTagsProvider);
  }
}

final tagActionsProvider = Provider<TagActions>((ref) {
  return TagActions(ref);
});
