import 'package:hentai_library/features/reader/domain/image_set_navigation.dart';
import 'package:test/test.dart';

const List<ImageSetNavItem> _items = <ImageSetNavItem>[
  ImageSetNavItem(imageSetId: 'a', title: 'A'),
  ImageSetNavItem(imageSetId: 'b', title: 'B'),
  ImageSetNavItem(imageSetId: 'c', title: 'C'),
];

void main() {
  test('middle set has both neighbours in catalog order', () {
    final nav = ImageSetNavigation.around(_items, 'b');
    expect(nav.currentIndex, 1);
    expect(nav.previous?.imageSetId, 'a');
    expect(nav.next?.imageSetId, 'c');
  });

  test('ends do not wrap', () {
    final first = ImageSetNavigation.around(_items, 'a');
    expect(first.hasPrevious, isFalse);
    expect(first.previous, isNull);
    expect(first.next?.imageSetId, 'b');

    final last = ImageSetNavigation.around(_items, 'c');
    expect(last.hasNext, isFalse);
    expect(last.next, isNull);
    expect(last.previous?.imageSetId, 'b');
  });

  test('a current set missing from the catalog has no neighbours', () {
    final nav = ImageSetNavigation.around(_items, 'gone');
    expect(nav.currentIndex, -1);
    expect(nav.hasPrevious, isFalse);
    expect(nav.hasNext, isFalse);
    expect(nav.contains('c'), isTrue);
    expect(nav.contains('gone'), isFalse);
  });
}
