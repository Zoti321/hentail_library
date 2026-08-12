import 'package:hentai_library/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/domain/repositories/library_repository.dart';
import 'package:hentai_library/src/rust/api/sync.dart' as rust;

/// 将安全存储中的 Remote 密码推入 Rust 进程内存，供阅读/缩略图/refresh 使用。
Future<void> pushRemoteLibraryCredentials(
  LibraryRepository libraryRepository,
) async {
  final List<LocalLibrary> libraries = await libraryRepository.list();
  final List<rust.RemoteLibraryCredentialDto> credentials =
      <rust.RemoteLibraryCredentialDto>[];
  for (final LocalLibrary library in libraries) {
    if (!isRemoteLibrary(library)) {
      continue;
    }
    final String? password = await libraryRepository.readRemotePassword(
      library.libraryId,
    );
    if (password == null || password.isEmpty) {
      continue;
    }
    credentials.add(
      rust.RemoteLibraryCredentialDto(
        libraryId: library.libraryId,
        password: password,
      ),
    );
  }
  rust.setRemoteLibraryCredentialsFrb(credentials: credentials);
}
