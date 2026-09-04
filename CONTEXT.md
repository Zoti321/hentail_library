# Hentai Library

个人漫画库：用户可维护一个或多个 Library（本地磁盘根或 WebDAV 远程根），扫描 Resource、管理元数据、按系列组织，并阅读（本地可离线；远程为在线流式）。

## Language

### Application data

**App data profile**:
与应用身份绑定的一整份本机应用数据树（含库文件、本地设置、日志与缓存等）。日常发布使用 `default`；非正式构建（Debug / Profile）使用独立的 `dev`，二者互不共享。与 Library（同一库文件内的多根集合）无关。详见 ADR-0010。
_Avoid_: 开发库、发布库、数据库环境（易与 Library 混淆）

### Library & resources

**Library**:
用户的一份漫画集合（趋近 Komga：一个 Library root 对应一个 Library），由该根下 Library sync 导入的 Comic 与 Folder series 组成；可有独立配置（Supported resource formats、Scan on startup、Scan interval），以及可独立于 Library root 编辑的显示名。应用内可同时存在多个 Library。
_Avoid_: 书架（UI 可用）；把「全部库合并」称作一个 Library

**Current library**:
用户当前选中的 Library；浏览与搜索默认作用于此。Reading history 跨 Library 全局可见。
_Avoid_: 活动库、选中书架

**All libraries browse**:
跨多个 Library 的聚合浏览面（趋近 Komga「全部库」）；不是一个 Library。路由占位为 `/libraries/all`；本阶段仅占位提示，不实现聚合目录。
_Avoid_: 全部库（若被理解成一个 Library）、合并库、全局书架

**Local library**:
Library root 为本机目录的 Library；Resource 来自本地文件系统；入库后可离线阅读。
_Avoid_: 本地书架、磁盘库（口语可用，文档用 Local library）

**Remote library**:
Library root 为 WebDAV 根的 Library；Resource 经 WebDAV 发现与流式读取；不整本落盘。
_Avoid_: 云库、网盘库、在线书架（无官方云账号语义）

**Library root**:
一个 Library 的唯一根位置：Local（本机目录）或 Remote（WebDAV 根 URL）。扫描与对齐均相对该根。
_Avoid_: 扫描路径、挂载点；Saved path（旧称，仅指 Local 根）

**Saved path**:
Local library 的 Library root 之旧称；兼容文档与实现中仍可能出现，新表述优先用 Library root / Local library。
_Avoid_: 在新设计中把 Saved path 扩成远程 URI

**Comic**:
某个 Library 中一条可阅读的独立作品，对应一个 Resource（本地文件/目录，或远程 WebDAV 上的文件）。身份由规范化后的资源位置键派生（`comicId`）；同一位置键始终是同一 Comic。
_Avoid_: 本子、作品、条目（口语可用，文档与 issue 中用 Comic）

**Comic identity**:
Comic 与资源位置键绑定，而非内容哈希。本地为规范化磁盘路径；远程为规范化 WebDAV 资源 URL。位置变化（移动/重命名/改 URL）生成新 `comicId`；Library sync 时旧记录及其用户元数据、阅读历史、Series 归属按该库对齐规则处理，不会仅凭内容自动迁移。详见 ADR-0001。
_Avoid_: 内容 ID、文件指纹

**Resource**:
可被发现并（校验后）入库为 Comic 的原始载体：本地文件/目录，或 WebDAV 上的文件。解析中间结果在入库前独立于 Comic 身份与用户元数据；Library sync / Metadata refresh / 阅读与缩略图共用同一套 Resource 访问与解析规则（经 Resource access）。
_Avoid_: 文件、素材

**Resource access**:
对 Library root 下资源的统一访问能力（列举、属性、打开只读流）；Local 走文件系统，Remote 走 WebDAV。Scan、阅读与缩略图生成均经此端口，不在 UI 层分叉协议。
_Avoid_: VFS、存储驱动、网盘 SDK

**Scan**:
遍历当前（或指定）Library 的 Library root、发现 Resource 并做轻量登记或解析的过程；用户与 UI 中常用的说法（如「扫描库」）。
_Avoid_: 导入、索引（未体现与根对齐的删除语义）

