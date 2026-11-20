import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/design-system/design_system.dart';

import '../../../support/pump_design_system_app.dart';

void main() {
  Finder day(String date) => find.byKey(ValueKey('calendar-date-$date'));
  Future<void> surface(
    WidgetTester tester, {
    bool modal = false,
    DateTime? initial,
    DatePickerEntryMode entry = DatePickerEntryMode.calendar,
    ValueChanged<DateTime>? confirmed,
    Locale locale = const Locale('en'),
  }) => pumpDesignSystemApp(
    tester,
    locale: locale,
    supportedLocales: const [
      Locale('en'),
      Locale('zh'),
      Locale('fr'),
      Locale('ar'),
    ],
    home: Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          width: 360,
          child: CalendarDatePickerSurface(
            modal: modal,
            initialEntryMode: entry,
            initialDate: initial ?? DateTime(2024, 3, 15),
            firstDate: DateTime(2020),
            lastDate: DateTime(2030, 12, 31),
            onConfirmed: confirmed ?? (_) {},
            onCancel: () {},
          ),
        ),
      ),
    ),
  );

  testWidgets(
    'docked month and year menus navigate independently without committing',
    (tester) async {
      final changes = <DateTime>[];
      await surface(tester, confirmed: changes.add);
      await tester.tap(find.byKey(const ValueKey('calendar-month-menu')));
      await tester.pumpAndSettle();
      expect(find.text('January'), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(
              find.byKey(const ValueKey('calendar-year-menu')),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('May'));
      await tester.pumpAndSettle();
      expect(day('2024-05-15'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('calendar-year-menu')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextButton>(
              find.byKey(const ValueKey('calendar-month-menu')),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('2025').last);
      await tester.pumpAndSettle();
      expect(day('2025-05-20'), findsOneWidget);
      await tester.tap(day('2025-05-20'));
      await tester.pumpAndSettle();
      expect(changes, isEmpty);
      await tester.tap(find.text('OK'));
      expect(changes, [DateTime(2025, 5, 20)]);
    },
  );

  for (final monthView in [true, false]) {
    testWidgets(
      'docked ${monthView ? 'month' : 'year'} menu separates check, labels and scrollbar',
      (tester) async {
        await surface(tester);
        final menuKey = ValueKey(
          monthView ? 'calendar-month-menu' : 'calendar-year-menu',
        );
        final otherKey = ValueKey(
          monthView ? 'calendar-year-menu' : 'calendar-month-menu',
        );
        await tester.tap(find.byKey(menuKey));
        await tester.pumpAndSettle();
        final selected = find.byKey(
          ValueKey('calendar-menu-item-${monthView ? 3 : 2024}'),
        );
        final check = find.descendant(
          of: selected,
          matching: find.byIcon(Icons.check),
        );
        final selectedLabel = find.descendant(
          of: selected,
          matching: find.byType(Text),
        );
        final nextLabel = find.descendant(
          of: find.byKey(
            ValueKey('calendar-menu-item-${monthView ? 4 : 2025}'),
          ),
          matching: find.byType(Text),
        );
        expect(check, findsOneWidget);
        expect(
          tester.getRect(check).right,
          lessThan(tester.getRect(selectedLabel).left),
        );
        expect(
          tester.getRect(selectedLabel).left,
          tester.getRect(nextLabel).left,
        );
        final panel = tester.getRect(
          find.byKey(const ValueKey('calendar-surface')),
        );
        expect(
          tester.getRect(check).left - panel.left,
          greaterThanOrEqualTo(24),
        );
        final scrollbar = find.byType(RawScrollbar);
        expect(scrollbar, findsOneWidget);
        expect(
          tester.getRect(scrollbar).right - tester.getRect(selected).right,
          greaterThanOrEqualTo(16),
        );
        expect(find.byIcon(Icons.chevron_left).hitTestable(), findsNothing);
        expect(find.byIcon(Icons.chevron_right).hitTestable(), findsNothing);
        expect(
          find
              .descendant(of: find.byKey(otherKey), matching: find.byType(Icon))
              .hitTestable(),
          findsNothing,
        );
        expect(
          find
              .descendant(
                of: find.byKey(menuKey),
                matching: find.byIcon(Icons.arrow_drop_up),
              )
              .hitTestable(),
          findsOneWidget,
        );
        await tester.tap(
          find.descendant(of: selected, matching: find.byType(TextButton)),
        );
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.chevron_left).hitTestable(), findsNWidgets(2));
      },
    );
  }

  testWidgets(
    'date state layers render above selected fill and leave disabled cells unchanged',
    (tester) async {
      await surface(tester);
      await tester.pumpAndSettle();
      final monthButton = tester.widget<TextButton>(
        find.byKey(const ValueKey('calendar-month-menu')),
      );
      monthButton.focusNode!.requestFocus();
      await tester.pumpAndSettle();
      Future<Color> pixel(Finder cell) async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byType(RepaintBoundary).first,
        );
        final point = boundary.globalToLocal(
          tester.getCenter(cell) + const Offset(0, -12),
        );
        return (await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          final index = (point.dy.floor() * image.width + point.dx.floor()) * 4;
          final color = Color.fromARGB(
            bytes.getUint8(index + 3),
            bytes.getUint8(index),
            bytes.getUint8(index + 1),
            bytes.getUint8(index + 2),
          );
          image.dispose();
          return color;
        }))!;
      }

      final mouse = await tester.createGesture(
        kind: ui.PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: const Offset(790, 590));
      for (final date in ['2024-03-15', '2024-03-20']) {
        final cell = day(date);
        final normal = await pixel(cell);
        await mouse.moveTo(tester.getCenter(cell));
        await tester.pumpAndSettle();
        expect(
          await pixel(cell),
          isNot(normal),
          reason: '$date hover must be visible',
        );
        await mouse.moveTo(const Offset(790, 590));
        await tester.pumpAndSettle();
        expect(await pixel(cell), normal);
        final press = await tester.startGesture(tester.getCenter(cell));
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          await pixel(cell),
          isNot(normal),
          reason: '$date press must be visible',
        );
        await press.cancel();
        await tester.pumpAndSettle();
      }
      final disabled = day('2024-02-25');
      final before = await pixel(disabled);
      await mouse.moveTo(tester.getCenter(disabled));
      await tester.pumpAndSettle();
      expect(await pixel(disabled), before);
      await mouse.removePointer();
      final selected = day('2024-03-15');
      final beforeFocus = await pixel(selected);
      tester
          .widget<Focus>(find.byKey(const ValueKey('calendar-day-grid')))
          .focusNode!
          .requestFocus();
      await tester.pumpAndSettle();
      expect(await pixel(selected), isNot(beforeFocus));
    },
  );

  testWidgets('docked surface has a medium rounded outline', (tester) async {
    await surface(tester);
    final material = tester.widget<Material>(
      find.byKey(const ValueKey('calendar-surface')),
    );
    expect(material.borderRadius, BorderRadius.circular(16));
    expect(material.clipBehavior, Clip.antiAlias);
  });

  testWidgets(
    'docked grid includes disabled outside dates and adjusts week rows',
    (tester) async {
      await surface(tester, initial: DateTime(2026, 2, 15));
      await tester.pumpAndSettle();
      final februaryHeight = tester
          .getSize(find.byKey(const ValueKey('calendar-surface')))
          .height;
      await tester.tap(find.byKey(const ValueKey('calendar-month-menu')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('August'),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('August'));
      await tester.pumpAndSettle();
      final augustHeight = tester
          .getSize(find.byKey(const ValueKey('calendar-surface')))
          .height;
      expect(augustHeight - februaryHeight, closeTo(96, 1));
      expect(day('2026-07-26'), findsOneWidget);
      final handle = tester.ensureSemantics();

      final semantics = tester.getSemantics(day('2026-07-26'));
      expect(
        semantics.getSemanticsData().hasAction(ui.SemanticsAction.tap),
        isFalse,
      );
      handle.dispose();
    },
  );

  testWidgets(
    'modal has header, swipe navigation and preserves draft through input',
    (tester) async {
      final changes = <DateTime>[];
      await surface(tester, modal: true, confirmed: changes.add);
      expect(find.text('Select date'), findsOneWidget);
      expect(find.text('Fri, Mar 15'), findsOneWidget);
      await tester.fling(
        find.byKey(const ValueKey('calendar-day-grid')),
        const Offset(-250, 0),
        600,
      );
      await tester.pumpAndSettle();
      expect(find.text('April 2024'), findsOneWidget);
      await tester.tap(day('2024-04-20'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('calendar-input-toggle')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        '4/20/2024',
      );
      await tester.enterText(find.byType(TextFormField), '02/30/2024');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('Invalid format.'), findsOneWidget);
      expect(changes, isEmpty);
      await tester.enterText(find.byType(TextFormField), '2024.02.29');
      await tester.tap(find.byKey(const ValueKey('calendar-input-toggle')));
      await tester.pumpAndSettle();
      expect(find.text('February 2024'), findsOneWidget);
      await tester.tap(find.text('OK'));
      expect(changes, [DateTime(2024, 2, 29)]);
    },
  );

  testWidgets(
    'keyboard handles arrows, month/year paging, Home/End and submit',
    (tester) async {
      final changes = <DateTime>[];
      await surface(tester, confirmed: changes.add);
      await tester.pumpAndSettle();
      final grid = tester.widget<Focus>(
        find.byKey(const ValueKey('calendar-day-grid')),
      );
      grid.focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pumpAndSettle();
      expect(find.text('Apr'), findsOneWidget);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(find.text('2025'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(changes, [DateTime(2025, 4, 9)]);
    },
  );

  for (final locale in [
    const Locale('en'),
    const Locale('zh'),
    const Locale('fr'),
    const Locale('ar'),
  ]) {
    testWidgets('localized month menu and input round trip in $locale', (
      tester,
    ) async {
      final changes = <DateTime>[];
      await surface(
        tester,
        modal: true,
        locale: locale,
        entry: DatePickerEntryMode.input,
        initial: DateTime(2024, 2, 29),
        confirmed: changes.add,
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(TextFormField));
      final l10n = MaterialLocalizations.of(context);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        l10n.formatCompactDate(DateTime(2024, 2, 29)),
      );
      await tester.tap(find.byKey(const ValueKey('calendar-input-toggle')));
      await tester.pumpAndSettle();
      expect(
        find.text(l10n.formatMonthYear(DateTime(2024, 2))),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text(l10n.okButtonLabel));
      await tester.tap(find.text(l10n.okButtonLabel));
      expect(changes, [DateTime(2024, 2, 29)]);
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in [
    const Size(320, 700),
    const Size(390, 800),
    const Size(599, 700),
    const Size(600, 700),
    const Size(840, 500),
    const Size(1600, 1000),
  ]) {
    testWidgets(
      'cancel preserves field; surface stays inside viewport at $size',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final changes = <String>[];
        await pumpDesignSystemApp(
          tester,
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomRight,
              child: SizedBox(
                width: 280,
                child: PublishedDateTextField(
                  label: 'Date',
                  value: '2024-03-15',
                  onChanged: changes.add,
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.byType(Icon).last);
        await tester.pumpAndSettle();
        expect(find.byType(CalendarDatePickerSurface), findsOneWidget);
        final rect = tester.getRect(
          find.byKey(const ValueKey('calendar-surface')),
        );
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(size.width));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.bottom, lessThanOrEqualTo(size.height));
        await tester.tap(day('2024-03-20'));
        await tester.pumpAndSettle();
        expect(changes, isEmpty);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byType(CalendarDatePickerSurface), findsNothing);
        expect(changes, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('out-of-range input cannot confirm', (tester) async {
    final changes = <DateTime>[];
    await surface(
      tester,
      modal: true,
      entry: DatePickerEntryMode.input,
      confirmed: changes.add,
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '01/01/2019');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(changes, isEmpty);
    expect(find.text('Out of range.'), findsOneWidget);
  });

  testWidgets(
    'large text and reduced motion fit without lingering transitions',
    (tester) async {
      await pumpDesignSystemApp(
        tester,
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: SingleChildScrollView(
              child: SizedBox(
                width: 360,
                child: CalendarDatePickerSurface(
                  initialDate: DateTime(2024, 2, 29),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  onConfirmed: (_) {},
                  onCancel: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('calendar-year-menu')));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.byType(AnimatedSize), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('docked field confirmation emits once and dismisses', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final changes = <String>[];
    await pumpDesignSystemApp(
      tester,
      locale: const Locale('en'),
      home: Scaffold(
        body: SizedBox(
          width: 360,
          child: PublishedDateTextField(
            label: 'Date',
            value: '2024-03-15',
            onChanged: changes.add,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(Icon).last);
    await tester.pumpAndSettle();
    await tester.tap(day('2024-03-20'));
    await tester.pumpAndSettle();
    expect(changes, isEmpty);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(changes, ['2024-03-20']);
    expect(find.byType(CalendarDatePickerSurface), findsNothing);
  });

  testWidgets(
    'field does not mask typing; submit normalizes separators and rejects overflow',
    (tester) async {
      final changes = <String>[];
      await pumpDesignSystemApp(
        tester,
        home: Scaffold(
          body: PublishedDateTextField(
            label: 'Date',
            value: '',
            onChanged: changes.add,
          ),
        ),
      );
      final field = find.byType(EditableText);
      await tester.enterText(field, '2024.2.29');
      expect(tester.widget<EditableText>(field).controller.text, '2024.2.29');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(changes.last, '2024-02-29');
      await tester.enterText(field, '2024 2 29');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(changes.last, '2024-02-29');
      await tester.enterText(field, '2024-02-30');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(tester.widget<EditableText>(field).controller.text, '2024-02-30');
      expect(changes.last, '2024-02-30');
    },
  );

  testWidgets('empty draft disables confirmation', (tester) async {
    await pumpDesignSystemApp(
      tester,
      home: Scaffold(
        body: SizedBox(
          width: 360,
          child: CalendarDatePickerSurface(
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            onConfirmed: (_) {},
            onCancel: () {},
          ),
        ),
      ),
    );
    expect(
      tester
          .widget<TextButton>(find.byKey(const ValueKey('calendar-confirm')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('exports actual themed picker surfaces for visual inspection', (
    tester,
  ) async {
    const capturePath = String.fromEnvironment('CALENDAR_CAPTURE_PATH');
    if (capturePath.isEmpty) return;
    final font = FontLoader(kAppFontFamily)
      ..addFont(rootBundle.load('assets/fonts/NotoSans-VariableFont_wdth_wght.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpDesignSystemApp(
      tester,
      locale: const Locale('en'),
      home: Scaffold(
        body: RepaintBoundary(
          key: const ValueKey('capture'),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < 3; i++)
                  SizedBox(
                    width: 360,
                    child: CalendarDatePickerSurface(
                      modal: i > 0,
                      initialEntryMode: i == 2
                          ? DatePickerEntryMode.input
                          : DatePickerEntryMode.calendar,
                      initialDate: DateTime(2025, 8, 17),
                      currentDate: DateTime(2025, 8, 5),
                      firstDate: DateTime(1970),
                      lastDate: DateTime(2030),
                      onConfirmed: (_) {},
                      onCancel: () {},
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('capture')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(capturePath).writeAsBytes(png!.buffer.asUint8List());
      image.dispose();
    });
    expect(find.byType(CalendarDatePickerSurface), findsNWidgets(3));
    const detailsPath = String.fromEnvironment('CALENDAR_DETAILS_CAPTURE_PATH');
    if (detailsPath.isEmpty) return;
    await pumpDesignSystemApp(
      tester,
      locale: const Locale('en'),
      home: Scaffold(
        body: RepaintBoundary(
          key: const ValueKey('details-capture'),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < 3; i++)
                  SizedBox(
                    key: ValueKey('detail-calendar-$i'),
                    width: 360,
                    child: CalendarDatePickerSurface(
                      initialDate: DateTime(2025, 8, 17),
                      currentDate: DateTime(2025, 8, 5),
                      firstDate: DateTime(1970),
                      lastDate: DateTime(2030),
                      onConfirmed: (_) {},
                      onCancel: () {},
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('detail-calendar-1')),
        matching: find.byKey(const ValueKey('calendar-month-menu')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('detail-calendar-2')),
        matching: find.byKey(const ValueKey('calendar-year-menu')),
      ),
    );
    await tester.pumpAndSettle();
    final mouse = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(day('2025-08-20')));
    await tester.pumpAndSettle();
    final details = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('details-capture')),
    );
    await tester.runAsync(() async {
      final image = await details.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(detailsPath).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    await mouse.removePointer();
  });
}
