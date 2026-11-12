import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations_zh.dart';
import 'package:hentai_library/features/comic_metadata/presentation/views/metadata/metadata_dialogs.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../../../support/pump_app.dart';

void main() {
  final AppLocalizationsZh l10n = AppLocalizationsZh();

  testWidgets('合并确认展示目标摘要与不再提示勾选', (WidgetTester tester) async {
    bool? confirmed;
    bool skip = false;

    await pumpApp(
      tester,
      home: Builder(
        builder: (BuildContext context) {
          return Center(
            child: FilledButton(
              onPressed: () {
                unawaited(() async {
                  confirmed = await showMetadataMergeConfirmDialog(
                    context: context,
                    target: '目标标签',
                    sourceCount: 2,
                    onSkipChanged: (bool value) => skip = value,
                  );
                }());
              },
              child: const Text('打开'),
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    expect(find.text(l10n.metadataMergeConfirmTitle), findsOneWidget);
    expect(find.text(l10n.metadataMergeConfirmBody(2, '目标标签')), findsOneWidget);
    expect(find.text(l10n.metadataMergeConfirmDontAskAgain), findsOneWidget);

    await tester.tap(find.byType(M3ECheckbox));
    await tester.pumpAndSettle();
    expect(skip, isTrue);

    await tester.tap(find.text(l10n.metadataMerge));
    await tester.pumpAndSettle();
    expect(confirmed, isTrue);
  });
}
