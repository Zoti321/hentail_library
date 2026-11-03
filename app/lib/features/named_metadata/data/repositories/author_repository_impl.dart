import 'dart:typed_data';

import 'package:hentai_library/features/named_metadata/data/adapters/author_frb_adapter.dart';
import 'package:hentai_library/features/named_metadata/data/mappers/author_frb_mapper.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/author.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/author_detail.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/features/named_metadata/domain/author_repository.dart';
import 'package:hentai_library/src/rust/api/author.dart' as rust_author;

class AuthorRepositoryImpl implements AuthorRepository {
  const AuthorRepositoryImpl({AuthorFrbAdapter? adapter})
    : _adapter = adapter ?? const AuthorFrbAdapter();

  final AuthorFrbAdapter _adapter;

  @override
  Future<List<Author>> listAll() async {
    final List<rust_author.AuthorIdentityFrbDto> rows = await _adapter
        .listAll();
    return rows.map(mapAuthorIdentity).toList();
  }

  @override
  Stream<List<Author>> watchAll() {
    return _adapter.watchAll().map(
      (List<rust_author.AuthorIdentityFrbDto> rows) =>
          rows.map(mapAuthorIdentity).toList(),
    );
  }

  @override
  Future<PagedResult<Author>> fetchPage(PageRequest request) async {
    final rust_author.AuthorPagedDto page = await _adapter.fetchPage(request);
    return PagedResult<Author>(
      items: page.items.map(mapAuthorIdentity).toList(),
      totalCount: page.totalCount.toInt(),
      page: page.page,
      pageSize: page.pageSize,
    );
  }

  @override
  Future<Author> add(Author author) async {
    final rust_author.AuthorIdentityFrbDto created = await _adapter.add(
      name: author.name,
    );
    return mapAuthorIdentity(created);
  }

  @override
  Future<void> deleteByNames(List<String> names) =>
      _adapter.deleteByNames(names);

  @override
  Future<void> rename(String oldName, String newName) =>
      _adapter.rename(oldName: oldName, newName: newName);

  @override
  Future<AuthorDetail?> getDetail({
    required int authorId,
    required bool showR18,
  }) async {
    final rust_author.AuthorDetailFrbDto? detail = await _adapter.getDetail(
      authorId: authorId,
      showR18: showR18,
    );
    if (detail == null) {
      return null;
    }
    final rust_author.AuthorImageRefFrbDto image = await _adapter.resolveImage(
      authorId: authorId,
      showR18: showR18,
    );
    return mapAuthorDetail(detail, image);
  }

  @override
  Future<Uint8List?> loadImage({
    required int authorId,
    required AuthorImageSlot slot,
    required bool showR18,
  }) => _adapter.loadImage(authorId: authorId, slot: slot, showR18: showR18);

  @override
  Future<AuthorLink> addLink({
    required int authorId,
    required AuthorLinkPlatform platform,
    required String url,
    String? platformDisplayName,
  }) async {
    final rust_author.AuthorLinkFrbDto link = await _adapter.addLink(
      authorId: authorId,
      platform: mapAuthorLinkPlatformToFrb(platform),
      url: url,
      platformDisplayName: platformDisplayName,
    );
    return mapAuthorLink(link);
  }

  @override
  Future<void> updateLink({
    required int linkId,
    required AuthorLinkPlatform platform,
    required String url,
    String? platformDisplayName,
  }) => _adapter.updateLink(
    linkId: linkId,
    platform: mapAuthorLinkPlatformToFrb(platform),
    url: url,
    platformDisplayName: platformDisplayName,
  );

  @override
  Future<void> deleteLink({required int authorId, required int linkId}) =>
      _adapter.deleteLink(authorId: authorId, linkId: linkId);
}
