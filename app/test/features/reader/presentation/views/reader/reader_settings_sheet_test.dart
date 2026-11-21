import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/composition/composition_overrides.dart';
import 'package:hentai_library/composition/feature_state_overrides.dart';
import 'package:hentai_library/features/app_settings/public/providers/app_settings_providers.dart';
import 'package:hentai_library/features/reader/presentation/views/reader/reader_settings_sheet.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../../../support/fakes/settings_test_fakes.dart';
import '../../../../../support/pump_localized_app.dart';
import '../../../../../support/test_view.dart';

/// 打开阅读设置面板（使用真实的设置写入链路 + 内存仓库）。
Future<void> _pumpSheet(
  WidgetTester tester, {
  Size surfaceSize = const Size(600, 800),
}) async {
  configureTestView(tester, surfaceSize);
  await pumpLocalizedApp(
    tester,
    wrapProviderScope: true,
    overrides: <Override>[
      ...featureStateOverrides(),
      ...bootstrapCompositionOverrides(),
      appSettingRepositoryProvider.overrideWithValue(
        MemoryAppSettingRepository(),
      ),
    ],
    home: Builder(
      builder: (BuildContext context) {
        return Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => ReaderSettingsSheet.show(context),
              child: const Text('open'),
            ),
          ),
        );
      },
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('medium- bottom sheet shows chips without full-screen chrome', (
    WidgetTester tester,
  ) async {
    await _pumpSheet(tester);

    expect(find.text('阅读设置'), findsNothing);
    expect(find.byIcon(M3EIcons.close), findsNothing);

    expect(find.text('阅读模式'), findsOneWidget);
    expect(find.text('自动翻页'), findsOneWidget);
    expect(find.text('翻页间隔'), findsOneWidget);
    expect(find.text('本话一次'), findsOneWidget);
    expect(find.text('翻页模式'), findsOneWidget);
    expect(find.text('Webtoon 模式'), findsOneWidget);
    expect(find.text('翻页'), findsOneWidget);
    expect(find.text('单页'), findsOneWidget);
    expect(find.text('双页'), findsOneWidget);
    expect(find.text('5 秒'), findsOneWidget);
  });

  testWidgets('expanded+ side sheet keeps title and hides close', (
    WidgetTester tester,
  ) async {
    await _pumpSheet(tester, surfaceSize: const Size(1024, 800));

    expect(find.text('阅读设置'), findsOneWidget);
    expect(find.byIcon(M3EIcons.close), findsNothing);
    expect(find.text('阅读模式'), findsOneWidget);
  });

  testWidgets('paged layout chip switches selection', (
    WidgetTester tester,
  ) async {
    await _pumpSheet(tester);

    await tester.tap(find.text('双页'));
    await tester.pumpAndSettle();

    final M3EChip dual = tester.widget<M3EChip>(
      find.widgetWithText(M3EChip, '双页'),
    );
    final M3EChip single = tester.widget<M3EChip>(
      find.widgetWithText(M3EChip, '单页'),
    );
    expect(dual.selected, isTrue);
    expect(single.selected, isFalse);
  });

  testWidgets('interval + increments the displayed value', (
    WidgetTester tester,
  ) async {
    await _pumpSheet(tester);

    await tester.tap(find.byIcon(Symbols.add).last);
    await tester.pumpAndSettle();

    expect(find.text('6 秒'), findsOneWidget);
    expect(find.text('5 秒'), findsNothing);
  });

  testWidgets('interval - decrements the displayed value', (
    WidgetTester tester,
  ) async {
    await _pumpSheet(tester);

    await tester.tap(find.byIcon(Symbols.remove).last);
    await tester.pumpAndSettle();

    expect(find.text('4 秒'), findsOneWidget);
    expect(find.text('5 秒'), findsNothing);
  });
}
