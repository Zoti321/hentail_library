import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hentai_library/domain/repositories/remote_library_credential_store.dart';

class FlutterSecureRemoteLibraryCredentialStore
    implements RemoteLibraryCredentialStore {
  const FlutterSecureRemoteLibraryCredentialStore({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static String _key(String libraryId) => 'remote_library_password_$libraryId';

  @override
  Future<void> savePassword({
    required String libraryId,
    required String password,
  }) {
    return _storage.write(key: _key(libraryId), value: password);
  }

  @override
  Future<String?> readPassword(String libraryId) {
    return _storage.read(key: _key(libraryId));
  }

  @override
  Future<void> deletePassword(String libraryId) {
    return _storage.delete(key: _key(libraryId));
  }
}
