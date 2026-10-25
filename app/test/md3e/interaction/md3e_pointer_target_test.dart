import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/interaction/md3e_pointer_target.dart';

import '../../support/pump_md3e_app.dart';

void main() {
  testWidgets('Md3ePointerTarget enforces minimum interactive size', (
    WidgetTester tester,
  ) async {
    await pumpMd3eApp(
      tester,
      home: Center(
        child: Md3ePointerTarget(
          key: const Key('target'),
          child: const SizedBox(width: 24, height: 24),
        ),
      ),
    );
    final Size size = tester.getSize(find.byKey(const Key('target')));
    expect(size.width, kMd3eMinInteractiveSize);
    expect(size.height, kMd3eMinInteractiveSize);
  });
}
