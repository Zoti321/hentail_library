import 'package:hentai_library/domain/util/enums.dart';

/// 漫画阅读资源访问相关异常基类。
class ComicReadResourceException implements Exception {
  ComicReadResourceException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() {
    return 'ComicReadResourceException: $message'
        '${cause == null ? '' : ' (cause: $cause)'}';
  }
}

/// 路径不存在或不可访问。
class ComicReadResourceNotFoundException extends ComicReadResourceException {
  ComicReadResourceNotFoundException({required this.path})
    : super('路径不存在: $path');

  final String path;
}

/// 路径形态与声明的 [ResourceType] 不一致。
class ComicReadResourceKindMismatchException extends ComicReadResourceException {
  ComicReadResourceKindMismatchException({
    required this.path,
    required this.expectedType,
    required this.detail,
  }) : super('资源类型与路径不一致: path=$path expected=$expectedType $detail');

  final String path;
  final ResourceType expectedType;
  final String detail;
}

/// 当前未实现的资源类型（如 cbr/rar）。
class ComicReadResourceUnsupportedTypeException extends ComicReadResourceException {
  ComicReadResourceUnsupportedTypeException({required this.type})
    : super('暂不支持的资源类型: ${type.name}');

  final ResourceType type;
}

/// 容器内无可用图片或索引越界等业务错误。
class ComicReadResourceInvalidContentException extends ComicReadResourceException {
  ComicReadResourceInvalidContentException({required String message, Object? cause})
    : super(message, cause: cause);
}
