import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_list_order.dart';

void main() {
  test('md3eHomeLibraryReorderTargetToFlutterNewIndex matches apply', () {
    final List<String> items = <String>['a', 'b', 'c', 'd'];
    const int from = 0;
    const int m3eTo = 2;
    final int flutterNew = md3eHomeLibraryReorderTargetToFlutterNewIndex(
      from,
      m3eTo,
    );
    final List<String> viaM3e = List<String>.of(items);
    final String moved = viaM3e.removeAt(from);
    viaM3e.insert(m3eTo, moved);
    expect(
      applyMd3eHomeLibraryListReorder(items, from, flutterNew),
      viaM3e,
    );
  });

  test('applyMd3eHomeLibraryListReorder moves item down', () {
    final List<String> items = <String>['a', 'b', 'c', 'd'];
    final List<String> next = applyMd3eHomeLibraryListReorder(items, 0, 3);
    expect(next, <String>['b', 'c', 'a', 'd']);
  });

  test('applyMd3eHomeLibraryListReorder moves item up', () {
    final List<String> items = <String>['a', 'b', 'c', 'd'];
    final List<String> next = applyMd3eHomeLibraryListReorder(items, 3, 0);
    expect(next, <String>['d', 'a', 'b', 'c']);
  });

  test('applyMd3eHomeLibraryListReorder ignores invalid indices', () {
    final List<String> items = <String>['a', 'b'];
    expect(
      applyMd3eHomeLibraryListReorder(items, -1, 1),
      <String>['a', 'b'],
    );
  });
}
