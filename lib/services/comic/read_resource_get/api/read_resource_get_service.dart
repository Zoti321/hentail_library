import 'package:hentai_library/model/enums.dart';
import 'package:hentai_library/services/comic/read_resource_get/core/comic_read_resource_accessor.dart';
import 'package:hentai_library/services/comic/read_resource_get/internal/session/comic_read_resource_session_manager.dart';

/// 阅读资源服务门面：对外统一暴露 acquire/clear。
abstract class ReadResourceGetService {
  Future<ComicReadResourceAccessor> acquire({
    required String comicId,
    required String path,
    required ResourceType type,
  });

  Future<void> clear();
}

/// 默认门面实现：内部委托给会话管理器。
class DefaultReadResourceGetService implements ReadResourceGetService {
  DefaultReadResourceGetService({required ComicReadResourceSessionManager sessions})
    : _sessions = sessions;

  final ComicReadResourceSessionManager _sessions;

  @override
  Future<ComicReadResourceAccessor> acquire({
    required String comicId,
    required String path,
    required ResourceType type,
  }) {
    return _sessions.acquire(comicId: comicId, path: path, type: type);
  }

  @override
  Future<void> clear() {
    return _sessions.clear();
  }
}

