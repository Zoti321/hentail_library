import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/reader/data/adapters/native_reader_frb_adapter.dart';
import 'package:hentai_library/features/reader/domain/native_reader_port.dart';
import 'package:hentai_library/shared/di/data_providers.dart';

/// Bootstrap / 测试注入用工厂（跨 feature 仍读 `shared/di` token）。
NativeReaderPort createNativeReaderPort(Ref ref) => NativeReaderFrbAdapter(
  remoteCredentials: ref.read(remoteLibraryCredentialsPortProvider),
);
