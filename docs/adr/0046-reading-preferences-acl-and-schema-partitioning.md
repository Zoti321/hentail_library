# ADR-0046: 偏好 schema 与领域类型的 ACL 分层（#517）

## Status

Accepted（2026-11-12，#517）

## Context

Phase 4（#503）收尾后，`shared/**` → `features/**` 的 R13 只剩 5 条，全部来自 `app_settings` 与 `reader` 的双向依赖：

- `AppSetting` 实体同时装着 `ReadingMode` / `WebtoonZoomMode` / `AutoPlayMode` 等 **reader 领域枚举**；
- 设置页渲染阅读偏好控件，于是 `app_settings → reader` 存在（`reader_session_preference_types.dart` 的 export 转发、`reading_preference_l10n.dart` 的文案）；
- `reader` 反过来需要 `appSettingsStateProvider` / `appSettingRepoProvider`，于是 `reader → app_settings` 也存在；
- 两者相加构成 public 跨模块环，唯一出路是把端口 / token 留在 `shared/**`，再引入 `ReaderSettingsCommandPort` / `ReaderDisplayPreferencesPort` / `AppThemePreferencesPort` 三个「仅为打破环而存在」的端口和 `shared/di` 的多个槽位 token。

这些端口没有领域价值：它们的每个方法都是 `AppSetting` 某个字段的 setter，参数是枚举。结果是：

- `shared/domain/ports` 与 `shared/di` 里躺着只服务设置读写的东西（违反 ADR-0045 的「生产者拥有」）；
- `app_settings` 认识 reader 的三个枚举，`reader` 认识 `AppSetting` 实体，**两侧语义双向渗漏**；
- 新增一个阅读偏好枚举值时，要同时改 `AppSetting`、迁移函数、三个端口、DI、设置页、reader 面板，六处机械同步。

## Decision

### 1. 严格分层：持久化归设置模块，阅读语义归阅读模块

| 层 | 位置 | 只认识 |
|----|------|--------|
| L1 持久化 schema | `features/app_settings/domain/reading_preferences_schema.dart` | `String` id、`int`、默认值、clamp / normalize |
| L1 传输记录 | `ReadingPreferencesRecord`（同一文件的 typedef） | 全原语 |
| L2 领域值对象 | `features/reader/domain/reading_preferences.dart` | reader 枚举 + `int` |
| 防腐层（ACL） | `features/reader/public/reading_preferences_acl.dart` | 同时 import 两侧，**纯函数** |

`app_settings` **不认识任何阅读枚举**；`reader` **不认识 `AppSetting`**。跨边界只经一条匿名 record（沿用 ADR-0040 的 record 投影）：

```dart
typedef ReadingPreferencesRecord = ({
  String readingModeId,
  String webtoonZoomModeId,
  int webtoonMarginPercent,
  String autoPlayModeId,
  int autoPlayIntervalSeconds,
});
```

### 2. `decode` 是全函数

任意输入（含未知 id、空串、越界数值）都返回**合法**的 `ReadingPreferences`，并把未识别的 id 收进 `unknownIds`：

```dart
typedef DecodedReadingPreferences = ({
  ReadingPreferences value,
  List<String> unknownIds,
});
```

`decode` 不打日志、不抛异常、不做 I/O。上报发生在 provider 层（`readingPreferencesProvider`，只报首次出现的 id，避免 rebuild 刷屏），因此 ACL 可以单测穷举。

### 3. `encode` 是穷尽 switch

对每个枚举字段写显式分支，**不写 `default` / `_ =>`**。新增 `ReadingMode` 等枚举值时编译失败，强制同一次提交里补齐 id。这是「防腐层防腐」的机制，不接受「省事」的兜底分支。

### 4. 单一写入口：`readingPreferencesControllerProvider`

`features/app_settings/public/di/app_settings_providers.dart` 暴露：

- `appSettingsProvider`（`settingsProvider` 的别名，保证 `.future` / `.select` 形态与 owner 一致）
- `appSettingRepositoryProvider`
- `readingPreferencesRecordProvider`（`AsyncValue<AppSetting>` → L1 record，`null` 表示未加载）
- `readingPreferencesControllerProvider`

controller **只有五个按字段写入的方法**，参数是持久化原语（`String` id / `int`）：

```dart
setReadingModeId(String id)
setWebtoonZoomModeId(String id)
setWebtoonMarginPercent(int percent)
setAutoPlayModeId(String id)
setAutoPlayIntervalSeconds(int seconds)
```

**不提供整条 record 的整体写入**：并发的两次整条写入会互相覆盖，按字段写入天然是 read-modify-write 的最小粒度。

### 5. 设置页分区：owner 提供自己的 UI

