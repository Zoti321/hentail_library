import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_page_request_spec.dart';
import 'package:hentai_library/shared/domain/exceptions/domain_rule_violation.dart';

void main() {
  test('assertValidLibraryPageRequest accepts valid input', () {
    expect(
      () => assertValidLibraryPageRequest(page: 1, pageSize: 50),
      returnsNormally,
    );
  });

  test('assertValidLibraryPageRequest rejects invalid input', () {
    expect(
      () => assertValidLibraryPageRequest(page: 0, pageSize: 50),
      throwsA(isA<DomainRuleViolation>()),
    );
  });
}
