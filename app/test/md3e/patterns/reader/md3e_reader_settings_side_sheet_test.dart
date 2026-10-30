import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_settings_side_sheet.dart';
import 'package:hentai_library/shared/domain/reading/auto_play_mode.dart';

import '../../../support/pump_md3e_app.dart';

Future<void> _openSheet(
  WidgetTester tester,
  ValueChanged<Md3eReaderSettingsLabState> onChanged, {
  Md3eReaderSettingsLabState initial = const Md3eReaderSettingsLabState(),
}) async {
  await tester.binding.setSurfaceSize(const Size(1024, 800));
  await pumpMd3eApp(
    tester,
    home: Builder(
      builder: (BuildContext context) => Scaffold(
        body: TextButton(
          onPressed: () => Md3eReaderSettingsSideSheet.show(
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
    Md3eReaderSettingsLabState latest = const Md3eReaderSettingsLabState();
    await _openSheet(tester, (Md3eReaderSettingsLabState next) => latest = next);

    final BuildContext context = tester.element(find.byType(Scaffold));
    final l10n = context.l10n;
    expect(find.text(l10n.autoPlayModeLabel(AutoPlayMode.comicOnce)),
        findsOneWidget);

    await tester.tap(find.text(l10n.readerSettingsAutoPlayMode));
    await tester.pumpAndSettle();
    expect(latest.autoPlayMode, AutoPlayMode.comicLoop);
    expect(find.text(l10n.autoPlayModeLabel(AutoPlayMode.comicLoop)),
        findsOneWidget);

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
    Md3eReaderSettingsLabState latest = const Md3eReaderSettingsLabState();
    await _openSheet(tester, (Md3eReaderSettingsLabState next) => latest = next);

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
