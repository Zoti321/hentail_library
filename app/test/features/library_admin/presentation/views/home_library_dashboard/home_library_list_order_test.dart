import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/library_admin/presentation/views/home_library_dashboard/patterns/home_library_list_order.dart';

void main() {
  test('applyHomeLibraryListReorder moves item down', () {
    final List<String> items = <String>['a', 'b', 'c', 'd'];
    final List<String> next = applyHomeLibraryListReorder(items, 0, 3);
    expect(next, <String>['b', 'c', 'a', 'd']);
  });

  test('applyHomeLibraryListReorder moves item up', () {
    final List<String> items = <String>['a', 'b', 'c', 'd'];
    final List<String> next = applyHomeLibraryListReorder(items, 3, 0);
    expect(next, <String>['d', 'a', 'b', 'c']);
  });

  test('applyHomeLibraryListReorder ignores invalid indices', () {
    final List<String> items = <String>['a', 'b'];
    expect(applyHomeLibraryListReorder(items, -1, 1), <String>['a', 'b']);
  });
}
