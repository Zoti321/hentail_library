import 'dart:async';

import 'package:hentai_library/features/app_settings/domain/app_setting.dart';
import 'package:hentai_library/features/app_settings/domain/reading_preferences_schema.dart';
import 'package:hentai_library/features/app_settings/presentation/providers/app_setting_repository_provider.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/settings_notifier.dart';
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

import '../../../../support/fakes/settings_test_fakes.dart';

class _ControlledRepository extends MemoryAppSettingRepository {
  _ControlledRepository({super.initial});

  final writes = <AppSetting>[];
  final completions = [Completer<void>(), Completer<void>()];
  final started = [Completer<void>(), Completer<void>()];
  var active = 0;
  var maxActive = 0;

  @override
  Future<void> save(AppSetting setting) async {
    final index = writes.length;
    writes.add(setting);
    active++;
    if (active > maxActive) maxActive = active;
    started[index].complete();
    try {
      await completions[index].future;
      await super.save(setting);
    } finally {
      active--;
    }
  }
}

ProviderContainer _container(_ControlledRepository repository) =>
    ProviderContainer(
      overrides: [appSettingRepositoryProvider.overrideWithValue(repository)],
    );

void main() {
  test('an earlier failed write cannot roll back a later accepted locale', () async {
    final initial = AppSetting();
    final repository = _ControlledRepository(initial: initial);
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(settingsProvider.future);
    final notifier = container.read(settingsProvider.notifier);
    final first = notifier.setThemePreference(AppThemePreference.dark);
    final second = notifier.setLocalePreference(AppLocalePreference.en);
    final optimistic = container.read(settingsProvider).requireValue;
    // A later success may already be ready while the earlier write is pending.
    repository.completions[1].complete();
    repository.completions[0].completeError(StateError('theme write failed'));
    await Future.wait([first, second]);
    final persisted = await repository.load();
    expect(optimistic.themePreference, AppThemePreference.dark);
    expect(optimistic.localePreference, AppLocalePreference.en);
    expect(container.read(settingsProvider).requireValue, persisted);
    expect(persisted.localePreference, AppLocalePreference.en);
    expect(repository.writes, hasLength(2));
  });

  test('whole settings snapshots save serially in acceptance order while UI remains optimistic', () async {
    final repository = _ControlledRepository();
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(settingsProvider.future);
    final notifier = container.read(settingsProvider.notifier);
    final first = notifier.setThemePreference(AppThemePreference.dark);
    final second = notifier.setLocalePreference(AppLocalePreference.en);
    await repository.started[0].future;
    final pendingWrites = repository.writes.length;
    final optimistic = container.read(settingsProvider).requireValue;
    repository.completions[0].complete();
    await repository.started[1].future;
    repository.completions[1].complete();
    await Future.wait([first, second]);
    expect(pendingWrites, 1);
    expect(repository.maxActive, 1);
    expect(optimistic.themePreference, AppThemePreference.dark);
    expect(optimistic.localePreference, AppLocalePreference.en);
    expect(
      repository.writes.map((s) => (s.themePreference, s.localePreference)),
      [
        (AppThemePreference.dark, AppLocalePreference.system),
        (AppThemePreference.dark, AppLocalePreference.en),
      ],
    );
    expect(await repository.load(), optimistic);
  });

  test('two failed saves roll back to the truly persisted snapshot', () async {
    final initial = AppSetting();
    final repository = _ControlledRepository(initial: initial);
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(settingsProvider.future);
    final notifier = container.read(settingsProvider.notifier);
    final first = notifier.setThemePreference(AppThemePreference.dark);
    final second = notifier.setLocalePreference(AppLocalePreference.en);
    await repository.started[0].future;
    repository.completions[0].completeError(StateError('first failure'));
    await first;
    final afterFirstFailure = container.read(settingsProvider).requireValue;
    await repository.started[1].future;
    repository.completions[1].completeError(StateError('second failure'));
    await second;
    expect(afterFirstFailure.localePreference, AppLocalePreference.en);
    expect(container.read(settingsProvider).requireValue, initial);
    expect(await repository.load(), initial);
    expect(repository.writes, hasLength(2));
  });

  for (final kind in ['generic', 'reader', 'sidebar']) {
    test(
      '$kind failure preserves its existing UI policy without retrying',
      () async {
        final initial = AppSetting();
        final failure = StateError('$kind failure');
        final repository = _ControlledRepository(initial: initial);
        final container = _container(repository);
        addTearDown(container.dispose);
        await container.read(settingsProvider.future);
        final notifier = container.read(settingsProvider.notifier);
        final saving = switch (kind) {
          'generic' => notifier.setThemePreference(AppThemePreference.dark),
          'reader' => notifier.setReadingModeId(
            ReadingPreferenceSchema.readingModeWebtoonId,
          ),
          _ => notifier.setDesktopSidebarExpanded(false),
        };
        final optimistic = container.read(settingsProvider).requireValue;
        expect(optimistic, isNot(initial));
        await repository.started[0].future;
        repository.completions[0].completeError(failure);
        await expectLater(saving, completes);
        final state = container.read(settingsProvider);
        if (kind == 'generic') {
          expect(state.requireValue, initial);
        } else {
          expect(state.hasError, isTrue);
          expect(state.error, same(failure));
        }
        expect(await repository.load(), initial);
        expect(repository.writes, [optimistic]);
      },
    );
  }

  test(
    'synchronous state listener reentry cannot reverse save order',
    () async {
      final initial = AppSetting();
      final repository = _ControlledRepository(initial: initial);
      final container = _container(repository);
      addTearDown(container.dispose);
      await container.read(settingsProvider.future);
      final notifier = container.read(settingsProvider.notifier);
      var reentered = false;
      Future<void>? second;
      final subscription = container.listen(settingsProvider, (_, next) {
        if (!reentered &&
            next.asData?.value.themePreference == AppThemePreference.dark) {
          reentered = true;
          second = notifier.setLocalePreference(AppLocalePreference.en);
        }
      });
      addTearDown(subscription.close);
      final first = notifier.setThemePreference(AppThemePreference.dark);
      await repository.started[0].future;
      repository.completions[0].complete();
      await repository.started[1].future;
      repository.completions[1].complete();
      await Future.wait([first, second!]);
      expect(repository.writes.map((s) => s.localePreference), [
        AppLocalePreference.system,
        AppLocalePreference.en,
      ]);
      expect(repository.maxActive, 1);
      expect(
        (await repository.load()).localePreference,
        AppLocalePreference.en,
      );
      expect(
        container.read(settingsProvider).requireValue.localePreference,
        AppLocalePreference.en,
      );
    },
  );

  test(
    'generic reset accepted from an error state retains AsyncError on failure',
    () async {
      final initial = AppSetting(themePreference: AppThemePreference.dark);
      final repository = _ControlledRepository(initial: initial);
      final container = _container(repository);
      addTearDown(container.dispose);
      await container.read(settingsProvider.future);
      final notifier = container.read(settingsProvider.notifier);
      final readerFailure = StateError('reader failed');
      final reader = notifier.setReadingModeId(
        ReadingPreferenceSchema.readingModeWebtoonId,
      );
      await repository.started[0].future;
      repository.completions[0].completeError(readerFailure);
      await reader;
      expect(container.read(settingsProvider).error, same(readerFailure));
      final resetFailure = StateError('reset failed');
      final reset = notifier.resetToDefaults();
      await repository.started[1].future;
      repository.completions[1].completeError(resetFailure);
      await expectLater(reset, completes);
      expect(container.read(settingsProvider).hasError, isTrue);
      expect(container.read(settingsProvider).error, same(resetFailure));
      expect(await repository.load(), initial);
      expect(repository.writes, hasLength(2));
    },
  );

  for (final fails in [false, true]) {
    test(
      'accepted writes finish after disposal even when the first ${fails ? 'fails' : 'succeeds'}',
      () async {
        final repository = _ControlledRepository();
        final container = _container(repository);
        await container.read(settingsProvider.future);
        final notifier = container.read(settingsProvider.notifier);
        final first = notifier.setThemePreference(AppThemePreference.dark);
        final second = notifier.setLocalePreference(AppLocalePreference.en);
        final observed = expectLater(Future.wait([first, second]), completes);
        await repository.started[0].future;
        container.dispose();
        if (fails) {
          repository.completions[0].completeError(
            StateError('write failed after disposal'),
          );
        } else {
          repository.completions[0].complete();
        }
        await repository.started[1].future;
        repository.completions[1].complete();
        await observed;
        expect(repository.writes, hasLength(2));
        expect(
          (await repository.load()).localePreference,
          AppLocalePreference.en,
        );
      },
    );
  }
}
