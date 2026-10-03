enum AuthorLinkPlatform { pixiv, x, patreon, fanbox, discord, other }

extension AuthorLinkPlatformX on AuthorLinkPlatform {
  bool get isCreative => this != AuthorLinkPlatform.other;
}

enum AuthorImageSource { platformCached, comicCover, none }

typedef AuthorLink = ({
  int id,
  AuthorLinkPlatform platform,
  String url,
  String? platformDisplayName,
  int sortKey,
});

typedef AuthorFacetCount = ({String name, int attachmentCount});

typedef AuthorTopComic = ({String comicId, String title});

typedef AuthorImageRef = ({
  AuthorImageSource avatarSource,
  String? avatarComicId,
  AuthorImageSource backgroundSource,
  String? backgroundComicId,
});

class AuthorDetail {
  const AuthorDetail({
    required this.id,
    required this.name,
    required this.verified,
    required this.links,
    required this.tags,
    required this.parodies,
    required this.characters,
    required this.topComics,
    required this.image,
  });

  final int id;
  final String name;
  final bool verified;
  final List<AuthorLink> links;
  final List<AuthorFacetCount> tags;
  final List<AuthorFacetCount> parodies;
  final List<AuthorFacetCount> characters;
  final List<AuthorTopComic> topComics;
  final AuthorImageRef image;
}
