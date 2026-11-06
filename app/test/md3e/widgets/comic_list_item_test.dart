import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../widgetbook/lab/theme/md3e_theme.dart';

import 'package:hentai_library/shared/ui/widgets/catalog/comic_list_item.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../support/pump_app.dart';

void main() {
  test('infoProgressWidthFor caps width without filling column', () {
    expect(ComicListItem.infoProgressWidthFor(300), 160);
    expect(ComicListItem.infoProgressWidthFor(120), 120);
    expect(ComicListItem.infoProgressWidthFor(72), 72);
  });

  test('metaLine joins author and page with middle dot', () {
    expect(
      ComicListItem.metaLine(author: '深海', pageLabel: '128 页'),
      '深海 · 128 页',
    );
    expect(ComicListItem.metaLine(pageLabel: '64 页'), '64 页');
    expect(ComicListItem.metaLine(author: '无名'), '无名');
    expect(ComicListItem.metaLine(), isNull);
  });

  testWidgets('ComicListItem shows title and meta line', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      home: ComicListItem(
        title: '深海图书馆',
        author: '作者甲',
        pageLabel: '128 页',
        cover: const ColoredBox(color: Color(0xFFE0E0E0)),
      ),
    );
    expect(find.text('深海图书馆'), findsOneWidget);
    expect(find.text('作者甲 · 128 页'), findsOneWidget);
  });

  testWidgets('ComicListItem onTap fires when enabled', (
    WidgetTester tester,
  ) async {
    var tapped = false;
    await pumpApp(
      tester,
      home: ComicListItem(
        title: '点我',
        cover: const ColoredBox(color: Color(0xFFE0E0E0)),
        onTap: () => tapped = true,
      ),
    );
    await tester.tap(find.text('点我'));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('ComicListItem hides info progress when readProgress is 0', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      home: ComicListItem(
        title: '未读',
        readProgress: 0,
        cover: const ColoredBox(color: Color(0xFFE0E0E0)),
      ),
    );
    expect(find.byKey(kComicListItemInfoProgressKey), findsNothing);
  });

  testWidgets('ComicListItem shows info progress when readProgress > 0', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      home: ComicListItem(
        title: '在读',
        readProgress: 0.5,
        cover: const ColoredBox(color: Color(0xFFE0E0E0)),
      ),
    );
    expect(find.byKey(kComicListItemInfoProgressKey), findsOneWidget);
  });

  testWidgets('ComicListItem shows more menu and opens on tap', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      home: ComicListItem(
        title: '菜单',
        cover: const ColoredBox(color: Color(0xFFE0E0E0)),
        moreMenuEntries: const <ComicListMoreMenuEntry>[
          ComicListMoreMenuEntry(label: '继续阅读'),
        ],
        onTap: () {},
      ),
    );
    expect(find.byType(M3EIconButton), findsOneWidget);
    await tester.tap(find.byType(M3EIconButton));
    await tester.pumpAndSettle();
    expect(find.text('继续阅读'), findsOneWidget);
    final Text menuLabel = tester.widget<Text>(find.text('继续阅读'));
    expect(menuLabel.style?.fontFamily, kAppFontFamily);
  });

  testWidgets('ComicListItem shows checkbox in selection mode', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      home: ComicListItem(
        title: '多选',
        selectionMode: true,
        selected: true,
        cover: const ColoredBox(color: Color(0xFFE0E0E0)),
        onSelectionChanged: (_) {},
      ),
    );
    expect(find.byType(M3ECheckbox), findsOneWidget);
  });
}
