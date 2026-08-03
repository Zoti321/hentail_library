# Hentai Library

本地漫画（本子）个人库：从指定文件夹扫描资源、管理元数据、按系列组织，并在桌面端离线阅读。

## Language

### Library & resources

**Library**:
用户在本机维护的全部漫画集合，由 Library sync 导入的 Comic 与按 Folder series 自动生成的 Series 组成。
_Avoid_: 书架（UI 语境可用，领域模型中用 Library）

**Comic**:
库中一条可阅读的独立作品，对应磁盘上的一个资源文件或图片目录。身份由规范化后的磁盘路径派生（`comicId`）；同一路径始终是同一 Comic。
_Avoid_: 本子、作品、条目（口语可用，文档与 issue 中用 Comic）

**Comic identity**:
Comic 与磁盘位置绑定，而非内容哈希。移动或重命名资源文件会改变路径，从而生成新的 `comicId`；下次 Scan 时旧 Comic 及其用户元数据、阅读历史、Series 归属会被清除，不会自动迁移到新路径。
_Avoid_: 内容 ID、文件指纹

**Resource**:
磁盘上的原始文件或目录，扫描后若校验通过则入库为 Comic。解析得到的中间结果（路径、格式、页数、嵌入元数据等）在入库为 Comic 之前独立于 Comic 身份与用户元数据；Library sync / Metadata refresh / 阅读与缩略图共用同一套 Resource 解析规则。
_Avoid_: 文件、素材

**Saved path**:
用户登记在库中的根目录路径；扫描时从这些路径向下发现 Resource。
_Avoid_: 扫描路径、文件夹、目录（UI 可用，领域术语用 Saved path）

**Scan**:
遍历 Saved path、发现 Resource 并解析元数据的过程；用户与 UI 中常用的说法（如「扫描库」）。
_Avoid_: 导入、索引（未体现与磁盘对齐的删除语义）

**Library sync**:
让 Library 与当前 Saved path 下磁盘内容对齐的完整操作：包含 Scan，并将结果写入数据库——新增缺失 Comic、按字段锁合并元数据后更新仍存在的 Comic、删除磁盘上已消失的 Comic。若所有 Saved path 被移除，则清空整个 Library。元数据合并见 Metadata field lock。
_Avoid_: 同步、刷新（太泛，未体现镜像语义）

_Scan_ 与 _Library sync_ 在用户触发的场景中指同一操作；领域文档与 issue 优先使用 Library sync。

**Supported resource formats**:
用户可配置的、Library sync 会收录的 Resource 格式范围；按 Format group 勾选（漫画文件夹 / PDF / EPUB / 漫画压缩包）。偏好存于应用设置，每次 Library sync 传入 core；未启用分组下的 Resource 不进入扫描结果，库中对应 Comic 在该次 sync 按 orphan 删除。默认四组全开；取消勾选仅在下次 sync 生效，此前已入库 Comic 仍可展示与阅读。
_Avoid_: 媒体类型（库页浏览筛选用语）、导入格式

**Format group**:
Supported resource formats 的勾选单位：`folder`（`dir`）、`pdf`、`epub`、`archive`（zip/cbz/rar/cbr/7z/cb7）。分组到 `resource_type` 的展开由 core 维护。
_Avoid_: 扩展名列表（用户设置层用分组）

### Organization & metadata

**Series**:
库中有名、有顺序的 Comic 集合；由 Library sync 根据 Comic 所在文件夹（直接父目录）自动生成与更新。用户可编辑连载状态与计划总卷数（各字段可有 Metadata field lock）；成员默认顺序由 sync 按文件名自然排序写入。用户可在系列详情手动编辑单本排序值（`SeriesItem.order`，浮点数）；手动保存后会锁定该成员（`sortOrderLocked`），后续 sync 保留锁定项的排序值，未锁定项仍按文件名自然排序更新；也可解锁排序以在下次 sync 恢复文件名序。顺序由 SeriesItem 的 order 决定，与 Comic 本身解耦。任一时刻一本 Comic 最多属于一个 Series；不在任何 Series 中的 Comic 仍作为独立条目存在于 Library 中。
_Avoid_: 合集、专辑、套系

**Folder series**:
Comic 的直接父目录对应一个 Series；Saved path 根目录下直接存放的 Comic 也会形成以根文件夹命名的 Series。Series 身份由规范化 `folder_path` 派生（`seriesId`）。
_Avoid_: 标题推断、自动分组

**Tag**:
用户为 Comic 附加的自由文本标签，用于筛选与归类。
_Avoid_: 分类、关键词

