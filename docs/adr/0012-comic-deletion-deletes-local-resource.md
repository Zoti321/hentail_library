# ADR-0012: 用户 Comic deletion 删除 Local Resource；sync / 删库不删盘

## Status

Accepted；「用户删除立即删盘、不使用回收站」部分被 ADR-0023 取代（改为 Comic trash → Comic purge），删盘语义与路径安全、sync / 删库不删盘仍有效

## Context

此前用户「删除漫画」只清除库内 Comic 及相关记录，磁盘上的 Resource 仍保留。产品要求改为真正删除源 Resource，同时需与 Library sync orphan 清理、删除整个 Library 区分：后两类常由改根、格式变更、根不可达或移除库配置触发，自动删盘风险过高。

## 现行流程（ADR-0023）

用户主动删除漫画走 **Comic trash → Comic restore / Comic purge** 两段式（见 ADR-0023）：先移入库内回收站、可恢复；**Comic purge** 才执行本节 Decision 中的 Local Resource 删盘与路径安全约束。勿将「从库中移除」与「purge 删盘」混为一谈。

## Decision

- **Comic purge**（及 ADR-0023 之前已落地的「一步删盘」语义在 purge 阶段的等价行为）：对 **Local library**，在 Resource 路径经规范化后落在所属 Library root 之下的前提下，**永久删除**该 Comic 的 Resource（归档文件或图片目录 `dir`），再移除库记录；路径已不存在视为删盘成功；删盘失败则**不**改库。对 **Remote library**，仅从库移除，不扩展 WebDAV 删除。用户菜单上的删除默认进入 **Comic trash**，除非产品流明确为 purge。
- **不**删除 Folder series 父目录、Library root，或同目录下其它 Comic 的 Resource。
- **Library sync** orphan 清理与 **删除 Library** 仍只动库记录，**不**删除磁盘或远程 Resource。
- **Comic purge** 不使用系统回收站；以确认对话框勾选闸门 + 危险样式按钮表达 purge 不可撤销。Comic trash 阶段可经 restore 恢复（ADR-0023）。

## Consequences

### Positive

- 用户主动删除与「磁盘上也要干净」的预期一致
- orphan / 删库不自动删盘，避免改配置或根短暂不可达时误删用户文件
- Local / Remote 语义分开，Remote 不必先做 WebDAV 写删除

### Negative

- 两条「漫画从库消失」路径对磁盘副作用不同，需靠文案与领域词（Comic deletion）持续区分
- **Comic purge** 永久删盘不可恢复；依赖 purge 确认 UI。Comic trash 在 purge 前可恢复（ADR-0023）
