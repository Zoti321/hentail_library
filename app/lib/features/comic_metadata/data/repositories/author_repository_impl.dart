import 'dart:typed_data';

import 'package:hentai_library/features/comic_metadata/data/adapters/author_frb_adapter.dart';
import 'package:hentai_library/features/comic_metadata/data/mappers/author_frb_mapper.dart';
import 'package:hentai_library/features/comic_metadata/domain/author.dart';
import 'package:hentai_library/features/comic_metadata/domain/author_detail.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/features/comic_metadata/domain/author_repository.dart';
import 'package:hentai_library/features/comic_metadata/domain/named_facet_form_candidate.dart';
import 'package:hentai_library/features/comic_metadata/domain/named_facet_management_repository.dart';
import 'package:hentai_library/src/rust/api/author.dart' as rust_author;

class AuthorRepositoryImpl implements AuthorRepository {
  const AuthorRepositoryImpl({
    required this.namedFacets,
    AuthorFrbAdapter? adapter,
  }) : _adapter = adapter ?? const AuthorFrbAdapter();

  /// 通用 named-facet 管理路径：author 的删除 / 重命名与 tag 共用。
  final NamedFacetManagementRepository namedFacets;
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
    final PagedResult<NamedFacetFormCandidate> page = await namedFacets
        .fetchPage(ManagedNamedFacetKind.author, request);
    return PagedResult<Author>(
      items: page.items
          .map((NamedFacetFormCandidate e) => Author(name: e.name))
          .toList(),
      totalCount: page.totalCount,
      page: page.page,
      pageSize: page.pageSize,
    );
  }

  @override
  Future<Author> add(Author author) async {
    await namedFacets.add(ManagedNamedFacetKind.author, author.name);
    return Author(name: author.name);
  }

  @override
  Future<void> deleteByNames(List<String> names) =>
      namedFacets.deleteByNames(ManagedNamedFacetKind.author, names);

  @override
  Future<void> rename(String oldName, String newName) =>
      namedFacets.rename(ManagedNamedFacetKind.author, oldName, newName);

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
