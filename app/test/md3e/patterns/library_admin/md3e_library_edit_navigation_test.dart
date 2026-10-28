import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/pages/md3e_library_edit_page.dart';
import 'package:hentai_library/md3e/patterns/library_admin/md3e_library_edit_form.dart';
import 'package:hentai_library/md3e/patterns/library_admin/md3e_library_edit_navigation.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../support/pump_md3e_app.dart';

void _setTestViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('expanded 视口以 Dialog 浮层打开库编辑', (WidgetTester tester) async {
    _setTestViewport(tester, const Size(1024, 720));

    await pumpMd3eApp(
      tester,
      home: Builder(
        builder: (BuildContext context) {
          return Center(
            child: FilledButton(
              onPressed: () {
                unawaited(
                  showMd3eLibraryEdit(
                    context: context,
                    intent: Md3eLibraryEditPageIntent.editLocal,
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
    expect(find.byType(Md3eLibraryEditForm), findsOneWidget);
    expect(find.byType(ModalBarrier), findsAtLeast(1));
    expect(find.text('打开'), findsOneWidget);
    expect(find.text('编辑库'), findsOneWidget);
  });

  testWidgets('medium 视口以全屏路由打开库编辑', (WidgetTester tester) async {
    _setTestViewport(tester, const Size(720, 720));

    await pumpMd3eApp(
      tester,
      home: Builder(
        builder: (BuildContext context) {
          return Center(
            child: FilledButton(
              onPressed: () {
                unawaited(
                  showMd3eLibraryEdit(
                    context: context,
                    intent: Md3eLibraryEditPageIntent.createLocal,
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

    expect(find.byType(Md3eLibraryEditForm), findsOneWidget);
    expect(find.byType(M3EFullScreenDialog), findsOneWidget);
    expect(find.text('添加本地库'), findsOneWidget);
  });
}
