import 'package:hentai_library/features/comic_metadata/domain/author.dart';
import 'package:hentai_library/features/comic_metadata/domain/author_detail.dart';
import 'package:hentai_library/src/rust/api/author.dart' as rust_author;

Author mapAuthorIdentity(rust_author.AuthorIdentityFrbDto dto) {
  return Author(id: dto.id.toInt(), name: dto.name, verified: dto.verified);
}

AuthorLink mapAuthorLink(rust_author.AuthorLinkFrbDto dto) {
  return (
    id: dto.id.toInt(),
    platform: mapAuthorLinkPlatform(dto.platform),
    url: dto.url,
    platformDisplayName: dto.platformDisplayName,
    sortKey: dto.sortKey.toInt(),
  );
}

AuthorDetail mapAuthorDetail(
  rust_author.AuthorDetailFrbDto detail,
  rust_author.AuthorImageRefFrbDto image,
) {
  return AuthorDetail(
    id: detail.identity.id.toInt(),
    name: detail.identity.name,
    verified: detail.identity.verified,
    links: detail.links.map(mapAuthorLink).toList(),
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
      avatarSource: mapAuthorImageSource(image.avatarSource),
      avatarComicId: image.avatarComicId,
      avatarLinkId: image.avatarLinkId?.toInt(),
      avatarImageUrl: image.avatarImageUrl,
      backgroundSource: mapAuthorImageSource(image.backgroundSource),
      backgroundComicId: image.backgroundComicId,
      backgroundLinkId: image.backgroundLinkId?.toInt(),
      backgroundImageUrl: image.backgroundImageUrl,
    ),
  );
}

AuthorLinkPlatform mapAuthorLinkPlatform(
  rust_author.AuthorLinkPlatformFrb platform,
) {
  return switch (platform) {
    rust_author.AuthorLinkPlatformFrb.pixiv => AuthorLinkPlatform.pixiv,
    rust_author.AuthorLinkPlatformFrb.x => AuthorLinkPlatform.x,
    rust_author.AuthorLinkPlatformFrb.patreon => AuthorLinkPlatform.patreon,
    rust_author.AuthorLinkPlatformFrb.fanbox => AuthorLinkPlatform.fanbox,
    rust_author.AuthorLinkPlatformFrb.discord => AuthorLinkPlatform.discord,
    rust_author.AuthorLinkPlatformFrb.other => AuthorLinkPlatform.other,
  };
}

rust_author.AuthorLinkPlatformFrb mapAuthorLinkPlatformToFrb(
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

AuthorImageSource mapAuthorImageSource(
  rust_author.AuthorImageSourceFrb source,
) {
  return switch (source) {
    rust_author.AuthorImageSourceFrb.platformCached =>
      AuthorImageSource.platformCached,
    rust_author.AuthorImageSourceFrb.comicCover => AuthorImageSource.comicCover,
    rust_author.AuthorImageSourceFrb.none => AuthorImageSource.none,
  };
}
