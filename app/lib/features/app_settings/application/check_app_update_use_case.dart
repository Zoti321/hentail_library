import 'package:hentai_library/core/util/semver_utils.dart';
import 'package:hentai_library/features/app_settings/domain/app_release_info.dart';

sealed class AppUpdateCheckResult {
  const AppUpdateCheckResult();
}

final class AppUpdateUnavailable extends AppUpdateCheckResult {
  const AppUpdateUnavailable();
}

final class AppUpdateCurrent extends AppUpdateCheckResult {
  const AppUpdateCurrent();
}

final class AppUpdateDismissed extends AppUpdateCheckResult {
  const AppUpdateDismissed();
}

final class AppUpdateAvailable extends AppUpdateCheckResult {
  const AppUpdateAvailable(this.release);

  final AppReleaseInfo release;
}

class CheckAppUpdateUseCase {
  const CheckAppUpdateUseCase({
    required this.fetchLatestRelease,
    required this.readDismissedVersion,
  });

  final Future<AppReleaseInfo?> Function() fetchLatestRelease;
  final String? Function() readDismissedVersion;

  Future<AppUpdateCheckResult> call({
    required String currentVersion,
    required bool respectDismissedVersion,
  }) async {
    final installedVersion = SemverUtils.normalizeVersion(currentVersion);
    final release = await fetchLatestRelease();
    if (release == null) return const AppUpdateUnavailable();
    if (!SemverUtils.isGreaterThan(release.version, installedVersion)) {
      return const AppUpdateCurrent();
    }
    // Read after the request: dismissal can change while the network is pending.
    if (respectDismissedVersion && readDismissedVersion() == release.version) {
      return const AppUpdateDismissed();
    }
    return AppUpdateAvailable(release);
  }
}
