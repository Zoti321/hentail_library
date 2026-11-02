import 'package:hentai_library/features/library_admin/public.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('public barrel exports command ports and bootstrap factories', () {
    expect(CurrentLibraryPort, isNotNull);
    expect(LibraryScanCommandPort, isNotNull);
    expect(createCurrentLibraryPort, isNotNull);
    expect(createLibraryScanCommandPort, isNotNull);
  });
}
