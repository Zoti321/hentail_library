import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/metadata_backup/presentation/metadata_export_flow.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_export_options.dart';

import '../../../support/pump_localized_app.dart';

void main() {
  testWidgets('export options dialog confirms gzip and library scoping', (
    WidgetTester tester,
  ) async {
    MetadataExportOptions? confirmed;

    await pumpLocalizedApp(
      tester,
      home: Builder(
        builder: (BuildContext context) {
          return FilledButton(
            onPressed: () async {
              confirmed = await showDialog<MetadataExportOptions>(
                context: context,
                builder: (BuildContext context) => MetadataExportOptionsDialog(
                  initialOptions: const MetadataExportOptions(
                    libraryId: 'lib-1',
                  ),
                ),
              );
            },
            child: const Text('open'),
          );
        },
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('使用 gzip 压缩'), findsOneWidget);
    expect(find.text('包含孤立标签与字典项'), findsOneWidget);
    expect(find.byType(Switch), findsNWidgets(2));

    await tester.tap(find.widgetWithText(FilledButton, '继续'));
    await tester.pumpAndSettle();

    expect(confirmed?.gzip, isTrue);
    expect(confirmed?.includeOrphanFacets, isFalse);
    expect(confirmed?.libraryId, 'lib-1');
  });
}
