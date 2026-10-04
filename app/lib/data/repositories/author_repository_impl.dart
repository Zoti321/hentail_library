import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:hentai_library/data/adapters/author_frb_mapper.dart';
import 'package:hentai_library/data/adapters/frb_call_guard.dart';
import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/domain/models/entity/comic/author_detail.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/domain/repositories/author_repository.dart';
import 'package:hentai_library/src/rust/api/author.dart' as rust_author;
import 'package:hentai_library/src/rust/api/comic.dart' as rust;

class AuthorRepositoryImpl implements AuthorRepository {
  const AuthorRepositoryImpl();

  @override
  Future<List<Author>> listAll() async {
    final List<rust_author.AuthorIdentityFrbDto> rows = await guardFrb(
      rust_author.listAllAuthorsFrb,
      fallbackMessage: '读取作者列表失败',
    );
    return rows.map(mapAuthorIdentity).toList();
  }

  @override
  Stream<List<Author>> watchAll() {
    return guardFrbStream(
      () => rust_author.watchAuthorsFrb().map(
        (List<rust_author.AuthorIdentityFrbDto> rows) =>
            rows.map(mapAuthorIdentity).toList(),
      ),
      fallbackMessage: '监听作者列表失败',
    );
  }

  @override
  Future<PagedResult<Author>> fetchPage(PageRequest request) async {
    final rust_author.AuthorPagedDto page = await guardFrb(
      () => rust_author.fetchAuthorsPageFrb(
        request: rust.PageRequestDto(
          page: request.page,
          pageSize: request.pageSize,
        ),
      ),
      fallbackMessage: '读取作者分页失败',
    );
    return PagedResult<Author>(
      items: page.items.map(mapAuthorIdentity).toList(),
      totalCount: page.totalCount.toInt(),
      page: page.page,
      pageSize: page.pageSize,
    );
  }

  @override
  Future<Author> add(Author author) async {
    final rust_author.AuthorIdentityFrbDto created = await guardFrb(
      () => rust_author.addAuthorFrb(name: author.name),
      fallbackMessage: '添加作者失败',
    );
    return mapAuthorIdentity(created);
  }

  @override
  Future<void> deleteByNames(List<String> names) async {
    await guardFrb(
      () => rust_author.deleteAuthorsByNamesFrb(names: names),
      fallbackMessage: '删除作者失败',
    );
  }

  @override
  Future<void> rename(String oldName, String newName) async {
    await guardFrb(
      () => rust_author.renameAuthorFrb(oldName: oldName, newName: newName),
      fallbackMessage: '重命名作者失败',
    );
  }

  @override
  Future<AuthorDetail?> getDetail({
    required int authorId,
    required bool showR18,
  }) async {
    final rust_author.AuthorDetailFrbDto? detail = await guardFrb(
      () => rust_author.getAuthorDetailFrb(
        authorId: _toI64(authorId),
        showR18: showR18,
      ),
      fallbackMessage: '读取作者详情失败',
    );
    if (detail == null) {
      return null;
    }
    final rust_author.AuthorImageRefFrbDto image = await guardFrb(
      () => rust_author.resolveAuthorImageFrb(
        authorId: _toI64(authorId),
        showR18: showR18,
      ),
      fallbackMessage: '读取作者形象失败',
    );
    return _mapDetail(detail, image);
  }

  @override
  Future<Uint8List?> loadImage({
    required int authorId,
    required AuthorImageSlot slot,
    required bool showR18,
  }) {
    return guardFrb(
      () => rust_author.loadAuthorImageFrb(
        authorId: _toI64(authorId),
        slot: switch (slot) {
          AuthorImageSlot.avatar => rust_author.AuthorImageSlotFrb.avatar,
          AuthorImageSlot.background =>
            rust_author.AuthorImageSlotFrb.background,
        },
        showR18: showR18,
      ),
      fallbackMessage: '读取作者形象高清图失败',
    );
  }

  @override
  Future<AuthorLink> addLink({
    required int authorId,
    required AuthorLinkPlatform platform,
    required String url,
    String? platformDisplayName,
  }) async {
    final rust_author.AuthorLinkFrbDto link = await guardFrb(
      () => rust_author.addAuthorLinkFrb(
        authorId: _toI64(authorId),
        platform: _mapPlatformToFrb(platform),
        url: url,
        platformDisplayName: platformDisplayName,
      ),
      fallbackMessage: '添加作者链接失败',
    );
    return _mapLink(link);
  }

