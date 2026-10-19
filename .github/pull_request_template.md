## Summary

<!-- 最小可视化：调用树、文件树、Mermaid、伪代码或 diff 草图，让 reviewer 快速看懂改动形状 -->

## Evidence

<!-- 前后对比：失败→通过的测试、命令输出、UI 截图等；UI 改动请附截图 -->

- [ ] 本地 Gate：`./scripts/run-gate.sh`（或说明为何跳过 / 等价检查）
- [ ] 其它：

## Merge danger

<!-- 单向门（迁移、删列、不可逆发布）还是可 revert？影响面：单功能 / 全库 / 全平台？ -->

| | |
| --- | --- |
| **门** | 单向 / 双向（可 revert） |
| **影响面** | （例如：仅阅读器 / FRB+DB / 全平台发布） |
| **需对照** | （可选：`GLOSSARY.md` 词条、`docs/adr/` 编号） |
