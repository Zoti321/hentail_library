import 'package:hentai_library/data/services/comic/read_resource_get/api/read_resource_get_service.dart';
import 'package:hentai_library/domain/ports/reader_session_port.dart';

/// [ReaderSessionPort] 的 data 层 adapter。
class ReaderSessionAdapter implements ReaderSessionPort {
  const ReaderSessionAdapter({
    required ReadResourceGetService readResourceGetService,
  }) : _readResourceGetService = readResourceGetService;

  final ReadResourceGetService _readResourceGetService;

  @override
  Future<void> clear() => _readResourceGetService.clear();
}
