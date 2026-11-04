import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/comic_trash/domain/comic_trash_target_ids.dart';

void main() {
  test('normalizeComicTrashTargetIds trims dedupes and drops empty', () {
    expect(
      normalizeComicTrashTargetIds([' a ', 'a', '', '  ', 'b']),
      ['a', 'b'],
    );
  });
}
