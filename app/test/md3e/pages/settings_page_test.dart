import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/app_settings/presentation/views/settings_page/settings_page_body.dart';
import 'package:hentai_library/features/app_settings/presentation/patterns/settings/settings_catalog.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('expanded width shows master and detail panes', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpApp(
      tester,
      home: const Center(
        child: SizedBox(
          width: 1280,
          height: 800,
          child: SettingsLayout(
            initialCategory: SettingsCategory.personalization,
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('_settings_master')), findsOneWidget);
    expect(find.byKey(const Key('_settings_detail')), findsOneWidget);
    expect(find.byIcon(Symbols.arrow_back), findsNothing);
  });

  testWidgets('compact width shows master list first', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      home: const SizedBox(width: 390, height: 800, child: SettingsLayout()),
    );
    expect(find.byKey(const Key('_settings_master')), findsOneWidget);
    expect(find.byKey(const Key('_settings_detail')), findsNothing);
  });

  testWidgets(
    'compact root hides back; detail back returns to list; system back calls onBack',
    (WidgetTester tester) async {
      int backCount = 0;
      await pumpApp(
        tester,
        home: SizedBox(
          width: 390,
          height: 800,
          child: SettingsLayout(onBack: () => backCount++),
        ),
      );
      expect(find.byIcon(Symbols.arrow_back), findsNothing);

      await tester.tap(
        find
            .descendant(
              of: find.byKey(const Key('_settings_master')),
              matching: find.byType(InkWell),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('_settings_detail')), findsOneWidget);
      expect(find.byIcon(Symbols.arrow_back), findsOneWidget);
      expect(backCount, 0);

      await tester.tap(find.byIcon(Symbols.arrow_back));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('_settings_master')), findsOneWidget);
      expect(find.byKey(const Key('_settings_detail')), findsNothing);
      expect(find.byIcon(Symbols.arrow_back), findsNothing);
      expect(backCount, 0);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(backCount, 1);
    },
  );

  testWidgets(
    'compact system back on detail returns to list, on list calls onBack',
    (WidgetTester tester) async {
      int backCount = 0;
      await pumpApp(
        tester,
        home: SizedBox(
          width: 390,
          height: 800,
          child: SettingsLayout(onBack: () => backCount++),
        ),
      );

      await tester.tap(
        find
            .descendant(
              of: find.byKey(const Key('_settings_master')),
              matching: find.byType(InkWell),
            )
            .first,
      );
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('_settings_master')), findsOneWidget);
      expect(backCount, 0);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(backCount, 1);
    },
  );
}
