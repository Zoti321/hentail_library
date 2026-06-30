## Parent

#11

## What to build

扩展 Resource 支持 rar/cbr、7z/cb7、pdf：Rust `PageSource` 实现与 scan 元数据解析；`core/vendor` 打包 pdfium、unrar（build.rs + 各平台 Flutter 复制）。Library sync 可发现新格式；阅读器可读新格式。更新 `ResourceType` 与 sync 进度计数。

## Acceptance criteria

- [ ] rar/cbr、7z/cb7、pdf 样本可 Library sync 入库
- [ ] 上述格式可 `open_reader` 并 `load_page_bytes`
- [ ] Windows 桌面构建可找到原生 dll/so；CI 文档说明 fetch-native-deps
- [ ] 仅解压/阅读，不暴露 RAR 压缩 API（许可合规）

## Blocked by

- #16

## Notes

原生库版本与 triple 矩阵需在 PR 中说明；某平台暂缺 vendor 时应编译失败而非静默跳过。
