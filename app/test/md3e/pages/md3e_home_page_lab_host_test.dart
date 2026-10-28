import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/pages/md3e_home_page_lab_host.dart';
import 'package:hentai_library/md3e/pages/md3e_library_edit_page.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_dashboard_models.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../support/pump_md3e_app.dart';

void _setTestViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('LabHost add local library opens Library form preview', (
    WidgetTester tester,
  ) async {
    _setTestViewport(tester, const Size(1024, 900));

    await pumpMd3eApp(
      tester,
      home: const SizedBox(
        width: 1024,
        height: 900,
        child: Md3eHomePageLabHost(enableReorder: false),
      ),
    );

    await tester.tap(find.text('新建漫画库'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('添加本地库'));
    await tester.pumpAndSettle();

    expect(find.byType(Md3eLibraryEditPage), findsOneWidget);
    expect(find.byType(ModalBarrier), findsAtLeast(1));
    expect(find.text('新建漫画库'), findsOneWidget);
  });
}
