/// 跨 feature 请 import `features/library_admin/public.dart` 的 [createRemoteLibraryCredentialsPort]；
/// [remoteLibraryCredentialsPortProvider] 在 shared/di 声明。
abstract class RemoteLibraryCredentialsPort {
  Future<void> pushStoredRemoteCredentialsToRust();
}
