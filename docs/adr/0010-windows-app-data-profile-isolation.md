# ADR-0010: Windows 上按构建变体隔离 App data profile

## Status

Accepted

## Context

本机常同时跑开发构建与发布构建；二者曾共用同一 Application Support 下的 SQLite。开发侧 schema 只升不降后，发布侧易异常（如 UI 一直 loading）。需要在不改动日常发布数据路径的前提下，把非正式构建的应用数据隔开。Loading 挂起的超时/错误上浮不在本决策范围。

## Decision

引入 **App data profile**：`default`（Release）与 `dev`（Debug / Profile）完全独立，硬绑构建变体，不可运行时切换。首版仅 Windows：`CompanyName` 仍为 `com.example`；Release 的 `ProductName` 保持 `hentai_library`（现有数据归 `default`）；Debug/Profile 为 `hentai_library_dev`（`path_provider` 据此分 Application Support 目录）。非 Release 窗口标题加 `[dev]`。其它平台仍共库（已知限制）。

## Consequences

### Positive

- 发布版路径与数据不变；开发迁移不再踩日常库。
- Debug 与 Profile 都走 `dev`，避免用当前分支跑 Profile 时再次污染 `default`。

### Negative

- 非 Windows 平台仍共库，直至补 applicationId / bundle 分离。
- `dev` 首启为空，需重新加 Library root 再 sync（与「完全独立」一致，无拷贝向导）。

### Considered Options

- **仅换 SQLite 文件名**：设置/日志/缓存仍缠在一起，排障面大。
- **同身份下 `profiles/` 子目录**：与「整份 Application Support 隔离」不一致，且易误指目录。
- **换应用身份 / ProductName（采纳）**：发布路径不变，开发侧空 profile 可接受。
- **运行时可切换 profile**：重新引入指错数据的风险；需要拷数据时用文件拷贝，而非运行时切换。
