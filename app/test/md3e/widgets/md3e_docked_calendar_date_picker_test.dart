import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_anchored_calendar_date_picker.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_docked_calendar_date_picker.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_embeddable_calendar_date_picker.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart' as mui;

void main() {
  testWidgets('anchored overlay builds with material_ui MaterialLocalizations', (
    WidgetTester tester,
  ) async {
    final LayerLink layerLink = LayerLink();
    await tester.binding.setSurfaceSize(const Size(400, 720));
    await tester.pumpWidget(
      M3ETheme(
        data: M3EThemeData.light(),
        child: mui.MaterialApp(
          localizationsDelegates: mui.GlobalMaterialLocalizations.delegates,
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

    final BuildContext context = tester.element(find.byType(SizedBox));

    md3eShowAnchoredCalendarDatePicker(
      context: context,
      layerLink: layerLink,
      firstDate: kMd3ePublishedDatePickerFirstDate,
      lastDate: kMd3ePublishedDatePickerLastDate,
      onDateChanged: (_) {},
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(Md3eEmbeddableCalendarDatePicker), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });
}
