import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/bootstrap/di/composition_overrides.dart';
import 'package:hentai_library/shared/domain/models/app_setting.dart';
import 'package:hentai_library/features/bootstrap/di/deps.dart';
import 'package:hentai_library/features/bootstrap/di/shared_state_overrides.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod/misc.dart' show Override;

/// Shared Settings overrides for shell/settings widget tests.
List<Override> settingsViewTestOverrides({
  AppSetting Function()? settingBuilder,
  PackageInfo? packageInfo,
}) {
  return <Override>[
    ...sharedLibraryStateOverrides(),
    ...bootstrapCompositionOverrides(),
    settingsProvider.overrideWith(
      () => FakeSettingsNotifier(settingBuilder: settingBuilder),
    ),
    packageInfoProvider.overrideWith(
      (Ref ref) async =>
          packageInfo ??
          PackageInfo(
            appName: 'Hentai Library',
            packageName: 'hentai_library',
            version: '1.0.0',
            buildNumber: '1',
          ),
    ),
  ];
}

class FakeSettingsNotifier extends SettingsNotifier {
  FakeSettingsNotifier({AppSetting Function()? settingBuilder})
    : _settingBuilder = settingBuilder;

  final AppSetting Function()? _settingBuilder;

  @override
  Future<AppSetting> build() async => _settingBuilder?.call() ?? AppSetting();
}
