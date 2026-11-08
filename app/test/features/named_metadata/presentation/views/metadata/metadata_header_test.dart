import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations_zh.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata/metadata_header.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../../support/pump_app.dart';

void main() {
  final AppLocalizationsZh l10n = AppLocalizationsZh();

  Future<void> pumpHeader(
    WidgetTester tester, {
    required Widget header,
  }) {
    return pumpApp(
      tester,
      home: Scaffold(
        body: SizedBox(width: 900, height: 200, child: header),
      ),
    );
  }

  testWidgets('普通模式显示「管理」标题与更多菜单入口', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 600));
    await pumpHeader(
      tester,
      header: MetadataHeader(onBack: () {}),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.navMetadata), findsOneWidget);
    expect(find.byIcon(Symbols.more_vert), findsOneWidget);
    expect(find.text(l10n.metadataMergeSelectionLabel(2)), findsNothing);

    await tester.tap(find.byIcon(Symbols.more_vert));
    await tester.pumpAndSettle();

    expect(find.text(l10n.settingsMetadataBackupExportLabel), findsOneWidget);
    expect(
      find.text(l10n.metadataImportTagDictionaryMenuLabel),
      findsOneWidget,
    );
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('合并模式显示本地化合并按钮计数', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 600));
    await pumpHeader(
      tester,
      header: MetadataHeader(
        mergeSelectionCount: 3,
        onExitMergeSelection: () {},
        onMergeSelection: () {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.navMetadata), findsNothing);
    expect(find.text(l10n.metadataMergeSelectionLabel(3)), findsOneWidget);
    expect(find.byIcon(Symbols.more_vert), findsNothing);
    await tester.binding.setSurfaceSize(null);
  });
}
