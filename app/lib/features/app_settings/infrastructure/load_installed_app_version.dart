import 'package:package_info_plus/package_info_plus.dart';

Future<String> loadInstalledAppVersion() async =>
    (await PackageInfo.fromPlatform()).version;
