# Hentai Library

本项目是一个基于 Flutter 的本地漫画/本子阅读与管理应用，聚焦离线阅读体验、桌面端交互效率与个人库管理。

## 项目状态

- 当前版本：`1.0.0+1`
- Flutter SDK：请使用 `pubspec.yaml` 中 `environment.sdk` 对应版本（当前为 Dart `^3.10.4`）
- 开发重点：桌面端体验优先，多平台能力保持可运行

## 核心功能

### 阅读器

- 支持多种资源格式：`CBZ`、`CBR`、`7Z`、`ZIP`、`RAR`、`PDF`、`EPUB`、`JPG`、`PNG`、`WebP`、`GIF`、`AVIF`
- 多阅读模式：卷轴（Webtoon）、单页、双页、跨页处理
- 阅读增强：预加载、亮度/对比度/锐化、缩放与自动裁边
- 桌面端交互：快捷操作、底部控制栏、全屏与自动播放

### 书架与库管理

- 指定目录扫描与导入
- 识别分层结构（作品/卷/话）
- 元数据支持（含 `ComicInfo.xml`）
- 多维排序与检索（标题、进度、添加时间、文件大小等）

## 支持平台

| 平台 | 支持情况 |
| --- | --- |
| Android | ✅ |
| iOS | ✅ |
| Windows | ✅ |
| macOS | ✅ |
| Linux | ✅ |

## 快速开始

### 1) 安装依赖

```bash
flutter pub get
```

### 2) 生成代码

```bash
dart run build_runner build --delete-conflicting-outputs
```

当你修改了依赖生成的源码（如 `freezed`、`json_serializable`、`riverpod_generator`、`drift` 相关定义）后，请重新执行上面的命令。

### 3) 本地运行

```bash
flutter run
```

如需指定设备：

```bash
flutter devices
flutter run -d windows
```

## 常用开发命令

```bash
# 代码格式化
dart format .

# 静态检查
flutter analyze

# 运行测试
flutter test

# 持续生成代码（开发期推荐）
dart run build_runner watch --delete-conflicting-outputs
```

## 桌面端构建

### Windows

```bash
flutter build windows --release
```

输出目录：`build/windows/x64/runner/Release/`

### macOS

```bash
flutter build macos --release
```

### Linux

```bash
flutter build linux --release
```

## 数据库说明（开发期）

项目目前维护独立的 v2 数据库用于新结构验证。

- 数据库文件名：`hentai_library_v2.sqlite`
- 存储位置：`applicationSupportDirectory`（由 `path_provider` 决定）
- 重置方式：关闭应用后手动删除数据库文件

## 项目结构

```text
lib/
  app/                # 应用启动与全局配置
  config/             # 主题、路由与基础配置
  core/               # 基础能力（错误、日志、工具、国际化）
  data/               # 数据层（DB、DAO、Repository 实现、服务）
  domain/             # 领域层（实体、仓储接口、用例）
  presentation/       # UI 层（页面、组件、状态管理）
test/                 # 单元测试与组件测试
assets/               # 字体、图标与静态资源
```

## 排错指南

### 1) 生成文件冲突

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 2) 平台构建失败

- 执行 `flutter doctor -v` 检查工具链
- 确认本机已安装目标平台依赖（Visual Studio C++、Xcode、Linux toolchain）

### 3) 运行时数据异常

- 关闭应用后备份并清理数据库文件，再重新启动验证
- 优先查看日志输出并定位具体模块（扫描、解析、数据库、渲染）

## 协作建议

- 提交前至少执行：`dart format .`、`flutter analyze`、`flutter test`
- 新增模型/DAO/Provider 后同步更新生成代码
- PR 说明建议包含：改动背景、核心改动点、测试方式、截图（UI 改动）
