/// 将已保存的远程 Library 凭据装载到 Rust；不向调用方暴露密码。
abstract class RemoteLibraryCredentialsPort {
  Future<void> pushStoredRemoteCredentialsToRust();
}
