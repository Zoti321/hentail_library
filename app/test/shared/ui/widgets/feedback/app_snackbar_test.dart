import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/application/errors/app_exception.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/app_snackbar.dart';

import '../../../../support/pump_localized_app.dart';

void main() {
  testWidgets(
    'application errors present their message without internal cause',
    (tester) async {
      await pumpLocalizedApp(
        tester,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showErrorSnackbar(
                context,
                AppException('无法读取', cause: 'private-path'),
              ),
              child: const Text('Show'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
      expect(find.text('无法读取'), findsOneWidget);
      expect(find.textContaining('private-path'), findsNothing);
    },
  );
}
