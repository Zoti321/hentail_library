import 'package:hentai_library/domain/ports/reader_session_port.dart';
import 'package:hentai_library/src/rust/api/reader.dart' as rust;

/// [ReaderSessionPort] 委托 Rust 清理阅读会话缓存。
class ReaderSessionFrbAdapter implements ReaderSessionPort {
  const ReaderSessionFrbAdapter();

  @override
  Future<void> clear() async {
    rust.clearReaderSessionsFrb();
  }
}
