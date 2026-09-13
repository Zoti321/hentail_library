import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/features/library/view_models/series_members_page_window.dart';

void main() {
  test('seriesMembersTotalPages rounds up', () {
    expect(seriesMembersTotalPages(totalCount: 0, pageSize: 50), 1);
    expect(seriesMembersTotalPages(totalCount: 50, pageSize: 50), 1);
    expect(seriesMembersTotalPages(totalCount: 51, pageSize: 50), 2);
  });
}
