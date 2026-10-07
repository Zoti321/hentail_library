# ADR-0025: Author 平台形象解析采用本地可信来源适配器

## Status

Accepted

## Context

Issue #202 需要为 Author image 增加平台来源：用户保存 Creative platform 的 Author link 后，应用尝试获取平台显示名、avatar 与 background，并在平台显示名不同于 Author 当前显示名时展示 Author alias。

KK Library 的公开产品行为提供了本决策的产品参考：本地优先、网络可选、使用官方来源作为 Author profile 的资料来源，并维护可信作者来源，而不是把任意外链都当作可信资料。

本项目已有以下约束：

- Author link 是用户手填 URL；Author 具有稳定 id，rename 不改变身份。
- Creative platform 闭集与优先级为 Pixiv > X > Patreon > FANBOX > Discord；Other 不参与形象解析或 alias。
- #204 已提供统一的 `load_author_image(author_id, slot)` 与 App data profile 下的 `ImageCache`。
- ADR-0002 要求网络、文件和数据库业务集中在 Rust core，Flutter 只保留 UI 与薄 Repository。
- 应用不提供 OAuth、平台账号绑定、平台 token、代理设置或远程规则清单；代理由用户自行准备。
- 平台适配器不得依赖脆弱 DOM/CSS 刮削。无法从明确支持的公开资料 URL 合规解析时，必须静默失败并回退。

## Decision

### Source model

- 五个平台首版均提供平台适配器：Pixiv、X、Patreon、FANBOX、Discord。
- 其中 Discord 无公开用户资料 API，适配器只校验公开链接形状，不抓取显示名与图片（见文末修订）。
- “可用”定义为：平台有适配器并支持明确的公开资料 URL 形状；不承诺任意作品页、帖子页、首页、邀请页或其他非资料页 URL 都能解析。
- 平台级 URL 规则和解析能力随应用版本发布，不从远程服务器下载规则。
- 不符合 URL 规则的 Author link 保留原样，解析状态为 Unsupported，不写入新的显示名或图片缓存。
- 五个平台适配器只负责资料解析，返回 `display_name`、`avatar_url`、`background_url`；统一 orchestrator 负责优先级、下载、缓存和持久化。

### Source selection

- 平台按 Pixiv > X > Patreon > FANBOX > Discord 选择。
- 同一平台的多个 Author link 按 `sort_key ASC, id ASC` 依次尝试。
- avatar 与 background 按 slot 独立选择和回退。
- `Other` link 不参与 Verified author、Author alias 或 Author image。
- Author 主显示名只能由用户维护，平台资料不能自动修改 `authors.name`。

### Network and credentials

- 所有网络请求、解析、下载和缓存写入在 Rust core 完成。
- 不引入 OAuth、平台登录、平台 token 存储或应用内代理设置。
- 代理行为完全由用户的系统或运行环境提供。
- 统一 downloader 只允许 HTTP(S)，限制重定向、超时、响应大小和图片格式，并拒绝 localhost、回环地址、私网地址及本地解析地址。
- 平台适配器不能自行下载任意 HTML 中的 URL；图片 URL 必须由该平台适配器明确识别并返回。

### Persistence and cache

- 成功解析的 `platform_display_name` 写回 `author_links.platform_display_name`；解析失败保留上一次成功值。
- 平台图片与 #204 的 Comic 高清封面共用 `ImageCache`、512MB 上限、LRU 和原子写入。
- 平台缓存按 `author_link_id + slot` 分区；底层可对相同图片 URL 去重，但 avatar/background 的领域状态保持独立。
- SQLite 保存平台缓存元数据：Author link、slot、资料页 URL、图片 URL、checked_at、fetched_at 和缓存文件 key；图片二进制不写入 SQLite。
- 平台缓存有效期为 7 天。过期刷新失败时保留旧平台图；link URL 变化或 link 删除时使对应缓存失效。
- Author rename 不使平台缓存失效。

### Refresh and concurrency

