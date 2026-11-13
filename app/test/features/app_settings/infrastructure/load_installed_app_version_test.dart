import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/app_settings/infrastructure/load_installed_app_version.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  test(
    'reads the installed version without replacing or normalizing it',
    () async {
      PackageInfo.setMockInitialValues(
        appName: 'App',
        packageName: 'example.app',
        version: 'V1.2.3+42',
        buildNumber: '99',
        buildSignature: '',
      );
      expect(await loadInstalledAppVersion(), 'V1.2.3+42');
    },
  );
}
