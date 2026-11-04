import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/comic_trash/domain/comic_trash_target_ids_specification.dart';

void main() {
  test('ComicTrashTargetIdsSpecification.normalize', () {
    expect(
      ComicTrashTargetIdsSpecification.normalize([' a ', 'a', '', '  ', 'b']),
      ['a', 'b'],
    );
  });
}
