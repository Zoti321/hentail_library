# Hentai Library

本地漫画（本子）个人库：从指定文件夹扫描资源、管理元数据、按系列组织，并在桌面端离线阅读。

## Language

### Library & resources

**Library**:
用户在本机维护的全部漫画集合，由扫描导入的 Comic 与手动创建的 Series 组成。
_Avoid_: 书架（UI 语境可用，领域模型中用 Library）

**Comic**:
库中一条可阅读的独立作品，对应磁盘上的一个资源文件或图片目录。身份由规范化后的磁盘路径派生（`comicId`）；同一路径始终是同一 Comic。
_Avoid_: 本子、作品、条目（口语可用，文档与 issue 中用 Comic）

**Comic identity**:
Comic 与磁盘位置绑定，而非内容哈希。移动或重命名资源文件会改变路径，从而生成新的 `comicId`；下次 Scan 时旧 Comic 及其用户元数据、阅读历史、Series 归属会被清除，不会自动迁移到新路径。
_Avoid_: 内容 ID、文件指纹

**Resource**:
磁盘上的原始文件或目录，扫描后若校验通过则入库为 Comic。
_Avoid_: 文件、素材

**Saved path**:
用户登记在库中的根目录路径；扫描时从这些路径向下发现 Resource。
_Avoid_: 扫描路径、文件夹、目录（UI 可用，领域术语用 Saved path）

**Scan**:
遍历 Saved path、发现 Resource 并解析元数据的过程；用户与 UI 中常用的说法（如「扫描库」）。
_Avoid_: 导入、索引（未体现与磁盘对齐的删除语义）

**Library sync**:
让 Library 与当前 Saved path 下磁盘内容对齐的完整操作：包含 Scan，并将结果写入数据库——新增缺失 Comic、更新仍存在的 Comic（保留用户元数据）、删除磁盘上已消失的 Comic。若所有 Saved path 被移除，则清空整个 Library。
_Avoid_: 同步、刷新（太泛，未体现镜像语义）

_Scan_ 与 _Library sync_ 在用户触发的场景中指同一操作；领域文档与 issue 优先使用 Library sync。

### Organization & metadata

**Series**:
库中有名、有顺序的 Comic 集合；可手动创建，也可由 Series inference 批量生成或并入同名 Series，入库后均为同一实体。顺序由 SeriesItem 的 order 决定，与 Comic 本身解耦。任一时刻一本 Comic 最多属于一个 Series；不在任何 Series 中的 Comic 仍作为独立条目存在于 Library 中。
_Avoid_: 合集、专辑、套系

**Series inference**:
根据 Comic 标题规则猜测系列名与卷序，将尚未归属任何 Series 的 Comic 编入 Series 的操作；若同名 Series 已存在则追加卷。
_Avoid_: 自动分组、智能归类

**Tag**:
用户为 Comic 附加的自由文本标签，用于筛选与归类。
_Avoid_: 分类、关键词

**Author**:
Comic 的署名，用于展示与筛选；社团、画师、原作者等展示用名字均记为 Author，不区分类型。
_Avoid_: 画师、创作者、社团、Circle（领域模型中统一用 Author）

**Content rating**:
Comic 的内容分级：`unknown`、`safe`、`r18`；主要由用户设定，也可通过路径关键词自动检测为 `r18`。
_Avoid_: 分级、年龄限制

**Healthy mode**:
应用级浏览过滤：开启后库、搜索、历史等视图隐藏 `contentRating == r18` 的 Comic；不修改 Comic 自身的分级。
_Avoid_: 安全模式、青少年模式、R18 过滤

**Metadata export**:
将 Author 名录、Tag 名录与 Series 结构（卷序以 Comic 标题标识）序列化为 JSON；不包含 Comic 本体、Saved path、阅读历史、Content rating，也不包含 Comic 与 Author/Tag 的关联。
_Avoid_: 库备份、完整导出

**Metadata import**:
从 JSON 合并 Author 名录、Tag 名录与 Series 结构；Series 卷册通过 Comic 标题匹配库中已有 Comic。标题重名时匹配不可靠，以库中先出现的 Comic 为准；不匹配或已占用归属的卷册项跳过。
_Avoid_: 库恢复、完整导入

### Reading

**Standalone read**:
在系列上下文之外打开单本 Comic 的阅读会话；进度写入 Reading history。
_Avoid_: Comic read（易与 Comic 实体混淆）、单本模式

**Series read**:
在某一 Series 内打开 Comic 的阅读会话；可在系列内切换卷册，进度写入 Series reading history。
_Avoid_: 连读、系列模式

**Reading history**:
用户对某 Comic 在 Standalone read 下最近一次阅读的时间与页码记录。
_Avoid_: 阅读记录、进度（系列级进度见 Series reading history）

**Series reading history**:
用户在 Series read 下于某个 Series 内的阅读进度（最后读到的 Comic 与页码）。
_Avoid_: 系列进度

**Scroll layout**:
阅读器纵向连续滚动的版式；适用于长条阅读体验。
_Avoid_: Webtoon 模式（易与作品类型混淆）、卷轴模式

**Paged layout**:
阅读器分页翻页的版式；逐页切换而非连续滚动。
_Avoid_: 翻页模式、单页模式
