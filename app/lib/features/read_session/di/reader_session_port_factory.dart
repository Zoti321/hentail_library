import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/read_session/data/adapters/reader_session_frb_adapter.dart';
import 'package:hentai_library/features/read_session/domain/reader_session_port.dart';
import 'package:hentai_library/shared/di/data_providers.dart';

/// Bootstrap / 测试注入用工厂（跨 feature 仍读 `shared/di` token）。
ReaderSessionPort createReaderSessionPort(Ref ref) => ReaderSessionFrbAdapter(
  remoteCredentials: ref.read(remoteLibraryCredentialsPortProvider),
);
