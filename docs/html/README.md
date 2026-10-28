# docs/html

**MD3E Lab 全站**给人看的静态 HTML（浏览器直接打开），不是 ADR / Gate 真源。

## 站点结构

| 文件 | 内容 |
|------|------|
| [index.html](./index.html) | 索引 |
| [overview.html](./overview.html) | Lab / Pilot / Cutover、代码布局 |
| [pages.html](./pages.html) | 全部预览页 vs 生产功能 |
| [widgetbook.html](./widgetbook.html) | Widgetbook 组件树 |
| [signoff.html](./signoff.html) | 全应用 Lab 收口（领域汇总 · 嵌套对照 · P0–P2） |
| [reader-signoff.html](./reader-signoff.html) | 重定向至 `signoff.html#sec-reader` |
| [assets/site.css](./assets/site.css) | 共享样式 |

改 `app/widgetbook/md3e_widgetbook_directories.dart` 时请同步更新 `widgetbook.html` 与 `pages.html`。

工程规范仍以 `docs/engineering/`、`docs/adr/` 为准。
