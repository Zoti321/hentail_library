import 'package:hentai_library/features/library_admin/domain/library_repository.dart';
import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/shared/domain/ports/remote_library_credentials_port.dart';
import 'package:hentai_library/src/rust/api/sync.dart' as rust;

class RemoteLibraryCredentialsFrbAdapter implements RemoteLibraryCredentialsPort {
  const RemoteLibraryCredentialsFrbAdapter(this._libraryRepository);

  final LibraryRepository _libraryRepository;

  @override
  Future<void> pushStoredRemoteCredentialsToRust() async {
    final List<LocalLibrary> libraries = await _libraryRepository.list();
    final List<rust.RemoteLibraryCredentialDto> credentials =
        <rust.RemoteLibraryCredentialDto>[];
    for (final LocalLibrary library in libraries) {
      if (!isRemoteLibrary(library)) {
        continue;
      }
      final String? password = await _libraryRepository.readRemotePassword(
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
}

/// library_admin 内部 FRB adapter 共用（不经过 [RemoteLibraryCredentialsPort]）。
Future<void> pushRemoteLibraryCredentials(
  LibraryRepository libraryRepository,
) {
  return RemoteLibraryCredentialsFrbAdapter(
    libraryRepository,
  ).pushStoredRemoteCredentialsToRust();
}
