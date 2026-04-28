import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/model/models.dart';
import 'package:hentai_library/domain/repository/app_setting_repo.dart';
import 'package:hentai_library/presentation/providers/deps/repos.dart';
import 'package:hentai_library/presentation/providers/pages/settings/settings_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class _InMemoryAppSettingRepository implements AppSettingRepository {
  _InMemoryAppSettingRepository(this._setting);
  AppSetting _setting;

  @override
  Future<AppSetting> load() async {
    return _setting;
  }

  @override
  Future<void> save(AppSetting setting) async {
    _setting = setting;
  }
}

void main() {
  test('setReaderDimLevel clamps upper bound to 0.8', () async {
    final _InMemoryAppSettingRepository repository =
        _InMemoryAppSettingRepository(AppSetting(readerDimLevel: 0.2));
    final ProviderContainer container = ProviderContainer(
      overrides: [appSettingRepoProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(settingsProvider.future);
    await container.read(settingsProvider.notifier).setReaderDimLevel(1.0);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final AppSetting actual = container.read(settingsProvider).asData!.value;
    expect(actual.readerDimLevel, 0.8);
  });

  test('setReaderDimLevel clamps lower bound to 0.0', () async {
    final _InMemoryAppSettingRepository repository =
        _InMemoryAppSettingRepository(AppSetting(readerDimLevel: 0.3));
    final ProviderContainer container = ProviderContainer(
      overrides: [appSettingRepoProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(settingsProvider.future);
    await container.read(settingsProvider.notifier).setReaderDimLevel(-0.2);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final AppSetting actual = container.read(settingsProvider).asData!.value;
    expect(actual.readerDimLevel, 0.0);
  });

  test('setReaderIsVertical updates global reader mode preference', () async {
    final _InMemoryAppSettingRepository repository =
        _InMemoryAppSettingRepository(AppSetting(readerIsVertical: false));
    final ProviderContainer container = ProviderContainer(
      overrides: [appSettingRepoProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(settingsProvider.future);
    await container.read(settingsProvider.notifier).setReaderIsVertical(true);
    final AppSetting actual = container.read(settingsProvider).asData!.value;
    expect(actual.readerIsVertical, isTrue);
  });

  test('setReaderAutoPlayEnabled updates global autoplay preference', () async {
    final _InMemoryAppSettingRepository repository =
        _InMemoryAppSettingRepository(AppSetting(readerAutoPlayEnabled: false));
    final ProviderContainer container = ProviderContainer(
      overrides: [appSettingRepoProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(settingsProvider.future);
    await container
        .read(settingsProvider.notifier)
        .setReaderAutoPlayEnabled(true);
    final AppSetting actual = container.read(settingsProvider).asData!.value;
    expect(actual.readerAutoPlayEnabled, isTrue);
  });

  test('setReaderAutoPlayIntervalSeconds clamps upper bound to 60', () async {
    final _InMemoryAppSettingRepository repository =
        _InMemoryAppSettingRepository(
          AppSetting(readerAutoPlayIntervalSeconds: 5),
        );
    final ProviderContainer container = ProviderContainer(
      overrides: [appSettingRepoProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(settingsProvider.future);
    await container
        .read(settingsProvider.notifier)
        .setReaderAutoPlayIntervalSeconds(120);
    final AppSetting actual = container.read(settingsProvider).asData!.value;
    expect(actual.readerAutoPlayIntervalSeconds, 60);
  });

  test('setReaderAutoPlayIntervalSeconds clamps lower bound to 1', () async {
    final _InMemoryAppSettingRepository repository =
        _InMemoryAppSettingRepository(
          AppSetting(readerAutoPlayIntervalSeconds: 5),
        );
    final ProviderContainer container = ProviderContainer(
      overrides: [appSettingRepoProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(settingsProvider.future);
    await container
        .read(settingsProvider.notifier)
        .setReaderAutoPlayIntervalSeconds(0);
    final AppSetting actual = container.read(settingsProvider).asData!.value;
    expect(actual.readerAutoPlayIntervalSeconds, 1);
  });
}
