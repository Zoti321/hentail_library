import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/composition/composition_overrides.dart';
import 'package:hentai_library/composition/feature_state_overrides.dart';
import 'package:hentai_library/features/reader/presentation/views/reader/reader_settings_sheet.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../../../support/fakes/settings_test_fakes.dart';
import '../../../../../support/pump_localized_app.dart';

import 'package:hentai_library/features/app_settings/public/providers/app_settings_providers.dart';

/// 打开阅读设置面板（使用真实的设置写入链路 + 内存仓库）。
Future<void> _pumpSheet(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1024, 800));
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
  testWidgets('shows auto-play settings from app settings', (
    WidgetTester tester,
  ) async {
    await _pumpSheet(tester);

    expect(find.text('阅读模式'), findsWidgets);
    expect(find.text('自动翻页'), findsOneWidget);
    expect(find.text('翻页范围'), findsOneWidget);
    expect(find.text('翻页间隔'), findsOneWidget);
    expect(find.text('本话一次'), findsOneWidget);
    expect(find.text('翻页模式'), findsOneWidget);
    expect(find.text('Webtoon 模式'), findsOneWidget);
    expect(find.text('5 秒'), findsOneWidget);
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
