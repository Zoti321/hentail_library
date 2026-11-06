import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../widgetbook/lab/theme/md3e_theme.dart';

import 'package:hentai_library/shared/ui/widgets/catalog/comic_card.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('ComicCard shows title and subtitle', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      home: Center(
        child: SizedBox(
          width: 160,
          child: ComicCard(
            title: '深海图书馆',
            subtitle: '128 页',
            cover: const ColoredBox(color: Color(0xFFE0E0E0)),
          ),
        ),
      ),
    );
    expect(find.text('深海图书馆'), findsOneWidget);
    expect(find.text('128 页'), findsOneWidget);
    final Text title = tester.widget<Text>(find.text('深海图书馆'));
    expect(title.style?.fontFamily, kAppFontFamily);
  });

  testWidgets('ComicCard onTap fires when enabled', (
    WidgetTester tester,
  ) async {
    var tapped = false;
    await pumpApp(
      tester,
      home: Center(
        child: SizedBox(
          width: 160,
          child: ComicCard(
            title: '点我',
            cover: const ColoredBox(color: Color(0xFFE0E0E0)),
            onTap: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('点我'));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('ComicCard shows checkbox in selection mode', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      home: Center(
        child: SizedBox(
          width: 160,
          child: ComicCard(
            title: '多选',
            selectionMode: true,
            selected: true,
            cover: const ColoredBox(color: Color(0xFFE0E0E0)),
            onSelectionChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.byType(M3ECheckbox), findsOneWidget);
    final M3ECheckbox checkbox = tester.widget<M3ECheckbox>(
      find.byType(M3ECheckbox),
    );
    expect(checkbox.value, isTrue);
  });

  test('showsCoverReadProgress is false for null and zero', () {
    expect(ComicCard.showsCoverReadProgress(null), isFalse);
    expect(ComicCard.showsCoverReadProgress(0), isFalse);
    expect(ComicCard.showsCoverReadProgress(0.0), isFalse);
    expect(ComicCard.showsCoverReadProgress(0.01), isTrue);
  });

  testWidgets('ComicCard hides cover progress when readProgress is null', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      home: Center(
        child: SizedBox(
          width: 160,
          child: ComicCard(
            title: '未读',
            cover: const ColoredBox(color: Color(0xFFE0E0E0)),
          ),
        ),
      ),
    );
    expect(find.byKey(kComicCardCoverProgressKey), findsNothing);
  });

  testWidgets('ComicCard hides cover progress when readProgress is 0', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      home: Center(
        child: SizedBox(
          width: 160,
          child: ComicCard(
            title: '未开始',
            readProgress: 0,
            cover: const ColoredBox(color: Color(0xFFE0E0E0)),
          ),
        ),
      ),
    );
    expect(find.byKey(kComicCardCoverProgressKey), findsNothing);
  });

  testWidgets(
    'ComicCard shows cover progress strip when readProgress > 0',
    (WidgetTester tester) async {
      await pumpApp(
        tester,
        home: Center(
          child: SizedBox(
            width: 160,
            child: ComicCard(
              title: '在读',
              readProgress: 0.5,
              cover: const ColoredBox(color: Color(0xFFE0E0E0)),
            ),
          ),
        ),
      );
      expect(find.byKey(kComicCardCoverProgressKey), findsOneWidget);
    },
  );

  testWidgets('ComicCard does not tap when disabled', (
    WidgetTester tester,
  ) async {
    var tapped = false;
    await pumpApp(
      tester,
      home: Center(
        child: SizedBox(
          width: 160,
          child: ComicCard(
            title: '禁用',
            enabled: false,
            cover: const ColoredBox(color: Color(0xFFE0E0E0)),
            onTap: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('禁用'));
    await tester.pump();
    expect(tapped, isFalse);
  });
}
