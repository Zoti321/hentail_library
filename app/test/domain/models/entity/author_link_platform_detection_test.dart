import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/models/entity/comic/author_detail.dart';

void main() {
  group('detectAuthorLinkPlatform', () {
    test('识别各平台主域名与子域名', () {
      expect(
        detectAuthorLinkPlatform('https://www.pixiv.net/users/123'),
        AuthorLinkPlatform.pixiv,
      );
      expect(
        detectAuthorLinkPlatform('https://x.com/alice'),
        AuthorLinkPlatform.x,
      );
      expect(
        detectAuthorLinkPlatform('https://mobile.twitter.com/alice'),
        AuthorLinkPlatform.x,
      );
      expect(
        detectAuthorLinkPlatform('https://www.patreon.com/alice'),
        AuthorLinkPlatform.patreon,
      );
      expect(
        detectAuthorLinkPlatform('https://alice.fanbox.cc/'),
        AuthorLinkPlatform.fanbox,
      );
      expect(
        detectAuthorLinkPlatform('https://discord.gg/abc'),
        AuthorLinkPlatform.discord,
      );
      expect(
        detectAuthorLinkPlatform('https://discord.com/invite/abc'),
        AuthorLinkPlatform.discord,
      );
    });

    test('pixiv 旧版 fanbox 路径识别为 fanbox', () {
      expect(
        detectAuthorLinkPlatform('https://www.pixiv.net/fanbox/creator/1'),
        AuthorLinkPlatform.fanbox,
      );
    });

    test('大小写不敏感，且不误判相似域名', () {
      expect(
        detectAuthorLinkPlatform('HTTPS://WWW.PIXIV.NET/users/1'),
        AuthorLinkPlatform.pixiv,
      );
      expect(
        detectAuthorLinkPlatform('https://notpixiv.net/a'),
        AuthorLinkPlatform.other,
      );
      expect(
        detectAuthorLinkPlatform('https://box.com/a'),
        AuthorLinkPlatform.other,
      );
    });

    test('未知或无法解析的链接归为 other', () {
      expect(
        detectAuthorLinkPlatform('https://example.org/a'),
        AuthorLinkPlatform.other,
      );
      expect(detectAuthorLinkPlatform('not a url'), AuthorLinkPlatform.other);
    });
  });
}
