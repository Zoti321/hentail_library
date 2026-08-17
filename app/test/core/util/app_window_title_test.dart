import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/util/app_window_title.dart';

void main() {
  test('Release uses base title without [dev]', () {
    expect(appWindowTitle(isReleaseMode: true), 'hentai library');
  });

  test('non-Release appends [dev] for App data profile affordance', () {
    expect(appWindowTitle(isReleaseMode: false), 'hentai library [dev]');
  });
}
