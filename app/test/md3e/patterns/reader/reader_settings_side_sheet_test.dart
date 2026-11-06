import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/read_session/public/reading_preference_l10n.dart';
import 'package:hentai_library/features/read_session/presentation/patterns/reader/reader_settings_side_sheet.dart';
import 'package:hentai_library/features/read_session/domain/auto_play_mode.dart';

import '../../../support/pump_app.dart';

Future<void> _openSheet(
  WidgetTester tester,
  ValueChanged<ReaderSettingsLabState> onChanged, {
  ReaderSettingsLabState initial = const ReaderSettingsLabState(),
}) async {
  await tester.binding.setSurfaceSize(const Size(1024, 800));
  await pumpApp(
    tester,
    home: Builder(
      builder: (BuildContext context) => Scaffold(
        body: TextButton(
          onPressed: () => ReaderSettingsSideSheet.show(
            context,
            state: initial,
            onStateChanged: onChanged,
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('play mode tile cycles through AutoPlayMode values', (
    WidgetTester tester,
  ) async {
    ReaderSettingsLabState latest = const ReaderSettingsLabState();
    await _openSheet(
      tester,
      (ReaderSettingsLabState next) => latest = next,
    );

    final BuildContext context = tester.element(find.byType(Scaffold));
    final l10n = context.l10n;
    expect(
      find.text(l10n.autoPlayModeLabel(AutoPlayMode.comicOnce)),
      findsOneWidget,
    );

    await tester.tap(find.text(l10n.readerSettingsAutoPlayMode));
    await tester.pumpAndSettle();
    expect(latest.autoPlayMode, AutoPlayMode.comicLoop);
    expect(
      find.text(l10n.autoPlayModeLabel(AutoPlayMode.comicLoop)),
      findsOneWidget,
    );

    await tester.tap(find.text(l10n.readerSettingsAutoPlayMode));
    await tester.pumpAndSettle();
    expect(latest.autoPlayMode, AutoPlayMode.seriesOnce);

    await tester.tap(find.text(l10n.readerSettingsAutoPlayMode));
    await tester.pumpAndSettle();
    expect(latest.autoPlayMode, AutoPlayMode.seriesLoop);

    await tester.tap(find.text(l10n.readerSettingsAutoPlayMode));
    await tester.pumpAndSettle();
    expect(latest.autoPlayMode, AutoPlayMode.comicOnce);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('interval stepper adjusts seconds and clamps to 1..60', (
    WidgetTester tester,
  ) async {
    ReaderSettingsLabState latest = const ReaderSettingsLabState();
    await _openSheet(
      tester,
      (ReaderSettingsLabState next) => latest = next,
    );

    expect(latest.autoPlayIntervalSeconds, 5);
    await tester.tap(find.byKey(const Key('reader_settings_interval_plus')));
    await tester.pumpAndSettle();
    expect(latest.autoPlayIntervalSeconds, 6);

    for (int i = 0; i < 10; i++) {
      await tester.tap(find.byKey(const Key('reader_settings_interval_minus')));
      await tester.pumpAndSettle();
    }
    expect(latest.autoPlayIntervalSeconds, 1);

    await tester.tap(find.byKey(const Key('reader_settings_interval_minus')));
    await tester.pumpAndSettle();
    expect(latest.autoPlayIntervalSeconds, 1);
    await tester.binding.setSurfaceSize(null);
  });
}
