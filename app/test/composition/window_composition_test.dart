import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/composition/window_composition.dart';
import 'package:hentai_library/design-system/design_system.dart';

import '../support/pump_design_system_app.dart';

void main() {
  testWidgets(
    'composition binds chrome to native actions and releases close guard',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      const channel = MethodChannel('window_manager');
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call.method);
        if (call.method == 'isMaximized' || call.method == 'isFullScreen') {
          return false;
        }
        return null;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await pumpDesignSystemApp(
        tester,
        home: const AppWindowHost(
          child: Align(
            alignment: Alignment.topCenter,
            child: DesktopTitleBar(),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.crop_square));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      await tester.dragFrom(const Offset(100, 18), const Offset(100, 0));
      await tester.pumpAndSettle();
      expect(calls, [
        'minimize',
        'isMaximized',
        'maximize',
        'setPreventClose',
        'close',
        'isFullScreen',
        'startDragging',
      ]);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      debugDefaultTargetPlatformOverride = null;
    },
  );
}
