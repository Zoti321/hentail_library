import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/widgets/inputs/anchored_calendar_date_picker.dart';
import 'package:hentai_library/shared/ui/widgets/inputs/docked_calendar_date_picker.dart';
import 'package:hentai_library/shared/ui/widgets/inputs/embeddable_calendar_date_picker.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

void main() {
  testWidgets('anchored overlay builds with MaterialLocalizations', (
    WidgetTester tester,
  ) async {
    final LayerLink layerLink = LayerLink();
    await tester.binding.setSurfaceSize(const Size(400, 720));
    await tester.pumpWidget(
      M3ETheme(
        data: M3EThemeData.light(),
        child: MaterialApp(
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const <Locale>[Locale('en'), Locale('zh')],
          home: Scaffold(
            body: Center(
              child: CompositedTransformTarget(
                link: layerLink,
                child: const SizedBox(width: 280, height: 56),
              ),
            ),
          ),
        ),
      ),
    );

    md3eShowAnchoredCalendarDatePicker(
      context: tester.element(find.byType(SizedBox)),
      layerLink: layerLink,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      onDateChanged: (_) {},
    );
    await tester.pumpAndSettle();

    expect(find.byType(Md3eEmbeddableCalendarDatePicker), findsOneWidget);
  });

  testWidgets('docked picker lays out within constraints', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      M3ETheme(
        data: M3EThemeData.light(),
        child: MaterialApp(
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const <Locale>[Locale('en')],
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 420,
              child: Md3eDockedCalendarDatePicker(
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                onDateChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Md3eEmbeddableCalendarDatePicker), findsOneWidget);
  });
}