- `reader` 提供 `readerSettingsSections(context)`（`reader/public/ui/reading_settings_sections.dart`）；
- `metadata_backup` 提供自身分区；
- 组合发生在 `bootstrap` 的 `app_router.dart`：`SettingsPage(sectionsBuilder: ...)`。

`SettingsPage` 无 `sectionsBuilder` 时只渲染 `app_settings` 自有分类——这条「最小可用」行为由 widget 测试锁定。**不设 `shared/di` 槽位 token**：分区是编译期组合，不需要运行期替换。

### 6. 智能匹配开关归位

`AppSetting.smartFacetMatchEnabled`（默认 `true`）取代 comic 侧的 SharedPreferences 键 `smart_facet_match_enabled`。迁移在 `AppSettingRepositoryImpl.load()` 内单向完成：读到旧键 → 写入 `AppSetting` → 删除旧键；旧键缺失时**不写**（不把默认值落盘）。

### 7. 门禁

- `app/test/architecture/baseline.json` → `[]`（R13 归零）；
- 禁止边表新增 `app_settings ↛ {reader, library_browse, comic, series, metadata_backup}`；
- 形状门禁 `app/test/architecture/reading_preferences_acl_shape_test.dart` 锁定：id 白名单两侧一致、`encode`↔`decode` 在全部合法值域上双射、`decode` 对任意输入不抛异常。

## 放弃的替代方案

1. **端口 + DI 槽位（现状）**：`ReaderSettingsCommandPort` 等方法签名仍暴露 `ReadingMode` 等枚举，`app_settings` 仍认识 reader 语义；而且每加一个偏好就要加一个端口方法 + 一处 override。它只把「双向 import」换成了「双向 DI」，环依然要靠 `shared/**` 兜底。驳回。
2. **把 `ReadingPreferences` 搬进 `shared/domain`**：`shared` 一旦认识 reader 枚举，就制造 `shared → features/reader`（R13 反方向）；若把枚举一起搬进 shared，则 reader 的领域语义被 shared 拥有，违反 ADR-0035 的 Catalog Shared Kernel 边界。驳回。
3. **让 `app_settings` 直接 import `reader` 的领域类型（或反之）**：这是最省事的写法，但双向 import 就是环本身；单侧留边只会在下一个消费方出现时复发。驳回。
4. **`decode` 抛异常 / 返回 `null`**：把「未知 id」变成调用方必须处理的错误路径，阅读器会因为一个脏字符串打不开。全函数 + `unknownIds` 上报是唯一不会让用户看到崩溃的选择。驳回。

## Consequences

### Positive

- `app_settings ↛ reader`、`reader ↛ app_settings/domain|presentation` 两条边都被门禁锁死，R13 baseline `[]`。
- 新增阅读偏好 = schema 加 id + ACL 加分支 + 领域加字段；`app_settings` 侧只改一个 `String` / `int` 字段，设置页与 reader 面板互不牵连。
- ACL 是纯函数，可对全部枚举组合做穷举双射测试，不需要 widget / DI。
- `shared/di` 里不再有「为打破环而存在」的设置槽位 token。

### Negative

- `AppSetting` 的阅读字段变成 `String`，**在设置模块内部**不再是类型安全的枚举。代价被两层收口：schema 的 id 白名单常量 + ACL 的穷尽 switch + 形状门禁。
- 每个偏好字段要经过 `AppSetting → record → ACL → ReadingPreferences` 四跳，读写路径比直接字段访问长；可读性靠命名与单点投影（`readingPreferencesRecordOf`）保证。
- 未知 id 会被静默回退默认值，只在日志中出现。这是「用户能继续读」优先于「报错」的有意取舍。

## 与既有 ADR 的关系

- **ADR-0034**：跨模块只 import `features/*/public/**`；本文档新增 `reading_preferences_schema.dart`、`reading_preferences_acl.dart`、`di/app_settings_providers.dart`、`reading_preferences_providers.dart` 四个 public 面。
- **ADR-0035**：Catalog Shared Kernel 范围不变；阅读偏好**不**进 shared。
- **ADR-0036**：禁止边表是本决策的强制手段；`app_settings` 的出边在此新增。
- **ADR-0039**：命令走 Port、事实走领域事件不变。本文档说明的是：**当 Port 只为打破 import 环而存在，且方法全是字段 setter 时，应改为 ACL + record**，而不是继续增加 Port。
- **ADR-0040**：跨模块只读投影继续用匿名 record；`ReadingPreferencesRecord` 是同一模式的写读两用版本。
- **ADR-0045**：§5 的 5 条 R13 豁免前提（双向依赖）被本文档消除，豁免随之作废；Port / 读模型仍按可达性归生产者。
