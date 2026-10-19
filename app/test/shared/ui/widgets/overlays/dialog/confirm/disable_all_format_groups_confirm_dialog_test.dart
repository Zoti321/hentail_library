import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/widgets/overlays/dialog/confirm/disable_all_format_groups_confirm_dialog.dart';

import '../../../../../../support/pump_localized_app.dart';

void main() {
  Future<void> openDialog(WidgetTester tester) async {
    await pumpLocalizedApp(
      tester,
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) {
            return TextButton(
              onPressed: () {
                showDialog<bool>(
                  context: context,
                  builder: (BuildContext dialogContext) =>
                      const DisableAllFormatGroupsConfirmDialog(),
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('cancel pops false', (WidgetTester tester) async {
    bool? result;
    await pumpLocalizedApp(
      tester,
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) {
            return TextButton(
              onPressed: () async {
                result = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext dialogContext) =>
                      const DisableAllFormatGroupsConfirmDialog(),
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('关闭全部格式？'), findsOneWidget);
    expect(find.textContaining('下次库同步将清空当前本地库中的全部 Comic'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(result, isFalse);
    expect(find.text('关闭全部格式？'), findsNothing);
  });

  testWidgets('confirm pops true', (WidgetTester tester) async {
    bool? result;
    await pumpLocalizedApp(
      tester,
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) {
            return TextButton(
              onPressed: () async {
                result = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext dialogContext) =>
                      const DisableAllFormatGroupsConfirmDialog(),
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(result, isTrue);
    expect(find.text('关闭全部格式？'), findsNothing);
  });

  testWidgets('shows title and body copy', (WidgetTester tester) async {
    await openDialog(tester);
    expect(find.text('关闭全部格式？'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('保存'), findsOneWidget);
  });
}
