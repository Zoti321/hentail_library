import 'package:hentai_library/features/library_admin/public/providers/remote_library_credentials_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/reader/infrastructure/adapters/native_reader_frb_adapter.dart';
import 'package:hentai_library/features/reader/domain/native_reader_port.dart';

/// Bootstrap / 测试注入用工厂（跨 feature 仍读 `shared/di` token）。
NativeReaderPort createNativeReaderPort(Ref ref) => NativeReaderFrbAdapter(
  remoteCredentials: ref.read(remoteLibraryCredentialsPortProvider),
);
