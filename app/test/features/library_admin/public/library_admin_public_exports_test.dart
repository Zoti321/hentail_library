import 'package:test/test.dart';
import 'package:hentai_library/features/library_admin/domain/libraries_port.dart';
import 'package:hentai_library/features/library_admin/domain/libraries_state.dart';

void main() {
  test('library_admin domain libraries types exist', () {
    expect(LibrariesPort, isNotNull);
    expect(LibrariesState, isNotNull);
  });
}