**Library sync**:
让某个 Library 与其 Library root 下内容对齐的完整操作：包含 Scan，并写库——新增缺失 Comic、按字段锁合并后更新仍存在的 Comic、删除根上已消失的 Comic。默认只 sync Current library（可配置为全部 Library）。Remote library 在根不可达（网络/鉴权失败）时跳过该库且不删除其已有 Comic。若某 Library 被移除，则清除该库及其 Comic/Series。元数据合并见 Metadata field lock。写库后由 core 使相关阅读会话失效；与 Metadata refresh 共用库级写锁。
_Avoid_: 同步、刷新（太泛，未体现镜像语义）

_Scan_ 与 _Library sync_ 在用户触发的场景中指同一操作；领域文档与 issue 优先使用 Library sync。

**Supported resource formats**:
按 Library 配置的、Library sync 会收录的 Resource 格式范围；按 Format group 勾选。未启用分组下的 Resource 不进入该次扫描结果，库中对应 Comic 按 orphan 删除。默认值与 Local / Remote 首版能力见产品定位；取消勾选仅在下次 sync 生效。
_Avoid_: 媒体类型（库页浏览筛选用语）、导入格式、全局唯一一份格式设置（已改为每库）

**Format group**:
Supported resource formats 的勾选单位：`folder`（`dir`）、`pdf`、`epub`、`archive`（zip/cbz/rar/cbr/7z/cb7）。分组到 `resource_type` 的展开由 core 维护。Remote library 首版不收录 `folder`。
_Avoid_: 扩展名列表（用户设置层用分组）

**Scan on startup**:
某 Library 的布尔配置：应用启动后是否对该库自动执行一次 incremental Library sync。按库独立；与 Scan interval 无关。
_Avoid_: 自动扫描（易与全局旧设置或间隔扫混淆）、autoScan（已移除的应用级设置）

**Scan interval**:
某 Library 的周期自动 Library sync 档位：`disabled`、`hourly`、`every_6_hours`、`every_12_hours`、`daily`、`weekly`。按库独立计时；锚点为应用本次启动或该库本档被改为非 `disabled` 之时；到期对该库做 incremental Library sync。应用未运行时不调度。
_Avoid_: 自动扫描间隔（口语可用）、cron、全局扫描周期

**Pinned library**:
用户选择在侧栏 Libraries 分区直接列出的 Library；Library 列表的全局顺序中 Pinned 一组排在 Unpinned 之前。新建 Library 默认为 Pinned，并排在已固定组末尾。详见 ADR-0009。
_Avoid_: 置顶库、收藏库、固定库（易与 sticky header 的 pinned 混淆）；文档用 Pinned library，UI 文案可用「已固定」

**Unpinned library**:
用户选择不在侧栏直接列出的 Library；平时藏在「更多」展开后渲染，未固定组为空时不显示「更多」。排序模式里出现在「未固定」段。
_Avoid_: 隐藏库、折叠库、次要库

**Library sidebar order**:
Pinned 组内与 Unpinned 组内各自的用户顺序；与 Series 成员的 `order` / `sortOrderLocked` 无关。`list_libraries` 按「Pinned 再 Unpinned、组内按该顺序」返回。
_Avoid_: 库排序（太泛）、sortOrder（Series 用语）

**Library reorder mode**:
侧栏的短暂状态：整栏换成「重新排序」顶栏与已固定/未固定两段，靠跨段拖拽同时改 Pinned/Unpinned 与 Library sidebar order；退出后恢复普通侧栏。不是 Library 上的持久字段。
_Avoid_: 编辑模式、排序页、固定开关（pin 只能在此模式用拖拽改，没有单独菜单项）

### Organization & metadata

**Series**:
同一 Library 内有名、有顺序的 Comic 集合；由 Library sync 根据 Comic 所在文件夹（直接父目录）自动生成与更新。不跨 Library。用户可编辑连载状态与计划总卷数（各字段可有 Metadata field lock）；成员默认顺序由 sync 按文件名自然排序写入。用户可在系列详情手动编辑单本排序值（`SeriesItem.order`，浮点数）；手动保存后会锁定该成员（`sortOrderLocked`），后续 sync 保留锁定项的排序值，未锁定项仍按文件名自然排序更新；也可解锁排序以在下次 sync 恢复文件名序。顺序由 SeriesItem 的 order 决定，与 Comic 本身解耦。任一时刻一本 Comic 最多属于一个 Series；不在任何 Series 中的 Comic 仍作为独立条目存在于其 Library 中。
_Avoid_: 合集、专辑、套系

