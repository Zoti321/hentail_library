import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_anchored_calendar_date_picker.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_docked_calendar_date_picker.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_embeddable_calendar_date_picker.dart';
import 'package:hentai_library/md3e/widgets/menu/md3e_anchored_menu.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart' as mui;

void main() {
  testWidgets('anchored overlay builds with material_ui MaterialLocalizations', (
    WidgetTester tester,
  ) async {
    final GlobalKey anchorKey = GlobalKey();
    await tester.binding.setSurfaceSize(const Size(400, 720));
    await tester.pumpWidget(
      M3ETheme(
        data: M3EThemeData.light(),
        child: mui.MaterialApp(
          localizationsDelegates: mui.GlobalMaterialLocalizations.delegates,
          supportedLocales: const <Locale>[Locale('en'), Locale('zh')],
          home: Scaffold(
            body: Center(
              child: KeyedSubtree(
                key: anchorKey,
                child: const SizedBox(width: 280, height: 56),
              ),
            ),
          ),
        ),
      ),
    );

    final BuildContext anchorContext = tester.element(find.byKey(anchorKey));
    final Rect? anchor = md3eMenuAnchorRectFor(anchorContext);
    expect(anchor, isNotNull);

    md3eShowAnchoredCalendarDatePicker(
      context: anchorContext,
      anchor: anchor!,
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
