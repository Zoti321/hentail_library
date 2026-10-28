import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_delete_confirm_dialog.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_management_copy.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../support/pump_md3e_app.dart';

void main() {
  testWidgets('删除库确认须勾选闸门后才能确认', (WidgetTester tester) async {
    await pumpMd3eApp(
      tester,
      home: Builder(
        builder: (BuildContext context) {
          return Center(
            child: FilledButton(
              onPressed: () {
                unawaited(
                  showMd3eHomeLibraryDeleteConfirmDialog(
                    context: context,
                    libraryDisplayName: '演示库',
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

    expect(
      find.text(Md3eHomeLibraryManagementCopy.deleteConfirmAcknowledgement),
      findsOneWidget,
    );
    expect(
      find.text(Md3eHomeLibraryManagementCopy.deleteConfirmBody),
      findsOneWidget,
    );

    final Finder deleteButton = find.descendant(
      of: find.byType(M3EDialog),
      matching: find.text('删除'),
    );
    expect(deleteButton, findsOneWidget);

    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    expect(
      find.text(Md3eHomeLibraryManagementCopy.deleteConfirmAcknowledgement),
      findsOneWidget,
    );

    await tester.tap(find.byType(M3ECheckbox));
    await tester.pumpAndSettle();

    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    expect(
      find.text(Md3eHomeLibraryManagementCopy.deleteConfirmAcknowledgement),
      findsNothing,
    );
  });
}
