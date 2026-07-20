import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/dialog_actions_bar.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/hentai_dialog.dart';

void main() {
  testWidgets('scrolls tall content instead of overflowing the dialog shell', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: Center(
            child: HentaiDialog(
              title: '发现新版本 v9.9.9',
              width: 480,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: List<Widget>.generate(
                  40,
                  (int index) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('- Release note line $index'),
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(onPressed: () {}, child: const Text('稍后提醒')),
                const SizedBox(width: 8),
                FilledButton(onPressed: () {}, child: const Text('立即更新')),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('narrow viewport does not overflow three-button update actions', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: Center(
            child: HentaiDialog(
              title: '发现新版本 v9.9.9',
              width: 480,
              content: const Text('发布于 2026-07-08'),
              actions: <Widget>[
                TextButton(onPressed: () {}, child: const Text('稍后提醒')),
                const SizedBox(width: 8),
                TextButton(onPressed: () {}, child: const Text('查看详情')),
                const SizedBox(width: 8),
                FilledButton(onPressed: () {}, child: const Text('立即更新')),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final Finder wrapFinder = find.descendant(
      of: find.byType(DialogActionsBar),
      matching: find.byType(Wrap),
    );
    final Wrap wrap = tester.widget<Wrap>(wrapFinder);
    expect(wrap.spacing, DialogActionsBar.actionSpacing);
    expect(wrap.runSpacing, DialogActionsBar.actionSpacing);

    final ThemeData footerTheme = Theme.of(tester.element(wrapFinder));
    final OutlinedBorder? filledShape = footerTheme
        .filledButtonTheme
        .style
        ?.shape
        ?.resolve(const <WidgetState>{});
    final OutlinedBorder? textShape = footerTheme.textButtonTheme.style?.shape
        ?.resolve(const <WidgetState>{});
    expect(filledShape, isA<RoundedRectangleBorder>());
    expect(textShape, isA<RoundedRectangleBorder>());
    expect(
      (filledShape! as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(4),
    );
    expect(
      (textShape! as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(4),
    );
  });
}