**Author**:
Comic 的署名，用于展示与筛选；社团、画师、原作者等展示用名字均记为 Author，不区分类型。
_Avoid_: 画师、创作者、社团、Circle（领域模型中统一用 Author）

**Content rating**:
Comic 的内容分级：`unknown`、`safe`、`r18`；主要由用户设定，也可通过路径关键词自动检测为 `r18`。
_Avoid_: 分级、年龄限制

**Comic metadata form**:
编辑 Comic 用户元数据（标题、概要、发布日期、Content rating、Author、Tag）时的可提交草稿；校验与 normalize、Author/Tag 增减与落库规则集中在此，非法结果以字段级返回由 UI 展示。保存时只提交相对打开时**值变化**的字段，这些字段会自动加上 Metadata field lock；无变化则不写库。表单旁可单独切换锁而不改值。
_Avoid_: 漫画表单、元数据 DTO

**Series metadata form**:
编辑 Series 用户元数据（名称、连载状态、计划总卷数）时的可提交草稿；计划总卷数以原始文本持有，空串表示清除、正整数表示设置；校验失败以字段级结果返回，由 UI 在字段下方展示。保存时只提交相对打开时**值变化**的字段，这些字段会自动加上 Metadata field lock；无变化则不写库。表单旁可单独切换锁而不改值。
_Avoid_: 系列表单、SeriesForm、编辑系列 DTO

**Metadata field lock**:
Comic / Series 元数据字段上的布尔锁（Komga 式）。未锁定且 Library sync 或 Metadata refresh 解析出有值时用扫描结果覆盖；已锁定则保留库内值；扫描空/缺不清除。编辑某字段并保存会自动锁定该字段（仅变更字段）；也可不改值单独上锁/解锁。解锁不自动触发 sync / refresh。Series 成员排序锁（`sortOrderLocked`）同属此策略（见 ADR-0006）。合并与自动上锁规则集中一处，供 Library sync、Metadata refresh 与用户元数据写入共用。详见 ADR-0007。
_Avoid_: 只读标记、冻结、保护位（口语可用，领域用 Metadata field lock）

**Metadata refresh**:
对单个 Comic 或 Series 从磁盘 Resource 重解析元数据并按 Metadata field lock 写回的操作（对齐 Komga「Refresh metadata」）。Comic：重解析该 Resource，更新物理字段，不动缩略图。Series：对每个成员执行 Comic 刷新，并在 `name` 未锁定时用文件夹名覆盖；不改连载状态、计划总卷数、成员排序与缩略图；部分成员失败则跳过并汇总。与 Library sync 全局单飞互斥。不是库页工具栏的「刷新」（后者仅重载 UI catalog），也不是全库 Library sync。
_Avoid_: 刷新、重新扫描、同步（易与 UI catalog refresh / Library sync 混淆）

**Healthy mode**:
应用级浏览过滤：开启后库、搜索、历史等视图隐藏 `contentRating == r18` 的 Comic；不修改 Comic 自身的分级。
_Avoid_: 安全模式、青少年模式、R18 过滤

### Reading

**Read session**:
由 comicId 打开的阅读会话；不区分「单本 / 系列」两种模式。进度只写入 Reading history。入口参数仅为 comicId（及无痕等开关），不传 seriesId。退出阅读器一律回到该 Comic 的详情页。详见 ADR-0005。
_Avoid_: Standalone read、Series read、单本模式、系列模式、Comic read（易与 Comic 实体混淆）

**Series reading context**:
由 comicId 在 core 侧派生的可选系列信息（seriesId、系列名、有序成员 comicId 列表、当前下标）；供阅读器展示位置、上一卷/下一卷与卷列表跳转。不是会话模式，也不持久化进度。无系列归属时为空。卷列表项展示标题由 Flutter 用现有 Comic 标题格式拼出（如 `{序号}-{title}`）。详见 ADR-0005。
_Avoid_: 系列阅读模式、Series read、系列会话

**Reading history**:
用户对某 Comic 最近一次阅读的时间与页码记录。从库/详情/历史等重新打开该 Comic 时恢复页码；阅读器内切到同系列另一卷时，先落盘当前 Comic 进度（无痕除外），目标卷从第 1 页打开。无痕 Read session 不读写 Reading history。
_Avoid_: 阅读记录、系列进度、Series reading history

**Scroll layout**:
阅读器纵向连续滚动的版式；适用于长条阅读体验。
_Avoid_: Webtoon 模式（易与作品类型混淆）、卷轴模式

**Paged layout**:
阅读器分页翻页的版式；逐页切换而非连续滚动。
_Avoid_: 翻页模式、单页模式
