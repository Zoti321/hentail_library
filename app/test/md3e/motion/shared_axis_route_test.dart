import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../widgetbook/lab/navigation/md3e_lab_reader_navigation.dart';
import '../../../widgetbook/hosts/md3e_reader_page_lab_host.dart';

import '../../support/pump_app.dart';

Future<void> _pumpLauncher(WidgetTester tester) async {
  await pumpApp(
    tester,
    home: Builder(
      builder: (BuildContext context) {
        return TextButton(
          onPressed: () => openLabReader(context),
          child: const Text('open'),
        );
      },
    ),
  );
}

void main() {
  testWidgets('forward route uses scaled SharedAxisTransition', (
    WidgetTester tester,
  ) async {
    await _pumpLauncher(tester);
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.byType(ReaderPageLabHost), findsOneWidget);
    expect(find.byType(SharedAxisTransition), findsWidgets);
    final SharedAxisTransition axis = tester.widget(
      find.byType(SharedAxisTransition).first,
    );
    expect(axis.transitionType, SharedAxisTransitionType.scaled);

    await tester.pumpAndSettle();
    expect(find.byType(ReaderPageLabHost), findsOneWidget);
  });

  testWidgets('back route pops the page', (WidgetTester tester) async {
    await _pumpLauncher(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(ReaderPageLabHost), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(find.byType(ReaderPageLabHost), findsNothing);
  });

  testWidgets('reduce motion switches route without SharedAxis', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          );
        },
        home: Builder(
          builder: (BuildContext context) {
            return TextButton(
              onPressed: () => openLabReader(context),
              child: const Text('open'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();

    expect(find.byType(SharedAxisTransition), findsNothing);
    expect(find.byType(ReaderPageLabHost), findsOneWidget);
  });
}
