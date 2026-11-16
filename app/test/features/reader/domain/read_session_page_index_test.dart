import 'package:hentai_library/features/reader/domain/value_objects/read_session_page_index.dart';
import 'package:hentai_library/shared/domain/exceptions/domain_exception.dart';
import 'package:test/test.dart';

void main() {
  test('ReadSessionPageIndex.tryParse', () {
    expect(ReadSessionPageIndex.tryParse(3, totalPages: 10).value, 3);
    expect(
      () => ReadSessionPageIndex.tryParse(0, totalPages: 10),
      throwsA(isA<DomainException>()),
    );
    expect(
      () => ReadSessionPageIndex.tryParse(11, totalPages: 10),
      throwsA(isA<DomainException>()),
    );
  });
}
