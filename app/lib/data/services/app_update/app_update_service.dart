import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:hentai_library/core/constants/app_update_constants.dart';
import 'package:hentai_library/core/util/semver_utils.dart';
import 'package:hentai_library/domain/models/app_release_info.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppUpdateService {
  AppUpdateService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: AppUpdateConstants.connectTimeout,
              receiveTimeout: AppUpdateConstants.receiveTimeout,
              headers: <String, String>{
                'Accept': 'application/vnd.github+json',
              },
            ),
          );

  final Dio _dio;

  Future<AppReleaseInfo?> fetchLatestStableRelease() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      AppUpdateConstants.releasesApiUrl,
      queryParameters: <String, dynamic>{'per_page': 30},
    );
    final List<dynamic> rawReleases = response.data as List<dynamic>;
    AppReleaseInfo? latestRelease;
    for (final dynamic rawRelease in rawReleases) {
      if (rawRelease is! Map<String, dynamic>) {
        continue;
      }
      if (rawRelease['prerelease'] == true) {
        continue;
      }
      final AppReleaseInfo? parsedRelease = _parseRelease(rawRelease);
      if (parsedRelease == null) {
        continue;
      }
      if (latestRelease == null ||
          SemverUtils.isGreaterThan(
            parsedRelease.version,
            latestRelease.version,
          )) {
        latestRelease = parsedRelease;
      }
    }
    return latestRelease;
  }

  AppReleaseAsset? findPlatformAsset(List<AppReleaseAsset> assets) {
    if (Platform.isWindows) {
      return assets.firstWhereOrNull(
            (AppReleaseAsset asset) =>
                asset.name.toLowerCase().endsWith('.exe') &&
                !asset.name.toLowerCase().contains('portable'),
          ) ??
          assets.firstWhereOrNull(
            (AppReleaseAsset asset) =>
                asset.name.toLowerCase().endsWith('.exe'),
          );
    }
    if (Platform.isMacOS) {
      return assets.firstWhereOrNull(
        (AppReleaseAsset asset) => asset.name.toLowerCase().endsWith('.dmg'),
      );
    }
    if (Platform.isLinux) {
      return assets.firstWhereOrNull(
        (AppReleaseAsset asset) =>
            asset.name.contains('_linux_x64.tar.gz') ||
            asset.name.endsWith('.tar.gz'),
      );
    }
    if (Platform.isAndroid) {
      return assets.firstWhereOrNull(
        (AppReleaseAsset asset) =>
            asset.name.endsWith('_android.apk') || asset.name.endsWith('.apk'),
      );
    }
    return null;
  }

  List<String> parseReleaseNotes(String? body) {
    if (body == null || body.trim().isEmpty) {
      return <String>[];
    }
    return body
        .split('\n')
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .map((String line) => line.replaceFirst(RegExp(r'^[-*]\s*'), '').trim())
        .where((String line) => line.isNotEmpty)
        .toList();
  }

  Future<String> downloadAsset({
    required AppReleaseAsset asset,
    required void Function(int received, int total) onProgress,
    required CancelToken cancelToken,
  }) async {
    final Directory tempDirectory = await getTemporaryDirectory();
    final String savePath = p.join(tempDirectory.path, asset.name);
    final File targetFile = File(savePath);
    if (await targetFile.exists()) {
      await targetFile.delete();
    }
    await _dio.download(
      asset.downloadUrl,
      savePath,
      cancelToken: cancelToken,
      options: Options(
        headers: <String, String>{'Accept': 'application/octet-stream'},
        followRedirects: true,
      ),
      onReceiveProgress: onProgress,
    );
    return savePath;
  }

  AppReleaseInfo? _parseRelease(Map<String, dynamic> rawRelease) {
    final String? tagName = rawRelease['tag_name'] as String?;
    final String? htmlUrl = rawRelease['html_url'] as String?;
    final String? publishedAtRaw = rawRelease['published_at'] as String?;
    if (tagName == null || htmlUrl == null || publishedAtRaw == null) {
      return null;
    }
    final DateTime? publishedAt = DateTime.tryParse(publishedAtRaw);
    if (publishedAt == null) {
      return null;
    }
    final List<AppReleaseAsset> assets = _parseAssets(rawRelease['assets']);
    return (
      version: SemverUtils.normalizeVersion(tagName),
      publishedAt: publishedAt,
      releaseNotes: parseReleaseNotes(rawRelease['body'] as String?),
      htmlUrl: htmlUrl,
      assets: assets,
    );
  }

  List<AppReleaseAsset> _parseAssets(Object? rawAssets) {
    if (rawAssets is! List<dynamic>) {
      return <AppReleaseAsset>[];
    }
    final List<AppReleaseAsset> assets = <AppReleaseAsset>[];
    for (final dynamic rawAsset in rawAssets) {
      if (rawAsset is! Map<String, dynamic>) {
        continue;
      }
      final String? name = rawAsset['name'] as String?;
      final String? downloadUrl = rawAsset['browser_download_url'] as String?;
      if (name == null || downloadUrl == null) {
        continue;
      }
      assets.add((
        name: name,
        downloadUrl: downloadUrl,
        size: (rawAsset['size'] as num?)?.toInt() ?? 0,
      ));
    }
    return assets;
  }
}
