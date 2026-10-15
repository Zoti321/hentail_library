import 'package:hentai_library/domain/models/entity/comic/author_detail.dart';
import 'package:test/test.dart';

void main() {
  test(
    'author aliases follow platform priority and preserve case-sensitive values',
    () {
      final List<String> aliases = authorAliases(
        authorName: 'Main',
        links: <AuthorLink>[
          (
            id: 4,
            platform: AuthorLinkPlatform.discord,
            url: 'https://discord.gg/example',
            platformDisplayName: 'Discord Name',
            sortKey: 0,
          ),
          (
            id: 3,
            platform: AuthorLinkPlatform.x,
            url: 'https://x.com/name',
            platformDisplayName: 'X Name',
            sortKey: 0,
          ),
          (
            id: 2,
            platform: AuthorLinkPlatform.pixiv,
            url: 'https://pixiv.net/users/2',
            platformDisplayName: 'Pixiv Name',
            sortKey: 0,
          ),
          (
            id: 1,
            platform: AuthorLinkPlatform.patreon,
            url: 'https://patreon.com/name',
            platformDisplayName: 'Pixiv Name',
            sortKey: 0,
          ),
        ],
      );

      expect(aliases, <String>['Pixiv Name', 'X Name', 'Discord Name']);
    },
  );

  test(
    'author aliases omit matching display name, empty values, and Other links',
    () {
      expect(
        authorAliases(
          authorName: 'Main',
          links: <AuthorLink>[
            (
              id: 1,
              platform: AuthorLinkPlatform.pixiv,
              url: 'https://pixiv.net/users/1',
              platformDisplayName: 'Main',
              sortKey: 0,
            ),
            (
              id: 2,
              platform: AuthorLinkPlatform.other,
              url: 'https://example.com/name',
              platformDisplayName: 'Other Name',
              sortKey: 1,
            ),
            (
              id: 3,
              platform: AuthorLinkPlatform.x,
              url: 'https://x.com/name',
              platformDisplayName: ' ',
              sortKey: 2,
            ),
          ],
        ),
        isEmpty,
      );
    },
  );

  test('author alias comparison and deduplication are case-sensitive', () {
    final List<String> aliases = authorAliases(
      authorName: 'Main',
      links: <AuthorLink>[
        (
          id: 1,
          platform: AuthorLinkPlatform.pixiv,
          url: 'https://pixiv.net/users/1',
          // 与 Author 名仅大小写不同：仍应作为 alias 保留。
          platformDisplayName: 'MAIN',
          sortKey: 0,
        ),
        (
          id: 2,
          platform: AuthorLinkPlatform.x,
          url: 'https://x.com/name',
          // 与上一条仅大小写不同：大小写敏感去重，两条都保留。
          platformDisplayName: 'main',
          sortKey: 0,
        ),
      ],
    );

    expect(aliases, <String>['MAIN', 'main']);
  });

  test(
    'showsAuthorImageView includes platform-only slots without comic fallback',
    () {
      const AuthorImageRef platformOnly = (
        avatarSource: AuthorImageSource.platformCached,
        avatarComicId: null,
        avatarLinkId: 1,
        avatarImageUrl: 'https://img.example/a.png',
        backgroundSource: AuthorImageSource.platformCached,
        backgroundComicId: null,
        backgroundLinkId: 2,
        backgroundImageUrl: 'https://img.example/b.png',
      );

      expect(platformOnly.showsAuthorImageView(AuthorImageSlot.avatar), isTrue);
      expect(
        platformOnly.showsAuthorImageView(AuthorImageSlot.background),
        isTrue,
      );
    },
  );

  test(
    'showsAuthorImageView is false when slot has no comic or platform source',
    () {
      const AuthorImageRef empty = (
        avatarSource: AuthorImageSource.none,
        avatarComicId: null,
        avatarLinkId: null,
        avatarImageUrl: null,
        backgroundSource: AuthorImageSource.none,
        backgroundComicId: null,
        backgroundLinkId: null,
        backgroundImageUrl: null,
      );

      expect(empty.showsAuthorImageView(AuthorImageSlot.avatar), isFalse);
      expect(empty.showsAuthorImageView(AuthorImageSlot.background), isFalse);
    },
  );
}
