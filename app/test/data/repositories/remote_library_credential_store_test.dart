import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/repositories/remote_library_credential_store.dart';

class _MemoryCredentialStore implements RemoteLibraryCredentialStore {
  final Map<String, String> _passwords = <String, String>{};

  @override
  Future<void> savePassword({
    required String libraryId,
    required String password,
  }) async {
    _passwords[libraryId] = password;
  }

  @override
  Future<String?> readPassword(String libraryId) async => _passwords[libraryId];

  @override
  Future<void> deletePassword(String libraryId) async {
    _passwords.remove(libraryId);
  }
}

void main() {
  test('credential store keeps password until deleted', () async {
    final _MemoryCredentialStore store = _MemoryCredentialStore();
    await store.savePassword(libraryId: 'lib-a', password: 's3cret');
    expect(await store.readPassword('lib-a'), 's3cret');
    await store.deletePassword('lib-a');
    expect(await store.readPassword('lib-a'), isNull);
  });
}
