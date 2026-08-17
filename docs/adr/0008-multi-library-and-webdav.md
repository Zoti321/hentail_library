# 多 Library 与 WebDAV Remote library

个人库从「单库 + 多 Saved path」演进为趋近 Komga 的模型：**一个 Library root 对应一个 Library**，可同时存在多个 Library；根分为 **Local**（本机目录）与 **Remote**（用户自建 WebDAV）。每库可有独立配置（如 Supported resource formats）。浏览与搜索默认作用于 Current library；Reading history 跨库全局；Series 不跨库。

Remote library 经 WebDAV 做 Library sync 与阅读：sync 轻量登记（体积/mtime 等），页数等在首次打开时解析回写；阅读纯在线流式，不整本落盘。根不可达时跳过该库且不删除已有 Comic。默认 HTTPS，允许用户显式启用 HTTP（局域网 NAS）。鉴权第一版为 Basic，凭证进平台安全存储。WebDAV 客户端与 Resource access 实现落在 Rust core（`reqwest_dav`），Flutter 不维护第二套协议栈。远程首版 Format group 为 archive + pdf + epub（不含远程 image folder）。缩略图按需生成后写入现有本地 thumb 缓存；不采用 `cached_network_image` 作为远程主路径。

### Considered Options

- **单库挂多个 WebDAV 路径**：改动小，但与「每根一库、每库配置」目标冲突，后续必拆。
- **远程整本镜像到本地再当 Local**：与路径身份、离线模型合拍，但不是「远程库源」，且占盘。
- **Dart WebDAV + FRB 喂字节**：UI 方便，但与 ADR-0002（I/O 在 core）及统一 Resource access 接缝冲突。

### Consequences

- 需迁移现有「多 Saved path ∈ 单库」数据模型与 UI（库切换、每库格式设置）。
- core 引入 HTTP/WebDAV 与 TLS 考量；测试以 Resource access 假实现为最高接缝。
- WebDAV 备份设置/DB、远程 image folder、Digest/客户端证书不在本决策范围内。
