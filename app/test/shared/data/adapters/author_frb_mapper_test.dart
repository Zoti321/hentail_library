import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:hentai_library/shared/data/adapters/author_frb_mapper.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/author.dart';
import 'package:hentai_library/src/rust/api/author.dart' as rust_author;
import 'package:test/test.dart';

void main() {
  test('maps Author identity id, name and verified', () {
    final Author mapped = mapAuthorIdentity(
      rust_author.AuthorIdentityFrbDto(
        id: PlatformInt64.parse('42'),
        name: 'Alice',
        verified: true,
      ),
    );
    expect(mapped.id, 42);
    expect(mapped.name, 'Alice');
    expect(mapped.verified, isTrue);
  });
}
