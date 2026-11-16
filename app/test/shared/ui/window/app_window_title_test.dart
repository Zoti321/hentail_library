import 'package:hentai_library/shared/ui/window/app_window_title.dart';
import 'package:test/test.dart';

void main() {
  test('Release uses base title without [dev]', () {
    expect(appWindowTitle(isReleaseMode: true), 'Hentai Library');
  });

  test('non-Release appends [dev] for App data profile affordance', () {
    expect(appWindowTitle(isReleaseMode: false), 'Hentai Library [dev]');
  });
}
