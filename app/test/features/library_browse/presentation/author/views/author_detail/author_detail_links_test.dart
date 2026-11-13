import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/comic_metadata/public/comic_metadata_entities.dart';
import 'package:hentai_library/features/library_browse/presentation/author/views/author_detail/author_detail_links.dart';
import 'package:hentai_library/features/library_browse/presentation/providers/author_link_providers.dart';
import 'package:hentai_library/l10n/app_localizations.dart';

import '../../../../../../support/pump_localized_app.dart';

const _url = 'https://example.com/artist?id=42#gallery';
const _label = 'Portfolio';
const _detail = AuthorDetail(
  id: 1,
  name: 'Alice',
  verified: false,
  links: [
    (
      id: 7,
      platform: AuthorLinkPlatform.other,
      url: _url,
      platformDisplayName: _label,
      sortKey: 0,
    ),
  ],
  tags: [],
  parodies: [],
  characters: [],
  topComics: [],
  comicCount: 0,
  image: (
    avatarSource: AuthorImageSource.none,
    avatarComicId: null,
    avatarLinkId: null,
    avatarImageUrl: null,
    backgroundSource: AuthorImageSource.none,
    backgroundComicId: null,
    backgroundLinkId: null,
    backgroundImageUrl: null,
  ),
);

void main() {
  testWidgets('rendering is inert and a click opens the exact URL once', (
    tester,
  ) async {
    final response = Completer<void>();
    final calls = <String>[];
    final l10n = await _pumpLinks(tester, (url) {
      calls.add(url);
      return response.future;
    });
    expect(find.text(_label), findsOneWidget);
    expect(calls, isEmpty);

    await tester.tap(find.text(_label));
    await tester.pump();
    expect(calls, [_url]);
    response.complete();
    await tester.pumpAndSettle();
    expect(calls, [_url]);
    expect(find.text(l10n.authorDetailOpenLinkFailed), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'opening failures show the localized message without technical details',
    (tester) async {
      final calls = <String>[];
      final l10n = await _pumpLinks(tester, (url) async {
        calls.add(url);
        throw StateError('private-platform-failure');
      });
      await tester.tap(find.text(_label));
      await tester.pumpAndSettle();
      expect(calls, [_url]);
      expect(find.text(l10n.authorDetailOpenLinkFailed), findsOneWidget);
      expect(find.textContaining('private-platform-failure'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a late opening failure after unmount does not show feedback', (
    tester,
  ) async {
    final response = Completer<void>();
    final visible = ValueNotifier(true);
    addTearDown(visible.dispose);
    final calls = <String>[];
    final l10n = await _pumpLinks(tester, (url) {
      calls.add(url);
      return response.future;
    }, visible: visible);
    await tester.tap(find.text(_label));
    await tester.pump();
    expect(calls, [_url]);
    visible.value = false;
    await tester.pumpAndSettle();
    expect(find.byType(AuthorDetailLinks), findsNothing);

    response.completeError(StateError('private-platform-failure'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.authorDetailOpenLinkFailed), findsNothing);
    expect(find.textContaining('private-platform-failure'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<AppLocalizations> _pumpLinks(
  WidgetTester tester,
  Future<void> Function(String) open, {
  ValueNotifier<bool>? visible,
}) async {
  const links = AuthorDetailLinks(detail: _detail);
  await pumpLocalizedApp(
    tester,
    overrides: [openAuthorLinkCommandProvider.overrideWithValue(open)],
    home: Scaffold(
      body: visible == null
          ? links
          : ValueListenableBuilder<bool>(
              valueListenable: visible,
              child: links,
              builder: (_, show, child) =>
                  show ? child! : const SizedBox.shrink(),
            ),
    ),
  );
  await tester.pumpAndSettle();
  return AppLocalizations.of(tester.element(find.byType(Scaffold)));
}
