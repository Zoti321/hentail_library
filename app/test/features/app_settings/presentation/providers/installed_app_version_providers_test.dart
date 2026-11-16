import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/app_settings/presentation/patterns/settings/settings_catalog.dart';
import 'package:hentai_library/features/app_settings/presentation/providers/installed_app_version_providers.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/settings_notifier.dart';
import 'package:hentai_library/features/app_settings/presentation/views/settings_page/settings_sections.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:riverpod/misc.dart' show ProviderException;

import '../../../../support/fakes/settings_test_fakes.dart';
import '../../../../support/pump_localized_app.dart';

void main() {
  test('the native version query requires explicit injection', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(
      () => container.read(installedAppVersionQueryProvider),
      throwsA(
        isA<ProviderException>().having(
          (error) => error.toString(),
          'message',
          contains('installedAppVersionQueryProvider 未注入'),
        ),
      ),
    );
  });

  test(
    'readers share the pending result and cache until invalidation',
    () async {
      var response = Completer<String>();
      var calls = 0;
      final container = _container(() {
        calls++;
        return response.future;
      });
      container.read(installedAppVersionQueryProvider);
      expect(calls, 0);
      final first = container.read(installedAppVersionProvider.future);
      final second = container.read(installedAppVersionProvider.future);
      expect(container.read(installedAppVersionProvider).isLoading, isTrue);
      expect(calls, 1);
      response.complete('V1.2.3+42');
      expect(await first, 'V1.2.3+42');
      expect(await second, 'V1.2.3+42');
      expect(
        await container.read(installedAppVersionProvider.future),
        'V1.2.3+42',
      );
      expect(calls, 1);

      response = Completer<String>();
      container.invalidate(installedAppVersionProvider);
      final refreshed = container.read(installedAppVersionProvider.future);
      response.complete('2.0.0');
      expect(await refreshed, '2.0.0');
      expect(calls, 2);
    },
  );

  test(
    'query failures remain visible as the original asynchronous error',
    () async {
      final failure = StateError('native package info');
      final container = _container(() async => throw failure);
      await expectLater(
        container.read(installedAppVersionProvider.future),
        throwsA(same(failure)),
      );
      expect(container.read(installedAppVersionProvider).error, same(failure));
    },
  );

  testWidgets('About and Updates share loading and the installed version', (
    tester,
  ) async {
    final response = Completer<String>();
    var calls = 0;
    final container = _container(() {
      calls++;
      return response.future;
    });
    await pumpLocalizedApp(tester, home: _sections(container));
    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));
    final checkTile = find.widgetWithText(
      SettingsNavigationTile,
      l10n.settingsCheckForUpdatesLabel,
    );
    expect(find.text(l10n.settingsCurrentVersionLoading), findsNWidgets(2));
    expect(tester.widget<SettingsNavigationTile>(checkTile).onTap, isNull);
    expect(calls, 1);

    response.complete('V1.2.3+42');
    await tester.pumpAndSettle();
    expect(
      find.text(l10n.settingsCurrentVersion('V1.2.3+42')),
      findsNWidgets(2),
    );
    expect(tester.widget<SettingsNavigationTile>(checkTile).onTap, isNotNull);
    expect(calls, 1);
  });

  testWidgets(
    'version errors retain the fallback label and allow a manual check',
    (tester) async {
      final container = _container(
        () async => throw StateError('native package info'),
      );
      await pumpLocalizedApp(tester, home: _sections(container));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));
      expect(find.text(l10n.settingsCurrentVersionLoading), findsNWidgets(2));
      final checkTile = find.widgetWithText(
        SettingsNavigationTile,
        l10n.settingsCheckForUpdatesLabel,
      );
      expect(tester.widget<SettingsNavigationTile>(checkTile).onTap, isNotNull);
    },
  );
}

ProviderContainer _container(Future<String> Function() query) {
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      installedAppVersionQueryProvider.overrideWithValue(query),
      settingsProvider.overrideWith(() => FakeSettingsNotifier()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Widget _sections(ProviderContainer container) => UncontrolledProviderScope(
  container: container,
  child: Builder(
    builder: (context) => Scaffold(
      body: Column(
        children: [
          ...settingsSectionsFor(SettingsCategory.about, context),
          ...settingsSectionsFor(SettingsCategory.updates, context),
        ],
      ),
    ),
  ),
);
