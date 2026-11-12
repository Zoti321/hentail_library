import 'package:hentai_library/features/app_settings/domain/app_release_info.dart';
import 'package:hentai_library/shared/application/cancellation_token.dart';

abstract interface class AppUpdateGateway {
  Future<AppReleaseInfo?> fetchLatestStableRelease();
  AppReleaseAsset? findPlatformAsset(List<AppReleaseAsset> assets);
  Future<String> downloadAsset({
    required AppReleaseAsset asset,
    required void Function(int received, int total) onProgress,
    required CancellationToken cancelToken,
  });
}
