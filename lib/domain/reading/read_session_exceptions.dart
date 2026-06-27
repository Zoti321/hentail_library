import 'package:hentai_library/core/errors/app_exception.dart';

/// 阅读会话无法加载页面（与「零页」区分）。
class ReadSessionPageLoadException extends AppException {
  ReadSessionPageLoadException._(
    super.message, {
    super.cause,
    super.stackTrace,
  });

  factory ReadSessionPageLoadException.comicNotFound(String comicId) {
    return ReadSessionPageLoadException._('漫画不存在: $comicId');
  }

  factory ReadSessionPageLoadException.emptyPages({
    required String comicId,
    required String path,
  }) {
    return ReadSessionPageLoadException._(
      '漫画没有可阅读的页面: comicId=$comicId, path=$path',
    );
  }

  factory ReadSessionPageLoadException.loadFailed({
    required String comicId,
    required String path,
    required Object cause,
    StackTrace? stackTrace,
  }) {
    return ReadSessionPageLoadException._(
      '加载漫画页面失败: comicId=$comicId, path=$path',
      cause: cause,
      stackTrace: stackTrace,
    );
  }
}
