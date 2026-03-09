import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/entity/entities.dart';
import 'package:hentai_library/domain/enums/enums.dart';
import 'package:hentai_library/presentation/providers/comic/comic_providers.dart';

/// 全部标签列表（用于标签管理页面）
final allTagsProvider = FutureProvider<List<CategoryTag>>((ref) async {
  final repo = ref.read(comicRepoProvider);
  final tags = await repo.listAllTags();
  return tags;
});

/// 标签按类型分组，方便 UI 渲染
final tagsByTypeProvider =
    FutureProvider<Map<CategoryTagType, List<CategoryTag>>>((ref) async {
      final tags = await ref.watch(allTagsProvider.future);
      final grouped = groupBy<CategoryTag, CategoryTagType>(
        tags,
        (t) => t.type,
      );
      for (final list in grouped.values) {
        list.sort((a, b) => a.name.compareTo(b.name));
      }
      return grouped;
    });

/// 当前选中的标签集合（用于批量删除）
class TagSelectionNotifier extends Notifier<Set<CategoryTag>> {
  @override
  Set<CategoryTag> build() => <CategoryTag>{};

  void toggle(CategoryTag tag) {
    final next = Set<CategoryTag>.from(state);
    if (next.contains(tag)) {
      next.remove(tag);
    } else {
      next.add(tag);
    }
    state = next;
  }

  void clear() {
    state = <CategoryTag>{};
  }

  void selectAll(Iterable<CategoryTag> tags) {
    state = Set<CategoryTag>.from(tags);
  }
}

final tagSelectionProvider =
    NotifierProvider<TagSelectionNotifier, Set<CategoryTag>>(
      TagSelectionNotifier.new,
    );

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

/// 标签管理操作封装（新增、删除、重命名）
class TagActions {
  TagActions(this._ref);

  final Ref _ref;

  Future<void> addTag(CategoryTag tag) async {
    final repo = _ref.read(comicRepoProvider);
    await repo.addTag(tag);
    _ref.invalidate(allTagsProvider);
    _ref.invalidate(tagsByTypeProvider);
  }

  Future<void> deleteTags(List<CategoryTag> tags) async {
    if (tags.isEmpty) return;
    final repo = _ref.read(comicRepoProvider);
    await repo.deleteTags(tags);
    _ref.invalidate(allTagsProvider);
    _ref.invalidate(tagsByTypeProvider);
    _ref.read(tagSelectionProvider.notifier).clear();
  }

  Future<void> renameTag(CategoryTag oldTag, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == oldTag.name) return;
    final repo = _ref.read(comicRepoProvider);
    await repo.renameTag(oldTag, trimmed);
    _ref.invalidate(allTagsProvider);
    _ref.invalidate(tagsByTypeProvider);
  }
}

final tagActionsProvider = Provider<TagActions>((ref) {
  return TagActions(ref);
});