**Folder series**:
Comic 的直接父目录对应一个 Series；Library root 下直接存放的 Comic 也会形成以根名命名的 Series。Series 身份由规范化 `folder_path`（含远程位置键时的父路径）派生（`seriesId`），且隶属于所属 Library。
_Avoid_: 标题推断、自动分组

**Tag**:
全局标签字典中的名称，用于筛选与归类；可来自用户创建或外部词库导入，再附着到 Comic。
_Avoid_: 分类、关键词、Eh 标签（口语可用；领域与 issue 用 Tag）

**Tag dictionary import**:
从外部 JSON 标签字典（经网络下载或本地字节）将标签名幂等写入全局 Tag 字典的操作；不附着到 Comic，不删除本机已有 Tag。JSON 格式见 `docs/agents/tag-dictionary-import.md`。UI 入口待接入自维护词库后启用。
_Avoid_: ehentai 导入、EhTagTranslation、标签同步、画廊导入（易被理解成给 Comic 打标或镜像删除）

**Author**:
Comic 的署名，用于展示与筛选；社团、画师、原作者等展示用名字均记为 Author，不区分类型。
_Avoid_: 画师、创作者、社团、Circle（领域模型中统一用 Author）

**Parody**:
Comic 所同人化的原作 / IP 名（可多值）；无所属 IP 时可用字面值如「原创」。与 Folder series（本库 Series）无关。
_Avoid_: Series、IP 系列、原作系列（易与 Folder series 混淆）；work（`djm` 旧 Kind 名）

**Character**:
Comic 中出场人物名（可多值）；用于展示与筛选，与 Tag / Author 分列。
_Avoid_: 角色标签（并入 Tag）、actor（`djm` 旧 Kind 名）

**Named metadata facet**:
Comic 上以「名称字符串」附着的元数据面：Tag、Author、Parody、Character 为字典表 + junction 全量 replace（core `named_facet`）；Language 为 `comic_meta.languages` JSON 闭集特例，不走 junction。新增同类 junction facet 应扩展 `JunctionNamedFacet`，而非再复制一套 replace/list/list_distinct 管道。
_Avoid_: 元数据字段（太泛）、标签族（易漏 Author / Language）

**Comic catalog query**:
库页 / 搜索共用的 Comic 目录查询：Dart 只组装筛选 intent（`LibraryComicFilter` / metadata expression）；谓词 SQL 集中在 core `comic/filter_predicate`（catalog 分桶与跨 facet 表达式共用 typed facet helpers）。
_Avoid_: 内存 matches、在 Flutter 再写一份 WHERE

**Language**（Comic language）:
Comic 文本所用语言的规范英文名有序列表（闭集首批：`Chinese`、`Japanese`、`English`、`Korean`、`Spanish`、`Other`）；空列表表示未知/未设。展示时按**界面语言**译为本地文案（如中文界面下 `Chinese`→「中文」、`Japanese`→「日语」），多项以 `|` 拼接；未在展示表中的值原样显示。与应用「界面语言」设置不是同一概念。
_Avoid_: 界面语言、locale、译文语言；把 Language 做成自由 Tag

**Content rating**:
Comic 的内容分级：`unknown`、`safe`、`r18`；主要由用户设定，也可通过路径关键词自动检测为 `r18`。
_Avoid_: 分级、年龄限制

**Comic metadata form**:
编辑 Comic 用户元数据（标题、概要、发布日期、Content rating、Author、Tag、Parody、Character、Language）时的可提交草稿；校验与 normalize、多值名增减与落库规则集中在此，非法结果以字段级返回由 UI 展示。保存时只提交相对打开时**值变化**的字段，这些字段会自动加上 Metadata field lock；无变化则不写库。表单旁可单独切换锁而不改值。
_Avoid_: 漫画表单、元数据 DTO

**Series metadata form**:
编辑 Series 用户元数据（名称、连载状态、计划总卷数）时的可提交草稿；计划总卷数以原始文本持有，空串表示清除、正整数表示设置；校验失败以字段级结果返回，由 UI 在字段下方展示。保存时只提交相对打开时**值变化**的字段，这些字段会自动加上 Metadata field lock；无变化则不写库。表单旁可单独切换锁而不改值。
_Avoid_: 系列表单、SeriesForm、编辑系列 DTO

