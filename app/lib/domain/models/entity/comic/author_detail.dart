enum AuthorLinkPlatform { pixiv, x, patreon, fanbox, discord, other }

extension AuthorLinkPlatformX on AuthorLinkPlatform {
  bool get isCreative => this != AuthorLinkPlatform.other;
}

/// 按 URL 主机名推断作者链接平台；无法识别时为 [AuthorLinkPlatform.other]。
AuthorLinkPlatform detectAuthorLinkPlatform(String url) {
  final Uri? uri = Uri.tryParse(url.trim());
  final String host = (uri?.host ?? '').toLowerCase();
  if (host.isEmpty) {
    return AuthorLinkPlatform.other;
  }
  bool matches(String domain) => host == domain || host.endsWith('.$domain');
  if (matches('fanbox.cc')) {
    return AuthorLinkPlatform.fanbox;
  }
  if (matches('pixiv.net')) {
    final String path = uri!.path.toLowerCase();
    return path.startsWith('/fanbox')
        ? AuthorLinkPlatform.fanbox
        : AuthorLinkPlatform.pixiv;
  }
  if (matches('x.com') || matches('twitter.com')) {
    return AuthorLinkPlatform.x;
  }
  if (matches('patreon.com')) {
    return AuthorLinkPlatform.patreon;
  }
  if (matches('discord.gg') ||
      matches('discord.com') ||
      matches('discordapp.com')) {
    return AuthorLinkPlatform.discord;
  }
  return AuthorLinkPlatform.other;
}

enum AuthorImageSource { platformCached, comicCover, none }

/// Author image 的位置：头像或背景横幅。
enum AuthorImageSlot { avatar, background }

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
    required this.comicCount,
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
  final int comicCount;
  final AuthorImageRef image;
}
