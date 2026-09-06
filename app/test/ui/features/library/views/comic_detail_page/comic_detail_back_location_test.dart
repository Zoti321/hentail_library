import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/features/library/views/comic_detail_page/comic_detail_back_location.dart';

void main() {
  group('resolveComicDetailBackLocation', () {
    test('returns series detail when returnSeriesId is present', () {
      expect(
        resolveComicDetailBackLocation(returnSeriesId: 'series-a'),
        '/series/${Uri.encodeComponent('series-a')}',
      );
    });

    test('encodes seriesId in path', () {
      expect(
        resolveComicDetailBackLocation(returnSeriesId: 'series/with space'),
        '/series/${Uri.encodeComponent('series/with space')}',
      );
    });

    test('returns null when returnSeriesId is absent', () {
      expect(resolveComicDetailBackLocation(), isNull);
    });

    test('returns null when returnSeriesId is blank', () {
      expect(resolveComicDetailBackLocation(returnSeriesId: ' '), isNull);
    });
  });
}
