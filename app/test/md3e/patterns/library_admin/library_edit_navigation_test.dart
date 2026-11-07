import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/library_admin/presentation/views/library/library_edit_page.dart';
import 'package:hentai_library/features/library_admin/presentation/patterns/library_edit_form.dart';

import '../../../../widgetbook/lab/navigation/md3e_library_edit_navigation.dart';

import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../support/pump_app.dart';

void _setTestViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('expanded 视口以 Dialog 浮层打开库编辑', (WidgetTester tester) async {
    _setTestViewport(tester, const Size(1024, 720));

    await pumpApp(
      tester,
      home: Builder(
        builder: (BuildContext context) {
          return Center(
            child: FilledButton(
              onPressed: () {
                unawaited(
                  showLibraryEdit(
                    context: context,
                    intent: LibraryEditPageIntent.editLocal,
                  ),
                );
              },
              child: const Text('打开'),
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    expect(find.byType(M3EDialog), findsOneWidget);
    expect(find.byType(LibraryEditForm), findsOneWidget);
    expect(find.byType(ModalBarrier), findsAtLeast(1));
    expect(find.text('打开'), findsOneWidget);
    expect(find.text('编辑库'), findsOneWidget);
  });

  testWidgets('medium 视口以全屏路由打开库编辑', (WidgetTester tester) async {
    _setTestViewport(tester, const Size(720, 720));

    await pumpApp(
      tester,
      home: Builder(
        builder: (BuildContext context) {
          return Center(
            child: FilledButton(
              onPressed: () {
                unawaited(
                  showLibraryEdit(
                    context: context,
                    intent: LibraryEditPageIntent.createLocal,
                  ),
                );
              },
              child: const Text('打开'),
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    expect(find.byType(LibraryEditForm), findsOneWidget);
    expect(find.byType(M3EFullScreenDialog), findsOneWidget);
    expect(find.text('添加本地库'), findsOneWidget);
  });
}
