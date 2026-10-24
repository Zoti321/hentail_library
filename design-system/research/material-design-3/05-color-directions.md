# 粉色品牌方向 A/B/C：Figma 预览与取色记录

> 状态：**已选定 A · 柔和玫瑰**（用户已拍板；B/C 保留为备选皮肤）。本文件记录三种粉色 seed/方案的取色、Figma 落点、对比度数据与查看方式；正式 token 已写入 `design-system/hentai-library/MASTER.md`。
> 上游：`01-foundations.md`（颜色角色）、`04-figma-design-workflow.md`（变量/样式/建库）；索引见 `README.md`。

## 1. Figma 落点

- 文件：`Hentai Library UI  (Material Design) v2`（文件名中 `UI` 与 `(Material` 之间有两个空格）
- 页面：`01 Tokens`（page id `9:9`）
- 预览 frame（顶栏流程图 `粉色方案 A/B/C`，默认从 A 开始）：
  - A · 柔和玫瑰 · Theme Preview — `10:308`，x=40
  - B · 品牌玫红 · Theme Preview — `10:357`，x=470
  - C · 樱花粉 · Theme Preview — `10:404`，x=900
- 每个 frame 390×844，内容为一屏 compact 首页样张（顶栏 / 搜索 / hero / 最近阅读两行 / chips / FAB / 底部导航），仅用于**比较颜色方向**，不是最终首页版式。
- frame 内底部有 `A | B | C` 三段切换器，已接 Prototype `ON_CLICK → NAVIGATE`（Dissolve 0.3s）；A 为 flow 起点。查看：打开文件 → `01 Tokens` → Present → 选 `粉色方案 A/B/C`。

## 2. 为什么是「三个 frame + 原型跳转」

当前文件是 **Starter（免费）计划**：每个 variable collection 只允许 **1 个 mode**。尝试 `addMode` 报：

```
add_variable_mode: the file's Figma plan does not allow another mode on "Color"
(in addMode: Limited to 1 modes only)
```

因此不能做一个 6 mode（A/B/C × Light/Dark）的集合再靠 `SET_VARIABLE_MODE` 实时换色。落地方案是 **每个主题一个 collection**，每个 collection 一个 mode：

| collection | collectionId | modeId | 变量数 |
|---|---|---:|---:|
| Theme/A · Light | `VariableCollectionId:9:21` | `9:0` | 46 |
| Theme/A · Dark | `10:69` | `10:1` | 46 |
| Theme/B · Light | `10:116` | `10:2` | 46 |
| Theme/B · Dark | `10:163` | `10:3` | 46 |
| Theme/C · Light | `10:210` | `10:4` | 46 |
| Theme/C · Dark | `10:257` | `10:5` | 46 |

变量统一命名 `color/<role>`（`color/primary`、`color/onPrimary`、`color/primaryContainer`、`color/surfaceContainerLow` …），46 个角色不含已弃用的 `background/onBackground/surfaceVariant`。三个 frame 的每个可见填充都绑定了对应 collection 的变量，克隆后按角色批量重绑，所以三者是**同一版式、不同皮肤**。

若以后升级到支持多 mode 的套餐，可合并为 `Theme` 集合 + 6 modes，届时用 `SET_VARIABLE_MODE` 做真正的单开关换色；当前 frame 的图层结构可直接复用。

## 3. 三套取色

生成脚本：`.scratch/generate_palette.dart`（`material_color_utilities 0.11.1` 的 `MaterialDynamicColors`），输出 `.scratch/palette.json`（UTF-16LE）。运行：

```
E:\flutter sdk\flutter\bin\cache\dart-sdk\bin\dart.exe \
  --packages='E:\projects\hentai_library\app\.dart_tool\package_config.json' \
  'E:\projects\hentai_library\.scratch\generate_palette.dart'
```

| | A 柔和玫瑰 | B 品牌玫红 | C 樱花粉 |
|---|---|---|---|
| seed | `#E91E63` | `#E91E63` | `#F06C9B` |
| scheme variant | tonalSpot（M3/Flutter 默认） | fidelity | fidelity |
| 观感 | 低饱和豆沙玫瑰，容器粉、主色偏灰 | 深洋红 + 高饱和容器，品牌冲击最强 | 樱桃粉，最接近日常说的「粉色」 |
| 主色 Light | `#8E4957` | `#B80049` | `#A63261` |
| 主容器 Light | `#FFD9DE` | `#E2165F` | `#F06C9B` |
| 主色 Dark | `#FFB2BE` | `#FFB2BE` | `#FFB1C7` |

### 关键角色（Light / Dark）

