import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/reader/presentation/providers/reader_window_providers.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_chrome_notifier.dart';
import 'package:test/test.dart';

void main() {
  test('idle chrome and conditional exit do not require window IO', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(readerChromeNotifierProvider), isFalse);
    await container
        .read(readerChromeNotifierProvider.notifier)
        .exitFullscreenIfNeeded();
    expect(container.read(readerChromeNotifierProvider), isFalse);
  });

  test(
    'entry hides chrome before the window effect and awaits completion',
    () async {
      final response = Completer<void>();
      late final ProviderContainer container;
      container = _container((value) {
        expect(value, isTrue);
        expect(container.read(readerChromeNotifierProvider), isTrue);
        return response.future;
      });
      final controller = container.read(readerChromeNotifierProvider.notifier);
      var completed = false;
      final pending = controller
          .setFullscreen(true)
          .then((_) => completed = true);
      await Future<void>.value();
      expect(container.read(readerChromeNotifierProvider), isTrue);
      expect(completed, isFalse);
      response.complete();
      await pending;
      expect(completed, isTrue);
    },
  );

  test('exit keeps chrome hidden until the window effect completes', () async {
    final response = Completer<void>();
    late final ProviderContainer container;
    container = _container((value) async {
      if (!value) {
        expect(container.read(readerChromeNotifierProvider), isTrue);
        await response.future;
      }
    });
    final controller = container.read(readerChromeNotifierProvider.notifier);
    await controller.setFullscreen(true);
    final pending = controller.setFullscreen(false);
    expect(container.read(readerChromeNotifierProvider), isTrue);
    response.complete();
    await pending;
    expect(container.read(readerChromeNotifierProvider), isFalse);
  });

  for (final failOn in [true, false]) {
    test(
      'failed fullscreen $failOn propagates and leaves chrome hidden',
      () async {
        final failure = StateError('window effect');
        final calls = <bool>[];
        final container = _container((value) async {
          calls.add(value);
          if (value == failOn) throw failure;
        });
        final controller = container.read(
          readerChromeNotifierProvider.notifier,
        );
        if (!failOn) await controller.setFullscreen(true);
        await expectLater(
          controller.setFullscreen(failOn),
          throwsA(same(failure)),
        );
        expect(container.read(readerChromeNotifierProvider), isTrue);
        expect(calls, failOn ? [true] : [true, false]);
      },
    );
  }

  test(
    'toggle reads the current state and repeated conditional exit is inert',
    () async {
      final calls = <bool>[];
      final container = _container((value) async => calls.add(value));
      final controller = container.read(readerChromeNotifierProvider.notifier);
      expect(calls, isEmpty);
      await controller.toggleFullscreen();
      expect(container.read(readerChromeNotifierProvider), isTrue);
      await controller.toggleFullscreen();
      await controller.exitFullscreenIfNeeded();
      await controller.toggleFullscreen();
      await controller.exitFullscreenIfNeeded();
      await controller.exitFullscreenIfNeeded();
      expect(calls, [true, false, true, false]);
      expect(container.read(readerChromeNotifierProvider), isFalse);
    },
  );
}

ProviderContainer _container(Future<void> Function(bool) command) {
  final container = ProviderContainer(
    overrides: [
      readerWindowFullscreenCommandProvider.overrideWithValue(command),
    ],
  );
  addTearDown(container.dispose);
  return container;
}
