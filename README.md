# Hentai Library

基于 Flutter 开发的**本地漫画 / 本子阅读与管理**应用，支持多平台，专注离线阅读体验与个人库管理。

## 本地运行

**环境要求**：Flutter SDK（见 `pubspec.yaml` 中 `environment.sdk`）、Dart 3.10+。

```bash
# 安装依赖
flutter pub get

# 生成代码（Riverpod、Freezed、Drift、json_serializable 等）
dart run build_runner build --delete-conflicting-outputs
```

之后在 IDE 或命令行运行目标设备即可，例如：

```bash
flutter run
```

修改了 `*.freezed.dart` / `*.g.dart` 对应的源码（如 entity、provider、database）后，需重新执行上述 `build_runner` 命令以生成最新代码。

## v2 数据库（开发期说明）

项目正在引入 **v2 独立数据库**（与 v1 并行，不做迁移），用于验证新的表结构/DAO/仓储实现。

- **v2 DB 文件名**：`hentai_library_v2.sqlite`
- **Flutter 运行时位置**：`applicationSupportDirectory`（由 `path_provider` 决定的应用支持目录）
- **开发期清空数据**：关闭应用后，**手动删除**该文件即可重置 v2 数据（不会影响 v1 数据库）。

## 支持平台

| 平台    | 支持 |
| ------- | ---- |
| Android | ✅   |
| iOS     | ✅   |
| Windows | ✅   |
| macOS   | ✅   |
| Linux   | ✅   |

## 屏幕截图

> 截图待补充，敬请期待。

## 功能概览

### 阅读模块

#### 全格式支持

- **压缩包**：CBZ、CBR、7Z、ZIP、RAR
- **文档**：PDF、EPUB
- **图像**：JPG、PNG、WebP、GIF、AVIF

#### 阅读模式

- **卷轴模式（Webtoon）**：纵向无缝滚动，适合条漫
- **单页 / 双页模式**：左右翻页（日漫）或左翻（美漫）
- **跨页处理**：宽图自动拆分为双页，或单页合并为跨页显示

#### 图像与体验

- **预加载**：后台预读后续页面，翻页更流畅
- **图像滤镜**：亮度、对比度、锐化，改善低画质资源观感
- **缩放与裁剪**：页边距锁定，自动裁切漫画白边（Auto-crop）

### 书架与库管理

- **自动扫描与导入**：指定文件夹扫描，从文件名解析并提取封面
- **层级结构**：支持文件夹嵌套，识别「作品 → 卷/话」结构
- **元数据**：
  - 读取 ComicInfo.xml（作者、年份、简介等）
  - 支持手动编辑元数据
- **排序与搜索**：按标题、添加时间、阅读进度、文件大小等多维度排序与检索
- **私密空间**：指纹 / 密码锁，隐藏指定文件夹