  @override
  Future<void> updateLink({
    required int linkId,
    required AuthorLinkPlatform platform,
    required String url,
    String? platformDisplayName,
  }) async {
    await guardFrb(
      () => rust_author.updateAuthorLinkFrb(
        linkId: _toI64(linkId),
        platform: _mapPlatformToFrb(platform),
        url: url,
        platformDisplayName: platformDisplayName,
      ),
      fallbackMessage: '更新作者链接失败',
    );
  }

  @override
  Future<void> deleteLink({required int authorId, required int linkId}) async {
    await guardFrb(
      () => rust_author.deleteAuthorLinkFrb(
        authorId: _toI64(authorId),
        linkId: _toI64(linkId),
      ),
      fallbackMessage: '删除作者链接失败',
    );
  }
}

AuthorLink _mapLink(rust_author.AuthorLinkFrbDto dto) {
  return (
    id: dto.id.toInt(),
    platform: _mapPlatform(dto.platform),
    url: dto.url,
    platformDisplayName: dto.platformDisplayName,
    sortKey: dto.sortKey.toInt(),
  );
}

AuthorDetail _mapDetail(
  rust_author.AuthorDetailFrbDto detail,
  rust_author.AuthorImageRefFrbDto image,
) {
  return AuthorDetail(
    id: detail.identity.id.toInt(),
    name: detail.identity.name,
    verified: detail.identity.verified,
    links: detail.links.map(_mapLink).toList(),
    tags: detail.tags
        .map(
          (rust_author.AuthorFacetCountFrbDto e) =>
              (name: e.name, attachmentCount: e.attachmentCount.toInt()),
        )
        .toList(),
    parodies: detail.parodies
        .map(
          (rust_author.AuthorFacetCountFrbDto e) =>
              (name: e.name, attachmentCount: e.attachmentCount.toInt()),
        )
        .toList(),
    characters: detail.characters
        .map(
          (rust_author.AuthorFacetCountFrbDto e) =>
              (name: e.name, attachmentCount: e.attachmentCount.toInt()),
        )
        .toList(),
    topComics: detail.topComics
        .map(
          (rust_author.AuthorTopComicFrbDto e) =>
              (comicId: e.comicId, title: e.title),
        )
        .toList(),
    comicCount: detail.comicCount.toInt(),
    image: (
      avatarSource: _mapImageSource(image.avatarSource),
      avatarComicId: image.avatarComicId,
      backgroundSource: _mapImageSource(image.backgroundSource),
      backgroundComicId: image.backgroundComicId,
    ),
  );
}

AuthorLinkPlatform _mapPlatform(rust_author.AuthorLinkPlatformFrb platform) {
  return switch (platform) {
    rust_author.AuthorLinkPlatformFrb.pixiv => AuthorLinkPlatform.pixiv,
    rust_author.AuthorLinkPlatformFrb.x => AuthorLinkPlatform.x,
    rust_author.AuthorLinkPlatformFrb.patreon => AuthorLinkPlatform.patreon,
    rust_author.AuthorLinkPlatformFrb.fanbox => AuthorLinkPlatform.fanbox,
    rust_author.AuthorLinkPlatformFrb.discord => AuthorLinkPlatform.discord,
    rust_author.AuthorLinkPlatformFrb.other => AuthorLinkPlatform.other,
  };
}

rust_author.AuthorLinkPlatformFrb _mapPlatformToFrb(
  AuthorLinkPlatform platform,
) {
  return switch (platform) {
    AuthorLinkPlatform.pixiv => rust_author.AuthorLinkPlatformFrb.pixiv,
    AuthorLinkPlatform.x => rust_author.AuthorLinkPlatformFrb.x,
    AuthorLinkPlatform.patreon => rust_author.AuthorLinkPlatformFrb.patreon,
    AuthorLinkPlatform.fanbox => rust_author.AuthorLinkPlatformFrb.fanbox,
    AuthorLinkPlatform.discord => rust_author.AuthorLinkPlatformFrb.discord,
    AuthorLinkPlatform.other => rust_author.AuthorLinkPlatformFrb.other,
  };
}

AuthorImageSource _mapImageSource(rust_author.AuthorImageSourceFrb source) {
  return switch (source) {
    rust_author.AuthorImageSourceFrb.platformCached =>
      AuthorImageSource.platformCached,
    rust_author.AuthorImageSourceFrb.comicCover => AuthorImageSource.comicCover,
    rust_author.AuthorImageSourceFrb.none => AuthorImageSource.none,
  };
}

PlatformInt64 _toI64(int value) => PlatformInt64.parse(value.toString());
