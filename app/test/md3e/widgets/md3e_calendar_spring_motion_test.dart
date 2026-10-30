import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/motion/md3e_spring_value.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_embeddable_calendar_date_picker.dart';
import 'package:material_3_expressive/components/date_pickers/components/m3e_date_picker_mode_toggle.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart' as mui;

Future<void> _pumpCalendar(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    M3ETheme(
      data: M3EThemeData.light(),
      child: mui.MaterialApp(
        localizationsDelegates: mui.GlobalMaterialLocalizations.delegates,
        supportedLocales: const <Locale>[Locale('en'), Locale('zh')],
        home: Scaffold(
          body: SingleChildScrollView(
            child: Md3eEmbeddableCalendarDatePicker(
              initialDate: DateTime(2024, 3, 15),
              firstDate: DateTime(2020, 1, 1),
              lastDate: DateTime(2030, 12, 31),
              currentDate: DateTime(2024, 3, 15),
              onDateChanged: (_) {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 展开区域（Md3eSpringValue 外层 SizedBox）的高度。
double _bodyHeight(WidgetTester tester) => tester
    .getSize(
      find
          .descendant(
            of: find.byType(Md3eSpringValue),
            matching: find.byType(SizedBox),
          )
          .first,
    )
    .height;

void main() {
  testWidgets(
    'expanding to year view overshoots the target height mid-animation',
    (WidgetTester tester) async {
      await _pumpCalendar(tester);
      final double start = _bodyHeight(tester);

      await tester.tap(find.byType(M3EDatePickerModeToggle));
      await tester.pump();
      final List<double> heights = <double>[];
      for (int i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 8));
        heights.add(_bodyHeight(tester));
      }
      await tester.pumpAndSettle();
      final double target = _bodyHeight(tester);

      expect(target, isNot(closeTo(start, 1)), reason: '年视图高度应与日视图不同');
      final double extreme = target > start
          ? heights.reduce((double a, double b) => a > b ? a : b)
          : heights.reduce((double a, double b) => a < b ? a : b);
      // 弹簧回弹：中间帧越过终点。
      if (target > start) {
        expect(extreme, greaterThan(target + 0.5), reason: '展开应有回弹过冲');
      } else {
        expect(extreme, lessThan(target - 0.5), reason: '收起应有回弹过冲');
      }
    },
  );

  testWidgets('next month paging overshoots page 1 then settles on it', (
    WidgetTester tester,
  ) async {
    await _pumpCalendar(tester);
    final PageView pageView = tester.widget<PageView>(find.byType(PageView));
    final PageController controller = pageView.controller!;
    final double before = controller.page!;

    await tester.tap(find.byIcon(M3EIcons.chevron_right));
    await tester.pump();
    final List<double> pages = <double>[];
    for (int i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 8));
      pages.add(controller.page!);
    }
    await tester.pumpAndSettle();

    expect(controller.page, closeTo(before + 1, 0.001), reason: '应翻到下一个月');
    final double maxPage = pages.reduce((double a, double b) => a > b ? a : b);
    expect(maxPage, greaterThan(before + 1 + 0.005), reason: '月份翻页应有回弹过冲');
  });
}
