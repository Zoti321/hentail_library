import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/library_browse/presentation/views/widgets/detail_status/detail_status_scaffold.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../../support/pump_localized_app.dart';

/// `TextButton.icon` 返回子类，`find.byType` 按精确类型匹配，故用谓词。
final Finder _textButtons = find.byWidgetPredicate(
  (Widget w) => w is TextButton,
);

void main() {
  testWidgets('DetailErrorStatus without onRetry shows label and no button', (
    WidgetTester tester,
  ) async {
    await pumpLocalizedApp(
      tester,
      home: const DetailErrorStatus(label: 'LOAD_FAILED'),
    );
    await tester.pumpAndSettle();

    expect(find.text('LOAD_FAILED'), findsOneWidget);
    expect(_textButtons, findsNothing);
  });

  testWidgets('DetailErrorStatus retry button invokes onRetry once', (
    WidgetTester tester,
  ) async {
    int retryCalls = 0;
    await pumpLocalizedApp(
      tester,
      home: DetailErrorStatus(
        label: 'LOAD_FAILED',
        onRetry: () => retryCalls++,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('LOAD_FAILED'), findsOneWidget);
    await tester.tap(_textButtons);
    await tester.pump();

    expect(retryCalls, 1);
    expect(
      tester.widget<TextButton>(_textButtons).onPressed,
      isNull,
      reason: '重试中按钮应禁用，避免重复触发',
    );
  });

  testWidgets('DetailNotFoundStatus shows label and go-to-library action', (
    WidgetTester tester,
  ) async {
    await pumpLocalizedApp(
      tester,
      home: const DetailNotFoundStatus(
        icon: LucideIcons.bookOpen,
        label: 'NOT_FOUND',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NOT_FOUND'), findsOneWidget);
    expect(_textButtons, findsOneWidget);
  });

  testWidgets('DetailLoadingStatus shows a progress indicator', (
    WidgetTester tester,
  ) async {
    await pumpLocalizedApp(tester, home: const DetailLoadingStatus());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
