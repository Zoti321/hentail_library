import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/metadata/metadata_export_flow.dart';
import 'package:hentai_library/core/metadata/metadata_export_options.dart';

import '../../support/pump_localized_app.dart';

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

    expect(find.text('使用 GZIP 压缩'), findsOneWidget);
    expect(find.text('仅当前 LIBRARY'), findsOneWidget);
    expect(find.text('开启'), findsWidgets);

    await tester.tap(find.text('继续'));
    await tester.pumpAndSettle();

    expect(confirmed?.gzip, isTrue);
    expect(confirmed?.currentLibraryOnly, isFalse);
    expect(confirmed?.libraryId, 'lib-1');
  });
}