| role | A-Light | A-Dark | B-Light | B-Dark | C-Light | C-Dark |
|---|---|---|---|---|---|---|
| primary | #8E4957 | #FFB2BE | #B80049 | #FFB2BE | #A63261 | #FFB1C7 |
| onPrimary | #FFFFFF | #561D2A | #FFFFFF | #660025 | #FFFFFF | #650032 |
| primaryContainer | #FFD9DE | #71333F | #E2165F | #FF4E7C | #F06C9B | #F06C9B |
| onPrimaryContainer | #3B0716 | #FFD9DE | #FFFFFF | #000000 | #160007 | #160007 |
| secondary | #75565B | #E5BDC2 | #A73451 | #FFB2BE | #864D5F | #FBB3C7 |
| secondaryContainer | #FFD9DE | #5C3F43 | #FF7794 | #8B1D3C | #FEB5CA | #6B3648 |
| surface | #FFF8F7 | #191112 | #FFF8F7 | #1F0F12 | #FFF8F8 | #1B1113 |
| surfaceContainerLow | #FFF0F1 | #22191A | #FFF0F1 | #28171A | #FFF0F2 | #23191C |
| surfaceContainer | #FBEAEB | #261D1E | #FFE9EA | #2C1B1E | #FEE9ED | #281D20 |
| onSurface | #22191A | #F0DEE0 | #28171A | #FADBDE | #23191C | #F2DEE1 |
| onSurfaceVariant | #524345 | #D6C2C3 | #5B3F43 | #E4BDC2 | #564147 | #DCBFC6 |
| outline | #847375 | #9F8C8E | #8F6F73 | #AB888C | #897177 | #A48A90 |

### 对比度（WCAG，计算值）

| 组合 | A-L | A-D | B-L | B-D | C-L | C-D |
|---|---:|---:|---:|---:|---:|---:|
| primary / onPrimary | 6.48 | 7.70 | 6.70 | 7.77 | 6.46 | 7.73 |
| primaryContainer / onPrimaryContainer | 13.22 | 7.22 | **4.65** | 6.63 | 7.06 | 7.06 |
| surface / onSurface | 16.38 | 14.36 | 16.31 | 14.32 | 16.32 | 14.36 |
| surface / onSurfaceVariant | 8.91 | 10.94 | 8.95 | 10.88 | 8.93 | 10.84 |

B-Light 的容器/前景 4.65 刚过 AA 正文线（4.5），大字号与粗体没问题；A/C 的容器更宽裕。

## 4. 选型结论

选型调研阶段的建议是 C（品牌识别与「粉色」直读性最好），B 作为强调色备选。**用户最终拍板 A · 柔和玫瑰**，理由是长时间阅读更克制、容器粉足够表达品牌。因此：

- **正式 token = A**：`seed #E91E63`，`tonalSpot`（Flutter `ColorScheme.fromSeed` 默认 variant），46 个角色见 `MASTER.md` §2。
- B/C 不删除：变量集合与三个预览 frame 保留在 `01 Tokens`，作为未来活动页/季节皮肤或 A/B 测试的备选；不进入默认组件。
- A 的代价要接受：默认 CTA 的 primary 是偏灰的 `#8E4957`，品牌粉主要出现在 `primaryContainer` 与大面积容器。若以后觉得不够「粉」，改动点只有 seed/variant，全库可重算。
- 对比度：A-Light primary/onPrimary 6.48、primaryContainer/onPrimaryContainer 13.22，均高于 AA；暗色 7.70 / 7.22。

暗色方向已生成并落成 frame：`A · 柔和玫瑰 · Dark Preview`（`13:578`，页面 `01 Tokens`，y=1020），53 个填充 + 2 个描边按角色重绑到 `Theme/A · Dark`；底部 A/B/C 切换器已隐藏（该 frame 不参与原型跳转，其重复 flow 已移除）。

## 5. 字体现状

- 本机已安装 MiSans 的 **Regular / Medium / Semibold / Bold**（per-user 安装，注册表 `HKCU\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Fonts`）。
- Figma 字族名 `MiSans`，style 名为 `Regular` / `Medium` / `Semibold`（**无空格**）/ `Bold`；预览样张已用这四档（标题 Bold、区块题 Semibold、标签 Medium、正文 Regular）。
- 应用侧 `app/pubspec.yaml` 目前仍只打包 `MiSans-Regular.ttf`；多字重资产与 `FontWeight` 映射等设计定稿后再补。

## 6. 进度与下一步

已完成：

1. ~~选定 A/B/C~~ → **A · 柔和玫瑰**。
2. 正式 token 已写入 `design-system/hentai-library/MASTER.md`；Flutter `ColorScheme` 映射等设计稿定稿后再改代码。
3. 30 个 M3 Text Style 已建（页面 `02 Styles`，样张 frame `10:577`，见 `MASTER.md` §3）。

下一步：

4. ~~暗色 frame~~ → `13:578`，与亮色 A `10:308` 并排评审。
5. effect / grid styles（elevation、8pt 基线网格）。
6. 组件集与首批模板（断点 600/840/1200/1600）；本页样张只用于色彩决策，不作为版式交付。
