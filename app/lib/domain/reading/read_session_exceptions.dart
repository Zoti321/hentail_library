import 'package:hentai_library/core/errors/app_exception.dart';

/// Read session / Resource access 失败的用户可见分类（映射自 core error kinds）。
enum ReadSessionFailureKind {
  /// 目录中找不到 Comic，或 Resource 路径不存在。
  resourceNotFound,

  /// Remote library 主机不可达 / TLS 失败等。
  remoteUnreachable,

  /// Remote library 鉴权失败。
  remoteAuthFailed,

  /// 打开或 Resource access 超时。
  timedOut,

  /// 空页、损坏、类型不匹配等无效内容。
  invalidOrEmptyContent,

  /// 未归入以上类别的加载失败。
  loadFailed,
}

/// 阅读会话无法加载页面（与「零页」区分）。
class ReadSessionPageLoadException extends AppException {
  ReadSessionPageLoadException._(
    super.message, {
    required this.kind,
    super.cause,
    super.stackTrace,
  });

  final ReadSessionFailureKind kind;

  factory ReadSessionPageLoadException.comicNotFound(String comicId) {
    return ReadSessionPageLoadException._(
      '漫画不存在: $comicId',
      kind: ReadSessionFailureKind.resourceNotFound,
    );
  }

  factory ReadSessionPageLoadException.emptyPages({
    required String comicId,
    required String path,
  }) {
    return ReadSessionPageLoadException._(
      '漫画没有可阅读的页面: comicId=$comicId, path=$path',
      kind: ReadSessionFailureKind.invalidOrEmptyContent,
    );
  }

  factory ReadSessionPageLoadException.timedOut({
    required String comicId,
    required String path,
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return ReadSessionPageLoadException._(
      '打开漫画超时: comicId=$comicId, path=$path',
      kind: ReadSessionFailureKind.timedOut,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  factory ReadSessionPageLoadException.loadFailed({
    required String comicId,
    required String path,
    required Object cause,
    StackTrace? stackTrace,
    ReadSessionFailureKind kind = ReadSessionFailureKind.loadFailed,
  }) {
    return ReadSessionPageLoadException._(
      '加载漫画页面失败: comicId=$comicId, path=$path',
      kind: kind,
      cause: cause,
      stackTrace: stackTrace,
    );
  }
}
