import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/pages/md3e_settings_page.dart';
import 'package:hentai_library/md3e/patterns/settings/md3e_settings_catalog.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../support/pump_md3e_app.dart';

void main() {
  testWidgets('expanded width shows master and detail panes', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpMd3eApp(
      tester,
      home: const Center(
        child: SizedBox(
          width: 1280,
          height: 800,
          child: Md3eSettingsPage(
            initialCategory: Md3eSettingsCategory.personalization,
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('md3e_settings_master')), findsOneWidget);
    expect(find.byKey(const Key('md3e_settings_detail')), findsOneWidget);
    expect(find.byIcon(Symbols.arrow_back), findsNothing);
  });

  testWidgets('compact width shows master list first', (
    WidgetTester tester,
  ) async {
    await pumpMd3eApp(
      tester,
      home: const SizedBox(width: 390, height: 800, child: Md3eSettingsPage()),
    );
    expect(find.byKey(const Key('md3e_settings_master')), findsOneWidget);
    expect(find.byKey(const Key('md3e_settings_detail')), findsNothing);
  });

  testWidgets(
    'compact list back button calls onBack; detail back returns to list',
    (WidgetTester tester) async {
      int backCount = 0;
      await pumpMd3eApp(
        tester,
        home: SizedBox(
          width: 390,
          height: 800,
          child: Md3eSettingsPage(onBack: () => backCount++),
        ),
      );
      expect(find.byIcon(Symbols.arrow_back), findsOneWidget);

      await tester.tap(
        find
            .descendant(
              of: find.byKey(const Key('md3e_settings_master')),
              matching: find.byType(InkWell),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('md3e_settings_detail')), findsOneWidget);
      expect(backCount, 0);

      await tester.tap(find.byIcon(Symbols.arrow_back));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('md3e_settings_master')), findsOneWidget);
      expect(find.byKey(const Key('md3e_settings_detail')), findsNothing);
      expect(backCount, 0);

      await tester.tap(find.byIcon(Symbols.arrow_back));
      await tester.pumpAndSettle();
      expect(backCount, 1);
    },
  );

  testWidgets(
    'compact system back on detail returns to list, on list calls onBack',
    (WidgetTester tester) async {
      int backCount = 0;
      await pumpMd3eApp(
        tester,
        home: SizedBox(
          width: 390,
          height: 800,
          child: Md3eSettingsPage(onBack: () => backCount++),
        ),
      );

      await tester.tap(
        find
            .descendant(
              of: find.byKey(const Key('md3e_settings_master')),
              matching: find.byType(InkWell),
            )
            .first,
      );
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('md3e_settings_master')), findsOneWidget);
      expect(backCount, 0);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(backCount, 1);
    },
  );
}
