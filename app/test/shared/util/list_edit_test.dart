import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/util/list_edit.dart';

void main() {
  test('listWithAdded 追加新值且不修改入参', () {
    final List<String> base = <String>['a'];
    final List<String> next = listWithAdded(base, 'b');

    expect(next, <String>['a', 'b']);
    expect(base, <String>['a']);
    expect(identical(base, next), isFalse);
  });

  test('listWithAdded 已存在时不重复追加', () {
    final List<String> base = <String>['a', 'b'];

    expect(listWithAdded(base, 'a'), <String>['a', 'b']);
    expect(identical(listWithAdded(base, 'a'), base), isTrue);
  });

  test('listWithRemoved 移除匹配项且不修改入参', () {
    final List<String> base = <String>['a', 'b', 'a'];
    final List<String> next = listWithRemoved(base, 'a');

    expect(next, <String>['b']);
    expect(base, hasLength(3));
  });

  test('listWithRemoved 无命中时列表不变', () {
    final List<String> base = <String>['a'];

    expect(listWithRemoved(base, 'z'), <String>['a']);
    expect(identical(listWithRemoved(base, 'z'), base), isTrue);
  });
}
