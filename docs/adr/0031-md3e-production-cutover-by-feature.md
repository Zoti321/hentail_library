# ADR-0031: MD3E 生产迁移按 feature Cutover，完成后收缩 Lab 目录

## Status

Accepted

## Context

MD3E Lab（`app/lib/md3e/`，见 ADR-0030）已完成 UI 范围收口，设置页 Pilot 已接入真实 `SettingsNotifier`（单一入口，见 `GLOSSARY.md` 中 **MD3E Pilot**）。生产路由其余页面仍是 Baseline UI（ADR-0027、ADR-0028）。

需要决定：

- 迁移的切分单位与完成判定；
- Lab 中的组件、页面与 Widgetbook 支持代码在迁移后归属何处；
- 迁移完成后 Lab 目录与命名如何收尾。

备选方案：

- 按页面切分，允许同一 feature 长期双轨；
- 按 feature 切分，同一 feature 内不分批；
- 迁移后保留 `md3e/` 作为长期 Lab 目录，生产只做局部引用。

前两者会延长双轨期或使 Lab 代码长期驻留生产路径；第三者与 ADR-0027 的 Shell / Layout / Component / Feature 分层不一致。

## Decision

1. **Cutover 单位是 feature**（`GLOSSARY.md` 中 **MD3E Cutover**）。同一 feature 内允许 **spec 分批**：先发布 spec，实现时再拆实施票；spec 批次之间不要求同时完成。feature 的 Cutover 完成判定仍以下列四条同时满足为准：
   1. 该 feature 的生产路由全部渲染 MD3E 页面；
   2. 对应的 Baseline 页面与组件已从该 feature 中删除，不保留双轨；
   3. 门禁全部通过（`./scripts/run-gate.sh` 与导入边界测试）；
   4. 维护者在本地完成手动测试并确认。

2. **组件归属**：
   - 只被一个 feature 使用的 MD3E 组件、页面与场景 pattern，迁入该 feature（`features/<feature>/presentation/`）；
   - 第二个 feature 需要复用时，再提升到 `shared/ui/`，不预先共享；
   - 无业务、仅依赖 props / callback 的通用组件，按 ADR-0027 归入 `shared/ui/widgets/`、`shared/ui/layout/`、`shared/ui/motion/`、`shared/ui/widgets/foundation/`。

3. **Lab 专用代码**（`*_lab_host.dart`、`*_preview_data.dart`、Widgetbook 支持文件）迁入 `app/widgetbook/`，不随生产 `lib/` 发布。

4. **终态**：全部 feature Cutover 完成后，删除 `app/lib/md3e/` 目录，去除生产文件名中的 `md3e_` 前缀，并以门禁测试禁止生产代码 import `md3e/`。

5. **迁移顺序**：`app_settings`（继续完善 Pilot）→ `comic_trash` → `named_metadata` → `home` → `library_browse`（同时收纳 `library_admin` 与 `metadata_backup` 的 UI）→ `reader`。桌面 / 移动应用外壳（shell）在所有 feature 迁完后统一迁移。

## Consequences

### Positive

- 双轨期可控：每个 feature 完成即收缩，不长期并存两套 UI。
- 允许同 feature 内分批写 spec，降低单次规划的体量。
- 生产目录结构与 ADR-0027 的分层一致，Agent 与人类可据此判断新 UI 应落的位置。

### Negative

- `library_browse` 同时承接 `library_admin` 与 `metadata_backup` 的 UI，单次迁移范围较大。
- 迁移期间，`md3e/` 与 `shared/ui/` 会有短期的重复实现，需要通过 Cutover 完成判定及时清理。

## References

- ADR-0017：UI MVVM 与 View / Repository 边界
- ADR-0027：Shell / Layout / Component / Feature 四层与 shared 依赖边界
- ADR-0028：设计系统主骨架与 `buildAppTheme` 装配
- ADR-0030：MD3E Lab 冻结 design-system 文档
- ADR-0032：主题合并为单一主题源
- `GLOSSARY.md`：**MD3E Pilot**、**MD3E Cutover**
