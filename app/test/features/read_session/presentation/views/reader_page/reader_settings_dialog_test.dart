import 'package:flutter/material.dart';
import 'package:hentai_library/features/bootstrap/di/composition_overrides.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hentai_library/features/read_session/presentation/views/reader_page/widgets/reader_settings_dialog.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/features/bootstrap/di/shared_state_overrides.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../../../support/fakes/settings_test_fakes.dart';
import '../../../../../support/pump_localized_app.dart';

void main() {
  testWidgets('reader settings shows Auto-play mode and non-primary header', (
    WidgetTester tester,
  ) async {
    await pumpLocalizedApp(
      tester,
      wrapProviderScope: true,
      overrides: <Override>[
        ...sharedLibraryStateOverrides(),
        ...bootstrapCompositionOverrides(),
        appSettingRepoProvider.overrideWithValue(MemoryAppSettingRepository()),
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
