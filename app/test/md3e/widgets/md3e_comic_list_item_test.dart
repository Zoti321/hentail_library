import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/theme/md3e_theme.dart';
import 'package:hentai_library/md3e/widgets/catalog/md3e_comic_list_item.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../support/pump_md3e_app.dart';

void main() {
  test('infoProgressWidthFor clamps between min and max when space allows', () {
    expect(Md3eComicListItem.infoProgressWidthFor(300), 240);
    expect(Md3eComicListItem.infoProgressWidthFor(150), 150);
    expect(Md3eComicListItem.infoProgressWidthFor(96), 96);
    expect(Md3eComicListItem.infoProgressWidthFor(72), 72);
  });

  test('metaLine joins author and page with middle dot', () {
    expect(
      Md3eComicListItem.metaLine(author: '深海', pageLabel: '128 页'),
      '深海 · 128 页',
    );
    expect(Md3eComicListItem.metaLine(pageLabel: '64 页'), '64 页');
    expect(Md3eComicListItem.metaLine(author: '无名'), '无名');
    expect(Md3eComicListItem.metaLine(), isNull);
  });

  testWidgets('Md3eComicListItem shows title and meta line', (
    WidgetTester tester,
  ) async {
    await pumpMd3eApp(
      tester,
      home: Md3eComicListItem(
        title: '深海图书馆',
        author: '作者甲',
        pageLabel: '128 页',
        cover: const ColoredBox(color: Color(0xFFE0E0E0)),
      ),
    );
    expect(find.text('深海图书馆'), findsOneWidget);
    expect(find.text('作者甲 · 128 页'), findsOneWidget);
  });

  testWidgets('Md3eComicListItem onTap fires when enabled', (
    WidgetTester tester,
  ) async {
    var tapped = false;
    await pumpMd3eApp(
      tester,
      home: Md3eComicListItem(
        title: '点我',
        cover: const ColoredBox(color: Color(0xFFE0E0E0)),
        onTap: () => tapped = true,
      ),
    );
    await tester.tap(find.text('点我'));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('Md3eComicListItem hides info progress when readProgress is 0',
      (WidgetTester tester) async {
    await pumpMd3eApp(
      tester,
      home: Md3eComicListItem(
        title: '未读',
        readProgress: 0,
        cover: const ColoredBox(color: Color(0xFFE0E0E0)),
      ),
    );
    expect(find.byKey(kMd3eComicListItemInfoProgressKey), findsNothing);
  });

  testWidgets('Md3eComicListItem shows info progress when readProgress > 0',
      (WidgetTester tester) async {
    await pumpMd3eApp(
      tester,
      home: Md3eComicListItem(
        title: '在读',
        readProgress: 0.5,
        cover: const ColoredBox(color: Color(0xFFE0E0E0)),
      ),
    );
    expect(find.byKey(kMd3eComicListItemInfoProgressKey), findsOneWidget);
  });

  testWidgets('Md3eComicListItem shows more menu and opens on tap', (
    WidgetTester tester,
  ) async {
    await pumpMd3eApp(
      tester,
      home: Md3eComicListItem(
        title: '菜单',
        cover: const ColoredBox(color: Color(0xFFE0E0E0)),
        moreMenuEntries: const <Md3eComicListMoreMenuEntry>[
          Md3eComicListMoreMenuEntry(label: '继续阅读'),
        ],
        onTap: () {},
      ),
    );
    expect(find.byType(M3EIconButton), findsOneWidget);
    await tester.tap(find.byType(M3EIconButton));
    await tester.pumpAndSettle();
    expect(find.text('继续阅读'), findsOneWidget);
    final Text menuLabel = tester.widget<Text>(find.text('继续阅读'));
    expect(menuLabel.style?.fontFamily, kMd3eAppFontFamily);
  });

  testWidgets('Md3eComicListItem shows checkbox in selection mode', (
    WidgetTester tester,
  ) async {
    await pumpMd3eApp(
      tester,
      home: Md3eComicListItem(
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
