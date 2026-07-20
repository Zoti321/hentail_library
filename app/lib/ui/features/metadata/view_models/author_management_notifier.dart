import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';

/// 全部作者列表（用于作者管理页面）；监听 Drift `authors` 表变化。
final allAuthorsProvider = StreamProvider<List<Author>>((ref) {
  return ref.watch(authorRepoProvider).watchAll();
});

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

final filteredAuthorsProvider = Provider<List<Author>>((ref) {
  final AsyncValue<List<Author>> asyncAuthors = ref.watch(allAuthorsProvider);
  final String query = ref.watch(authorFilterProvider).trim().toLowerCase();
  final List<Author> authors = asyncAuthors.maybeWhen(
    data: (List<Author> value) => value,
    orElse: () => const <Author>[],
  );
  if (query.isEmpty) {
    return authors;
  }
  return authors
      .where((Author item) => item.name.toLowerCase().contains(query))
      .toList();
});

/// 作者管理操作封装（新增、删除、重命名）
class AuthorActions {
  AuthorActions(this._ref);

  final Ref _ref;

  Future<void> addAuthor(Author author) async {
    await _ref.read(authorRepoProvider).add(author);
  }

  Future<void> deleteAuthor(Author author) async {
    await _ref.read(authorRepoProvider).deleteByNames(<String>[author.name]);
  }

  Future<void> renameAuthor(Author oldAuthor, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == oldAuthor.name) return;
    await _ref.read(authorRepoProvider).rename(oldAuthor.name, trimmed);
  }
}

final authorActionsProvider = Provider<AuthorActions>((ref) {
  return AuthorActions(ref);
});
