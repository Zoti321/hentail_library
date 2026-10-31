import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/bootstrap/di/composition_overrides.dart';
import 'package:hentai_library/features/bootstrap/di/shared_state_overrides.dart';
import 'package:hentai_library/features/read_session/presentation/views/reader_md3e/reader_md3e_settings_sheet.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../../../support/fakes/settings_test_fakes.dart';
import '../../../../../support/pump_localized_app.dart';

void main() {
  testWidgets(
    'reader md3e settings sheet shows auto-play settings from app settings',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 800));
      await pumpLocalizedApp(
        tester,
        wrapProviderScope: true,
        overrides: <Override>[
          ...sharedLibraryStateOverrides(),
          ...bootstrapCompositionOverrides(),
          appSettingRepoProvider.overrideWithValue(
            MemoryAppSettingRepository(),
          ),
        ],
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => ReaderMd3eSettingsSheet.show(context),
                  child: const Text('open'),
                ),
              ),
            );
          },
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('阅读模式'), findsWidgets);
      expect(find.text('自动播放'), findsOneWidget);
      expect(find.text('自动播放模式'), findsOneWidget);
      expect(find.text('播放间隔'), findsOneWidget);
      expect(find.text('单本播放'), findsOneWidget);
      expect(find.text('5 秒'), findsOneWidget);
    },
  );
}
