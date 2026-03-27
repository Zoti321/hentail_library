import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/entity/v2/library_tag.dart';
import 'package:hentai_library/presentation/providers/providers_deps.dart';

/// 全部标签列表（用于标签管理页面）
final allTagsProvider = FutureProvider<List<LibraryTag>>((ref) async {
  final tags = await ref.watch(libraryTagRepoProvider).listAll();
  tags.sort((a, b) => a.name.compareTo(b.name));
  return tags;
});

/// 当前选中的标签集合（用于批量删除）
class TagSelectionNotifier extends Notifier<Set<LibraryTag>> {
  @override
  Set<LibraryTag> build() => <LibraryTag>{};

  void toggle(LibraryTag tag) {
    final next = Set<LibraryTag>.from(state);
    if (next.contains(tag)) {
      next.remove(tag);
    } else {
      next.add(tag);
    }
    state = next;
  }

  void clear() {
    state = <LibraryTag>{};
  }

  void selectAll(Iterable<LibraryTag> tags) {
    state = Set<LibraryTag>.from(tags);
  }
}

final tagSelectionProvider =
    NotifierProvider<TagSelectionNotifier, Set<LibraryTag>>(
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

  Future<void> addTag(LibraryTag tag) async {
    await _ref.read(libraryTagRepoProvider).add(LibraryTag(name: tag.name));
    _ref.invalidate(allTagsProvider);
  }

  Future<void> deleteTags(List<LibraryTag> tags) async {
    if (tags.isEmpty) return;
    await _ref
        .read(libraryTagRepoProvider)
        .deleteByNames(tags.map((e) => e.name).toList());
    _ref.invalidate(allTagsProvider);
    _ref.read(tagSelectionProvider.notifier).clear();
  }

  Future<void> renameTag(LibraryTag oldTag, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == oldTag.name) return;
    await _ref.read(libraryTagRepoProvider).rename(oldTag.name, trimmed);
    _ref.invalidate(allTagsProvider);
  }
}

final tagActionsProvider = Provider<TagActions>((ref) {
  return TagActions(ref);
});
