import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../widgetbook/catalog/widgetbook_directories.dart';
import '../../widgetbook/shell/md3e_widgetbook_app.dart';
import '../support/test_view.dart';

void main() {
  for (final state in ['Loaded', 'Loading', 'Error', 'Empty']) {
    testWidgets('actual Widgetbook facet preview: $state', (tester) async {
      configureTestView(tester, const Size(1280, 900));
      final directories = buildWidgetbookDirectories();
      final root = WidgetbookRoot(children: directories);
      final useCase = root.leaves.whereType<WidgetbookUseCase>().singleWhere(
        (node) => node.nodesPath.any(
          (parent) => parent.name == 'FacetMultiSelectField',
        ),
      );
      await tester.pumpWidget(
        Widgetbook(
          initialRoute: Uri(
            path: '/',
            queryParameters: {
              'path': useCase.path,
              'knobs': '{Candidates:$state}',
              'preview': 'true',
            },
          ).toString(),
          directories: directories,
          appBuilder: md3eWidgetbookAppBuilder,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(EditableText), findsOneWidget);
      await tester.tap(find.byType(EditableText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      if (state == 'Loading') {
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      } else {
        await tester.pumpAndSettle();
        switch (state) {
          case 'Loaded':
            expect(find.text('深海'), findsOneWidget);
            await tester.enterText(find.byType(EditableText), 'tsg');
            await tester.pumpAndSettle();
            expect(find.text('图书馆'), findsOneWidget);
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            await tester.pumpAndSettle();
            expect(find.text('图书馆'), findsOneWidget);
            await tester.tap(
              find.byKey(FacetMultiSelectField.clearAllButtonKey),
            );
            await tester.pumpAndSettle();
            expect(
              find.byKey(FacetMultiSelectField.clearAllButtonKey),
              findsNothing,
            );
          case 'Error':
            expect(find.text('作者列表加载失败'), findsOneWidget);
            expect(find.text('重试'), findsOneWidget);
          case 'Empty':
            expect(find.text('暂无作者'), findsOneWidget);
        }
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
}
