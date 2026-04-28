import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/model/entity/comic/author.dart';
import 'package:hentai_library/presentation/providers/deps/deps.dart';

/// 全部作者列表（用于作者管理页面）；监听 Drift `authors` 表变化。
final allAuthorsProvider = StreamProvider<List<Author>>((ref) {
  return ref.watch(libraryAuthorRepoProvider).watchAll();
});

/// 当前选中的作者集合（用于批量删除）
class AuthorSelectionNotifier extends Notifier<Set<Author>> {
  @override
  Set<Author> build() => <Author>{};

  void toggle(Author author) {
    final next = Set<Author>.from(state);
    if (next.contains(author)) {
      next.remove(author);
    } else {
      next.add(author);
    }
    state = next;
  }

  void clear() {
    state = <Author>{};
  }

  void remove(Author author) {
    if (!state.contains(author)) {
      return;
    }
    state = Set<Author>.from(state)..remove(author);
  }

  void selectAll(Iterable<Author> authors) {
    state = Set<Author>.from(authors);
  }
}

final authorSelectionProvider =
    NotifierProvider<AuthorSelectionNotifier, Set<Author>>(
      AuthorSelectionNotifier.new,
    );

/// 作者搜索关键词
class AuthorFilterNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) {
    state = value;
  }

  void clear() {
    state = '';
  }
}

final authorFilterProvider = NotifierProvider<AuthorFilterNotifier, String>(
  AuthorFilterNotifier.new,
);

/// 作者管理操作封装（新增、删除、重命名）
class AuthorActions {
  AuthorActions(this._ref);

  final Ref _ref;

  Future<void> addAuthor(Author author) async {
    await _ref.read(libraryAuthorRepoProvider).add(author);
  }

  Future<void> deleteAuthors(List<Author> authors) async {
    if (authors.isEmpty) return;
    await _ref
        .read(libraryAuthorRepoProvider)
        .deleteByNames(authors.map((e) => e.name).toList());
    _ref.read(authorSelectionProvider.notifier).clear();
  }

  Future<void> deleteAuthor(Author author) async {
    await _ref.read(libraryAuthorRepoProvider).deleteByNames(<String>[
      author.name,
    ]);
    _ref.read(authorSelectionProvider.notifier).remove(author);
  }

  Future<void> renameAuthor(Author oldAuthor, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == oldAuthor.name) return;
    await _ref.read(libraryAuthorRepoProvider).rename(oldAuthor.name, trimmed);
  }
}

final authorActionsProvider = Provider<AuthorActions>((ref) {
  return AuthorActions(ref);
});
