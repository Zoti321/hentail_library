import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/widgets/md3e_comic_card.dart';

import '../../support/pump_md3e_app.dart';

void main() {
  testWidgets('Md3eComicCard shows title and subtitle', (
    WidgetTester tester,
  ) async {
    await pumpMd3eApp(
      tester,
      home: Center(
        child: SizedBox(
          width: 160,
          child: Md3eComicCard(
            title: '深海图书馆',
            subtitle: '128 页',
            cover: const ColoredBox(color: Color(0xFFE0E0E0)),
          ),
        ),
      ),
    );
    expect(find.text('深海图书馆'), findsOneWidget);
    expect(find.text('128 页'), findsOneWidget);
  });

  testWidgets('Md3eComicCard onTap fires when enabled', (
    WidgetTester tester,
  ) async {
    var tapped = false;
    await pumpMd3eApp(
      tester,
      home: Center(
        child: SizedBox(
          width: 160,
          child: Md3eComicCard(
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

  testWidgets('Md3eComicCard shows checkbox in selection mode', (
    WidgetTester tester,
  ) async {
    await pumpMd3eApp(
      tester,
      home: Center(
        child: SizedBox(
          width: 160,
          child: Md3eComicCard(
            title: '多选',
            selectionMode: true,
            selected: true,
            cover: const ColoredBox(color: Color(0xFFE0E0E0)),
            onSelectionChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.byType(Checkbox), findsOneWidget);
    final Checkbox checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, isTrue);
  });

  test('showsCoverReadProgress is false for null and zero', () {
    expect(Md3eComicCard.showsCoverReadProgress(null), isFalse);
    expect(Md3eComicCard.showsCoverReadProgress(0), isFalse);
    expect(Md3eComicCard.showsCoverReadProgress(0.0), isFalse);
    expect(Md3eComicCard.showsCoverReadProgress(0.01), isTrue);
  });

  testWidgets('Md3eComicCard hides cover progress when readProgress is null',
      (WidgetTester tester) async {
    await pumpMd3eApp(
      tester,
      home: Center(
        child: SizedBox(
          width: 160,
          child: Md3eComicCard(
            title: '未读',
            cover: const ColoredBox(color: Color(0xFFE0E0E0)),
          ),
        ),
      ),
    );
    expect(find.byKey(kMd3eComicCardCoverProgressKey), findsNothing);
  });

  testWidgets('Md3eComicCard hides cover progress when readProgress is 0',
      (WidgetTester tester) async {
    await pumpMd3eApp(
      tester,
      home: Center(
        child: SizedBox(
          width: 160,
          child: Md3eComicCard(
            title: '未开始',
            readProgress: 0,
            cover: const ColoredBox(color: Color(0xFFE0E0E0)),
          ),
        ),
      ),
    );
    expect(find.byKey(kMd3eComicCardCoverProgressKey), findsNothing);
  });

  testWidgets('Md3eComicCard shows cover progress strip when readProgress > 0',
      (WidgetTester tester) async {
    await pumpMd3eApp(
      tester,
      home: Center(
        child: SizedBox(
          width: 160,
          child: Md3eComicCard(
            title: '在读',
            readProgress: 0.5,
            cover: const ColoredBox(color: Color(0xFFE0E0E0)),
          ),
        ),
      ),
    );
    expect(find.byKey(kMd3eComicCardCoverProgressKey), findsOneWidget);
  });

  testWidgets('Md3eComicCard does not tap when disabled', (
    WidgetTester tester,
  ) async {
    var tapped = false;
    await pumpMd3eApp(
      tester,
      home: Center(
        child: SizedBox(
          width: 160,
          child: Md3eComicCard(
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
