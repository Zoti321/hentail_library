import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/widgets/actions/destructive_filled_button.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/confirm/clear_application_data_confirm_dialog.dart';

import '../../../../../../support/pump_localized_app.dart';

void main() {
  testWidgets('confirm action uses DestructiveFilledButton with clear label', (
    WidgetTester tester,
  ) async {
    await pumpLocalizedApp(
      tester,
      home: const Scaffold(
        body: ClearApplicationDataConfirmDialog(recentBackupAt: null),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DestructiveFilledButton), findsOneWidget);
    expect(find.text('清空'), findsOneWidget);
    expect(find.text('尚无自动元数据备份记录'), findsOneWidget);
  });

  testWidgets('shows recent backup timestamp when provided', (
    WidgetTester tester,
  ) async {
    await pumpLocalizedApp(
      tester,
      home: Scaffold(
        body: ClearApplicationDataConfirmDialog(
          recentBackupAt: DateTime(2026, 3, 26, 14, 30),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('2026-03-26 14:30'), findsOneWidget);
  });
}
