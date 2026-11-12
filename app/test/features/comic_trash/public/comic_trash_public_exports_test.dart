import 'package:hentai_library/features/comic_trash/public.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'public barrel exports command port, cross-feature types, and trash page',
    () {
      expect(TrashComicsCommand, isNotNull);
      expect(TrashedComic, isNotNull);
      expect(ComicTrashRepository, isNotNull);
      expect(PurgeConfirmCopy, isNotNull);
      expect(TrashPage, isNotNull);
    },
  );
}
