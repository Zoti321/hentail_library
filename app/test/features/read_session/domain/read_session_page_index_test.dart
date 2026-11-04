import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/read_session/domain/read_session_page_index.dart';
import 'package:hentai_library/shared/domain/exceptions/domain_rule_violation.dart';

void main() {
  test('ReadSessionPageIndex.tryParse', () {
    expect(ReadSessionPageIndex.tryParse(3, totalPages: 10).value, 3);
    expect(
      () => ReadSessionPageIndex.tryParse(0, totalPages: 10),
      throwsA(isA<DomainRuleViolation>()),
    );
    expect(
      () => ReadSessionPageIndex.tryParse(11, totalPages: 10),
      throwsA(isA<DomainRuleViolation>()),
    );
  });
}
