import 'package:test/test.dart';
import 'package:hentai_library/features/library_admin/domain/library_commands.dart';
import 'package:hentai_library/features/library_admin/domain/libraries_state.dart';

void main() {
  test('library_admin domain libraries types exist', () {
    expect(SubmitLibraryFormCommand, isNotNull);
    expect(LibrariesState, isNotNull);
  });
}
