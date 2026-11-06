import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/library_admin/presentation/views/home_library_dashboard/patterns/home_library_delete_confirm_dialog.dart';
import 'package:hentai_library/features/library_admin/presentation/views/home_library_dashboard/patterns/home_library_management_copy.dart';

import '../../../../../../widgetbook/lab/theme/md3e_theme.dart';

import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../../../support/pump_app.dart';

void main() {
  testWidgets('删除库确认须勾选闸门后才能确认', (WidgetTester tester) async {
    await pumpApp(
      tester,
      home: Builder(
        builder: (BuildContext context) {
          return Center(
            child: FilledButton(
              onPressed: () {
                unawaited(
                  showHomeLibraryDeleteConfirmDialog(
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
      find.text(HomeLibraryManagementCopy.deleteConfirmAcknowledgement),
      findsOneWidget,
    );
    expect(
      find.text(HomeLibraryManagementCopy.deleteConfirmBody),
      findsOneWidget,
    );

    final Finder deleteButton = find.descendant(
      of: find.byType(M3EDialog),
      matching: find.text('删除'),
    );
    expect(deleteButton, findsOneWidget);
    final TextStyle effectiveDeleteLabelStyle = DefaultTextStyle.of(
      tester.element(deleteButton),
    ).style;
    expect(effectiveDeleteLabelStyle.fontFamily, kAppFontFamily);

    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    expect(
      find.text(HomeLibraryManagementCopy.deleteConfirmAcknowledgement),
      findsOneWidget,
    );

    await tester.tap(find.byType(M3ECheckbox));
    await tester.pumpAndSettle();

    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    expect(
      find.text(HomeLibraryManagementCopy.deleteConfirmAcknowledgement),
      findsNothing,
    );
  });
}
