import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/widgets/foundation/expressive_pointer_target.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('PointerTarget enforces minimum interactive size', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      home: Center(
        child: PointerTarget(
          key: const Key('target'),
          child: const SizedBox(width: 24, height: 24),
        ),
      ),
    );
    final Size size = tester.getSize(find.byKey(const Key('target')));
    expect(size.width, kMinInteractiveSize);
    expect(size.height, kMinInteractiveSize);
  });
}
