import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:hentai_library/features/media/public/widgets.dart';
import 'package:hentai_library/features/resource_metadata/public/providers.dart';
import 'package:hentai_library/features/resource_metadata/public/widgets.dart';
import 'package:hentai_library/features/library_admin/public/providers.dart';
import 'package:hentai_library/features/library_admin/public/contracts.dart';
import 'package:hentai_library/features/app_settings/public.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/design-system/design_system.dart';

import '../../../support/fakes/resource_metadata_test_gateway.dart';
import '../../../support/fakes/settings_test_fakes.dart';
import '../../../support/pump_localized_app.dart';

class _Libraries extends LibrariesNotifier {
  @override
  Future<LibrariesState> build() async => const LibrariesState(
    libraries: [
      (
        libraryId: 'lib',
        kind: 'local',
        rootPath: '/Comics',
        name: '本地漫画库',
        enabledResourceFormatCategories: [],
        username: '',
        allowHttp: false,
        scanOnStartup: false,
        scanInterval: ScanInterval.disabled,
        pinned: false,
        sidebarOrder: 0,
      ),
      (
        libraryId: 'remote',
        kind: 'remote',
        rootPath: 'https://example.test',
        name: 'Remote library',
        enabledResourceFormatCategories: [],
        username: '',
        allowHttp: false,
        scanOnStartup: false,
        scanInterval: ScanInterval.disabled,
        pinned: false,
        sidebarOrder: 1,
      ),
    ],
  );
}

Future<void> _pump(
  WidgetTester tester,
  ResourceMetadataTestGateway gateway, {
  Locale locale = const Locale('zh'),
  ThemeData? theme,
  double textScale = 1,
}) async {
  await pumpLocalizedApp(
    tester,
    locale: locale,
    theme: theme,
    overrides: [
      writebackGatewayProvider.overrideWithValue(gateway),
      librariesProvider.overrideWith(_Libraries.new),
      settingsProvider.overrideWith(() => FakeSettingsNotifier()),
    ],
    home: M3ETheme(
      data: buildAppM3eThemeData(theme?.brightness ?? Brightness.light),
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: const MediaPage(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'overview shows aggregate counts and local library controls only',
    (tester) async {
      configureTestView(tester, const Size(1200, 1100));
      final gateway = ResourceMetadataTestGateway();
      await _pump(tester, gateway);
      final l10n = AppLocalizations.of(tester.element(find.byType(MediaPage)));
      expect(find.text('24'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text(l10n.mediaWritingOverview), findsOneWidget);
      expect(find.text('本地漫画库'), findsOneWidget);
      expect(find.text('Remote library'), findsNothing);
      expect(find.byType(DropdownButton<String>), findsNothing);
      expect(find.byType(ListTile), findsNothing);
      expect(gateway.processed, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('periodic refresh retains visible content while awaiting IO', (
    tester,
  ) async {
    final gateway = ResourceMetadataTestGateway();
    await _pump(tester, gateway);
    final card = find.text('24');
    final element = tester.element(card);
    final position = tester.getTopLeft(card);
    final response = Completer<void>();
    gateway.queryDelay = response.future;
    final reads = gateway.enabledReads;
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(find.text('24'), findsOneWidget);
    expect(tester.element(card), same(element));
    expect(tester.getTopLeft(card), position);
    expect(gateway.enabledReads, reads);
    response.complete();
    await tester.pumpAndSettle();
    expect(find.text('24'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'revision reload retains content and failed refresh keeps last counts',
    (tester) async {
      final gateway = ResourceMetadataTestGateway();
      await _pump(tester, gateway);
      final l10n = AppLocalizations.of(tester.element(find.byType(MediaPage)));
      final response = Completer<void>();
      gateway.queryDelay = response.future;
      final scope = ProviderScope.containerOf(
        tester.element(find.byType(MediaPage)),
      );
      scope.read(writebackRevisionProvider.notifier).changed();
      await tester.pump();
      expect(find.text('24'), findsOneWidget);
      gateway.queryError = StateError('unavailable');
      response.complete();
      await tester.pumpAndSettle();
      expect(find.text('24'), findsOneWidget);
      expect(find.text(l10n.mediaRefreshFailed), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'initial failure can retry the read without processing resources',
    (tester) async {
      final gateway = ResourceMetadataTestGateway()
        ..queryError = StateError('unavailable');
      await _pump(tester, gateway);
      final l10n = AppLocalizations.of(tester.element(find.byType(MediaPage)));
      expect(find.text(l10n.shellLoadFailed), findsOneWidget);
      gateway.queryError = null;
      await tester.tap(find.text(l10n.commonRetry));
      await tester.pumpAndSettle();
      expect(find.text('24'), findsOneWidget);
      expect(gateway.processed, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'overview polling pauses in background and stops after disposal',
    (tester) async {
      final gateway = ResourceMetadataTestGateway();
      await _pump(tester, gateway);
      final initial = gateway.queries.length;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 10));
      expect(gateway.queries, hasLength(initial));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(gateway.queries.length, greaterThan(initial));
      final afterResume = gateway.queries.length;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 10));
      expect(gateway.queries, hasLength(afterResume));
    },
  );

  for (final config in [
    (
      size: const Size(390, 844),
      scale: 1.0,
      locale: const Locale('zh'),
      brightness: Brightness.light,
    ),
    (
      size: const Size(390, 844),
      scale: 2.0,
      locale: const Locale('en'),
      brightness: Brightness.dark,
    ),
    (
      size: const Size(1440, 1000),
      scale: 1.0,
      locale: const Locale('en'),
      brightness: Brightness.dark,
    ),
  ]) {
    testWidgets('overview adapts to $config without overflow', (tester) async {
      configureTestView(tester, config.size);
      await _pump(
        tester,
        ResourceMetadataTestGateway(),
        locale: config.locale,
        theme: buildAppTheme(config.brightness),
        textScale: config.scale,
      );
      expect(find.text('24'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.byType(WritebackSetting),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byType(WritebackSetting), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
    'automatic lifecycle notifies once per batch and stops after disposal',
    (tester) async {
      final gateway = ResourceMetadataTestGateway()..remainingJobs = 3;
      await pumpLocalizedApp(
        tester,
        overrides: [writebackGatewayProvider.overrideWithValue(gateway)],
        home: const WritebackLifecycle(child: SizedBox.shrink()),
      );
      final scope = ProviderScope.containerOf(
        tester.element(find.byType(WritebackLifecycle)),
      );
      final revision = scope.read(writebackRevisionProvider);
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
      expect(gateway.processed, 4);
      expect(scope.read(writebackRevisionProvider), revision + 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 5));
      expect(gateway.processed, 4);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(gateway.processed, 5);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 10));
      expect(gateway.processed, 5);
    },
  );

  testWidgets(
    'opt in needs affirmative explanation and shares the persisted setting',
    (tester) async {
      final gateway = ResourceMetadataTestGateway();
      await pumpLocalizedApp(
        tester,
        overrides: [writebackGatewayProvider.overrideWithValue(gateway)],
        home: const Scaffold(body: WritebackSetting(libraryId: 'lib')),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(WritebackSetting)),
      );
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.text(l10n.writebackConfirmTitle), findsOneWidget);
      expect(gateway.enabled['lib'], isNull);
      await tester.tap(find.text(l10n.writebackEnable));
      await tester.pumpAndSettle();
      expect(gateway.enabled['lib'], isTrue);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    },
  );
}