**Library form**:
创建或编辑 Library 时的可提交草稿：显示名（必填）、Library root（Local 目录或 Remote WebDAV URL）、Remote 凭证（用户名/密码/allow HTTP；编辑时密码空表示保留）、Scan on startup、Scan interval、Supported resource formats。校验与落库规则集中在此；非法结果以字段级返回由 UI 展示。Local root 之间禁止相等或互相嵌套（对齐 Komga）。改 root 时保留 `libraryId`，下次 Library sync 按新根对齐（旧路径 Comic 可能 orphan 删除）。无变化则不写库。
_Avoid_: 库表单、LibraryForm DTO、Library settings form（旧称）、编辑库元数据

**Metadata field lock**:
Comic / Series 元数据字段上的布尔锁（Komga 式）。未锁定且 Library sync 或 Metadata refresh 解析出有值时用扫描结果覆盖；已锁定则保留库内值；扫描空/缺不清除。编辑某字段并保存会自动锁定该字段（仅变更字段）；也可不改值单独上锁/解锁。解锁不自动触发 sync / refresh。Series 成员排序锁（`sortOrderLocked`）同属此策略（见 ADR-0006）。合并与自动上锁规则集中一处，供 Library sync、Metadata refresh 与用户元数据写入共用。详见 ADR-0007。
_Avoid_: 只读标记、冻结、保护位（口语可用，领域用 Metadata field lock）

**Metadata refresh**:
从 Resource 重解析元数据并按 Metadata field lock 写回的操作（对齐 Komga「Refresh metadata」），作用对象可为单个 Comic、单个 Series，或指定 Library（侧栏该库的 `libraryId`，可非 Current library，且不切换 Current）。Comic：经 Resource access 重解析，更新物理字段，不动缩略图。Series：对每个成员执行 Comic 刷新，并在 `name` 未锁定时用文件夹名覆盖；不改连载状态、计划总卷数、成员排序与缩略图。Library：对该库全部 Comic 执行 Comic 刷新，并对该库 Series 在 `name` 未锁定时用文件夹名覆盖（其余 Series 字段规则同 Series 级）。部分成员失败则跳过并汇总；可取消（已写回保留、不回滚）。Remote library 根不可达时跳过该库且不改已有数据。与 Library sync 共用 core 库级写锁（全局单飞，占用则立即失败不排队）；互斥不在 Flutter 编排层重复实现。UI 不展示实时进度，仅 busy 态与结束汇总。不是库页工具栏的「刷新」（后者仅重载 UI catalog），也不是 Library sync（不 orphan 删除、不重建成员排序、不再生缩略图）。
_Avoid_: 刷新、重新扫描、同步（易与 UI catalog refresh / Library sync 混淆）

**Healthy mode**:
应用级浏览过滤：开启后库、搜索、历史等视图隐藏 `contentRating == r18` 的 Comic；不修改 Comic 自身的分级。
_Avoid_: 安全模式、青少年模式、R18 过滤

### Reading

**Read session**:
由 comicId 打开的阅读会话；不区分「单本 / 系列」两种模式。进度只写入 Reading history。入口参数仅为 comicId（及无痕等开关），不传 seriesId。退出阅读器一律回到该 Comic 的详情页。Local library 可读本地文件；Remote library 经 Resource access 流式读取，不整本缓存到磁盘。详见 ADR-0005。
_Avoid_: Standalone read、Series read、单本模式、系列模式、Comic read（易与 Comic 实体混淆）

**Series reading context**:
由 comicId 在 core 侧派生的可选系列信息（seriesId、系列名、有序成员 comicId 列表、当前下标）；供阅读器展示位置、上一卷/下一卷与卷列表跳转。不是会话模式，也不持久化进度。无系列归属时为空。卷列表项展示标题由 Flutter 用现有 Comic 标题格式拼出（如 `{序号}-{title}`）。详见 ADR-0005。
_Avoid_: 系列阅读模式、Series read、系列会话

**Reading history**:
用户对某 Comic 最近一次阅读的时间与页码记录；跨 Library 全局保留与展示。从库/详情/历史等重新打开该 Comic 时恢复页码；阅读器内切到同系列另一卷时，先落盘当前 Comic 进度（无痕除外），目标卷从第 1 页打开。无痕 Read session 不读写 Reading history。
_Avoid_: 阅读记录、系列进度、Series reading history

**Scroll layout**:
阅读器纵向连续滚动的版式；适用于长条阅读体验。
_Avoid_: Webtoon 模式（易与作品类型混淆）、卷轴模式

**Paged layout**:
阅读器分页翻页的版式；逐页切换而非连续滚动。
_Avoid_: 翻页模式、单页模式
