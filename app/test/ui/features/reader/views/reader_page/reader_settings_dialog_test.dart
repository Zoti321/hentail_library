import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/models/app_setting.dart';
import 'package:hentai_library/domain/repositories/app_setting_repository.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_settings_dialog.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../../../support/pump_localized_app.dart';

void main() {
  testWidgets('reader settings shows Auto-play mode and non-primary header', (
    WidgetTester tester,
  ) async {
    await pumpLocalizedApp(
      tester,
      wrapProviderScope: true,
      overrides: <Override>[
        appSettingRepoProvider.overrideWithValue(_MemoryRepo()),
      ],
      home: Builder(
        builder: (BuildContext context) {
          return Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showReaderSettingsDialog(context),
                child: const Text('open'),
              ),
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('阅读设置'), findsOneWidget);
    expect(find.text('自动播放'), findsOneWidget);
    expect(find.text('自动播放模式'), findsOneWidget);
    expect(find.text('播放间隔'), findsOneWidget);
    expect(find.text('单本播放'), findsOneWidget);

    final ThemeData headerTheme = Theme.of(tester.element(find.text('阅读设置')));
    final ColorScheme cs = headerTheme.colorScheme;
    final Material headerMaterial = tester.widget(
      find
          .ancestor(of: find.text('阅读设置'), matching: find.byType(Material))
          .first,
    );
    expect(headerMaterial.color, cs.hentai.readerBackground);
    expect(headerMaterial.color, isNot(cs.primary));
  });
}

class _MemoryRepo implements AppSettingRepository {
  AppSetting _setting = AppSetting();

  @override
  Future<AppSetting> load() async => _setting;

  @override
  Future<void> save(AppSetting setting) async {
    _setting = setting;
  }

  @override
  Future<bool?> peekLegacyAutoScan() async => null;
}
