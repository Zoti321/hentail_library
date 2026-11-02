import 'package:hentai_library/shared/domain/models/entity/comic/author.dart';
import 'package:hentai_library/src/rust/api/author.dart' as rust_author;

Author mapAuthorIdentity(rust_author.AuthorIdentityFrbDto dto) {
  return Author(id: dto.id.toInt(), name: dto.name, verified: dto.verified);
}
