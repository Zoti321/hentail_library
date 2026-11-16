/// GitHub 仓库与更新检查相关常量。
abstract final class AppUpdateConstants {
  static const String githubOwner = 'Zoti321';
  static const String githubRepo = 'hentail_library';
  static const String releasesApiUrl =
      'https://api.github.com/repos/$githubOwner/$githubRepo/releases';
  static const Duration startupCheckDelay = Duration(seconds: 3);
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
