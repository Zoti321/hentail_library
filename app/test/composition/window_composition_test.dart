import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/composition/infrastructure_overrides.dart';
import 'package:hentai_library/composition/window_composition.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/reader/presentation/providers/reader_window_providers.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_chrome_notifier.dart';

import '../support/pump_design_system_app.dart';

void main() {
  for (final (platform, desktop) in [
    (TargetPlatform.windows, true),
    (TargetPlatform.macOS, true),
    (TargetPlatform.linux, true),
    (TargetPlatform.android, false),
    (TargetPlatform.iOS, false),
    (TargetPlatform.fuchsia, false),
  ]) {
    testWidgets(
      'reader fullscreen uses the composed window effect on $platform',
      (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        const channel = MethodChannel('window_manager');
        final calls = <MethodCall>[];
        final container = ProviderContainer(
          overrides: infrastructureOverrides(),
        );
        addTearDown(container.dispose);
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (call) async {
            calls.add(call);
            expect(container.read(readerChromeNotifierProvider), isTrue);
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            null,
          ),
        );
        container.read(readerWindowFullscreenCommandProvider);
        final controller = container.read(
          readerChromeNotifierProvider.notifier,
        );
        expect(calls, isEmpty);
        expect(container.read(readerChromeNotifierProvider), isFalse);
        await controller.setFullscreen(true);
        expect(container.read(readerChromeNotifierProvider), isTrue);
        await controller.exitFullscreenIfNeeded();
        expect(container.read(readerChromeNotifierProvider), isFalse);
        expect(
          calls.map((call) => call.method),
          desktop ? ['setFullScreen', 'setFullScreen'] : isEmpty,
        );
        expect(
          calls.map((call) => call.arguments),
          desktop
              ? [
                  {'isFullScreen': true},
                  {'isFullScreen': false},
                ]
              : isEmpty,
        );
        debugDefaultTargetPlatformOverride = null;
      },
    );
  }

  testWidgets(
    'composition binds chrome to native actions and releases close guard',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      const channel = MethodChannel('window_manager');
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call.method);
        if (call.method == 'isMaximized' || call.method == 'isFullScreen') {
          return false;
        }
        return null;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await pumpDesignSystemApp(
        tester,
        home: const AppWindowHost(
          child: Align(
            alignment: Alignment.topCenter,
            child: DesktopTitleBar(),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.crop_square));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      await tester.dragFrom(const Offset(100, 18), const Offset(100, 0));
      await tester.pumpAndSettle();
      expect(calls, [
        'minimize',
        'isMaximized',
        'maximize',
        'setPreventClose',
        'close',
        'isFullScreen',
        'startDragging',
      ]);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      debugDefaultTargetPlatformOverride = null;
    },
  );
}
