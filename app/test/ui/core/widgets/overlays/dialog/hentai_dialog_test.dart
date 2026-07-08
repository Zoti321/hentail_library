import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
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
                TextButton(
                  onPressed: () {},
                  child: const Text('稍后提醒'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {},
                  child: const Text('立即更新'),
                ),
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
}
