/// Remote library Basic 密码的平台安全存储接缝。
///
/// 密码不进入 SQLite / 明文设置；core 仅在后续 sync/read 经 FRB 使用时由上层注入。
abstract class RemoteLibraryCredentialStore {
  Future<void> savePassword({
    required String libraryId,
    required String password,
  });

  Future<String?> readPassword(String libraryId);

  Future<void> deletePassword(String libraryId);
}
