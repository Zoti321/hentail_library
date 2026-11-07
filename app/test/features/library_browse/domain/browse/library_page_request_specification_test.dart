import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_page_request_specification.dart';
import 'package:hentai_library/shared/domain/exceptions/domain_exception.dart';

void main() {
  test('LibraryPageRequestSpecification.assertValid accepts valid input', () {
    expect(
      () => LibraryPageRequestSpecification.assertValid(page: 1, pageSize: 50),
      returnsNormally,
    );
  });

  test('LibraryPageRequestSpecification.assertValid rejects invalid input', () {
    expect(
      () => LibraryPageRequestSpecification.assertValid(page: 0, pageSize: 50),
      throwsA(isA<DomainException>()),
    );
  });
}
