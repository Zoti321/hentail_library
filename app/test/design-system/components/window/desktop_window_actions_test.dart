import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/design-system/design_system.dart';

import '../../../support/pump_design_system_app.dart';

void main() {
  testWidgets(
    'chrome invokes supplied window actions without a window plugin',
    (tester) async {
      final calls = <String>[];
      await pumpDesignSystemApp(
        tester,
        home: DesktopWindowActions(
          onMinimize: () => calls.add('minimize'),
          onToggleMaximize: () => calls.add('maximize'),
          onClose: () => calls.add('close'),
          onStartDragging: () => calls.add('drag'),
          child: const Align(
            alignment: Alignment.topCenter,
            child: DesktopTitleBar(),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.remove));
      await tester.tap(find.byIcon(Icons.crop_square));
      await tester.tap(find.byIcon(Icons.close));
      await tester.dragFrom(const Offset(100, 18), const Offset(100, 0));
      await tester.pumpAndSettle();
      expect(calls, ['minimize', 'maximize', 'close', 'drag']);
    },
  );

  testWidgets('an explicit callback overrides host actions', (tester) async {
    final calls = <String>[];
    await pumpDesignSystemApp(
      tester,
      home: DesktopWindowActions(
        onMinimize: () => calls.add('host'),
        onToggleMaximize: () {},
        onClose: () {},
        onStartDragging: () {},
        child: DesktopWindowControls(onMinimize: () => calls.add('override')),
      ),
    );
    await tester.tap(find.byIcon(Icons.remove));
    expect(calls, ['override']);
  });
}