- 新增或修改 Creative platform link 后后台触发一次解析。
- 打开 Author detail 时只刷新超过 7 天的来源；应用启动和回到前台不做全量刷新。
- 同一 `author_id + link_id` 的资料解析 single-flight；图片下载按 slot 独立去重。
- 后台任务提交结果前重新校验 `link_id + URL + version`；旧 URL、已删除 link 或旧版本任务不得回写。
- 只有确认图片 URL 发生变化后才进入 slot loading；成功后原子替换并淡入。
- 解析或下载失败对用户静默，只记录脱敏日志并继续使用旧平台图或 Comic 封面。

### Domain and Flutter boundary

- `AuthorImageRef` 增加 `avatar_link_id` 与 `background_link_id`，与现有 source 和 Comic id 一起跨 FRB 返回。
- `AuthorImageRef` 另外携带 `avatar_image_url` 与 `background_image_url`（平台缓存当前图片 URL），用于让前端只在平台图片确实变化时重取并淡入。
- 保留 `resolve_author_image_frb` 和 `load_author_image_frb`；首版不新增用户可见的手动刷新 API。
- Author alias 在 Dart domain 纯逻辑中计算：比较和去重均大小写敏感，按 Creative platform 优先级排序，以英文逗号拼接。
- Rust 通过现有 revision/watch 机制通知数据变化，不新增专用平台事件流。
- Flutter 只负责 ViewModel 编排、状态消费和 UI 渲染，不维护平台协议栈。

## Consequences

### Positive

- 五个平台拥有统一、可替换、可 fixture 测试的解析边界。
- 不把 OAuth、代理或平台账号体系引入个人本地库产品。
- 公开资料不可用时有明确的 Comic cover fallback，不破坏现有 Author image 体验。
- 平台图片与 #204 共用缓存、容量上限和淘汰策略。
- Author rename 不影响外链、alias 或图片缓存。

### Negative

- 五个平台的公开资料 URL 规则需要持续维护，平台页面变化可能导致单个平台暂时回退。
- 不使用 OAuth 或平台 token 意味着无法保证所有平台链接都能解析。
- 需要新增缓存元数据迁移、统一 downloader、五个平台 fixture 和并发测试。
- 平台源失败对用户静默，诊断依赖脱敏日志。

## 修订（2026-10-07）

### Discord 不抓取，只校验链接

Discord 没有可用于解析 Author 形象的公开用户资料 API：唯一无需 OAuth/token 的公开资源是邀请 API，而它返回的是服务器（guild）而非作者用户，语义不符。因此 Discord 适配器**不做任何网络请求**：

- 只校验链接是否为合法的公开 Discord 链接形状（`discord.gg/{code}`、`discord.com/invite/{code}`、`discord.com/users/{id}`），形状不合法时记脱敏 debug 日志。
- 不产生 `platform_display_name`，不产生 avatar/background，因此 Discord slot 始终回退 Comic 封面。
- Discord link 仍算 Creative platform（参与 Verified author 与 alias 的链接判定），只是不提供形象。

这取代本文档上文「五个平台首版均提供真实平台适配器」中关于 Discord 的表述。

### Patreon 只接受 Creator 资料 URL

Patreon 适配器仅接受 Creator 资料页形状：`/c/{vanity}`、`/user?u={id}` 或历史 `/{vanity}`。`/posts/{id}` 等非资料页判定为 Unsupported，保留原 link，不写入显示名或图片缓存。

### AuthorImageRef 携带平台图片 URL

`AuthorImageRef` 增加 `avatar_image_url` 与 `background_image_url`。前端以该 URL 作为「平台图片是否变化」的信号：link 未变但平台换了图时，URL 变化会触发重取并淡入替换；仅凭 `link_id` 无法感知这种变化。

## References

- Issue #202 — Author 平台形象解析（方案 B）
- Issue #204 — Author image 高清显示与统一取图接口
- ADR-0002 — Rust 核心层经 FRB 接管数据与 I/O
- ADR-0024 — Author 稳定身份与创作平台外链
- `CONTEXT.md` — Author image / Author alias / Creative platform / Author link
