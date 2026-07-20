import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/adaptive_form_surface.dart';

void main() {
  Future<void> pumpOpenSurface(
    WidgetTester tester, {
    required Size surfaceSize,
    double maxDialogWidth = 480,
    Widget body = const Text('form-body'),
  }) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAppTheme(Brightness.light),
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: TextButton(
                onPressed: () {
                  showAdaptiveFormSurface<void>(
                    context: context,
                    title: '编辑表单',
                    maxDialogWidth: maxDialogWidth,
                    body: body,
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('取消'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('保存'),
                      ),
                    ],
                  );
                },
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('medium viewport presents dialog chrome with constrained width', (
    WidgetTester tester,
  ) async {
    await pumpOpenSurface(tester, surfaceSize: const Size(800, 600));

    expect(find.byKey(AdaptiveFormSurface.dialogChromeKey), findsOneWidget);
    expect(find.byKey(AdaptiveFormSurface.pageChromeKey), findsNothing);
    expect(find.text('编辑表单'), findsOneWidget);
    expect(find.text('form-body'), findsOneWidget);

    final Size chromeSize = tester.getSize(
      find.byKey(AdaptiveFormSurface.dialogChromeKey),
    );
    expect(chromeSize.width, lessThanOrEqualTo(480));
    expect(find.byType(ModalBarrier), findsWidgets);
  });

  testWidgets('compact viewport presents page chrome with back control', (
    WidgetTester tester,
  ) async {
    await pumpOpenSurface(tester, surfaceSize: const Size(390, 800));

    expect(find.byKey(AdaptiveFormSurface.pageChromeKey), findsOneWidget);
    expect(find.byKey(AdaptiveFormSurface.dialogChromeKey), findsNothing);
    expect(find.text('编辑表单'), findsOneWidget);
    expect(find.text('form-body'), findsOneWidget);
    expect(find.byTooltip('返回'), findsOneWidget);

    final Size pageSize = tester.getSize(
      find.byKey(AdaptiveFormSurface.pageChromeKey),
    );
    expect(pageSize.width, equals(390));
  });

  testWidgets('keeps body field text when crossing compact breakpoint', (
    WidgetTester tester,
  ) async {
    await pumpOpenSurface(
      tester,
      surfaceSize: const Size(800, 600),
      body: const TextField(
        key: Key('adaptive-form-field'),
        decoration: InputDecoration(hintText: 'title'),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('adaptive-form-field')),
      '草稿标题',
    );
    expect(find.text('草稿标题'), findsOneWidget);
    expect(find.byKey(AdaptiveFormSurface.dialogChromeKey), findsOneWidget);

    tester.view.physicalSize = const Size(390, 800);
    await tester.pump();
    await tester.pump(kAdaptiveFormSurfaceTransitionDuration);

    expect(find.byKey(AdaptiveFormSurface.pageChromeKey), findsOneWidget);
    expect(find.text('草稿标题'), findsOneWidget);
  });

  testWidgets('morphs chrome width across compact breakpoint', (
    WidgetTester tester,
  ) async {
    await pumpOpenSurface(tester, surfaceSize: const Size(800, 600));
    expect(find.byKey(AdaptiveFormSurface.dialogChromeKey), findsOneWidget);

    final Finder eitherChrome = find.byWidgetPredicate(
      (Widget widget) =>
          widget.key == AdaptiveFormSurface.dialogChromeKey ||
          widget.key == AdaptiveFormSurface.pageChromeKey,
    );

    tester.view.physicalSize = const Size(390, 800);
    await tester.pump();
    final double startWidth = tester.getSize(eitherChrome).width;

    await tester.pump(kAdaptiveFormSurfaceTransitionDuration * 0.25);
    final double midWidth = tester.getSize(eitherChrome).width;
    expect(midWidth, greaterThan(startWidth));
    expect(midWidth, lessThan(390));

    await tester.pumpAndSettle();
    expect(find.byKey(AdaptiveFormSurface.pageChromeKey), findsOneWidget);
    expect(
      tester.getSize(find.byKey(AdaptiveFormSurface.pageChromeKey)).width,
      equals(390),
    );
  });

  testWidgets('dialog barrier tap dismisses the surface', (
    WidgetTester tester,
  ) async {
    await pumpOpenSurface(tester, surfaceSize: const Size(800, 600));
    expect(find.text('编辑表单'), findsOneWidget);

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(find.text('编辑表单'), findsNothing);
  });

  testWidgets('page back control dismisses the surface', (
    WidgetTester tester,
  ) async {
    await pumpOpenSurface(tester, surfaceSize: const Size(390, 800));
    expect(find.text('编辑表单'), findsOneWidget);

    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();
    expect(find.text('编辑表单'), findsNothing);
  });
}
