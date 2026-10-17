#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

git -c http.version=HTTP/1.1 push origin dev

BASELINE_COUNT="$(python -c "import json; print(len(json.load(open('app/test/gate/import_boundary_baseline.json'))))")"
HEAD_SHA="$(git rev-parse --short HEAD)"

comment_and_close() {
  local num="$1"
  local body="$2"
  gh issue close "$num" --comment "$body"
}

comment_and_close 271 "$(cat <<EOF
## 交付（\`$HEAD_SHA\`）

- library_browse 去除对 \`features/bootstrap\` 的 M3 边。
- 导入边界基线：62 → 38（本票约 -27 条 M3）。
- 全量 \`flutter test\` 941 绿。
EOF
)"

comment_and_close 272 "$(cat <<EOF
## 交付（\`$HEAD_SHA\`）

- home 去除对 bootstrap 的 M3 边；阅读器入口经 \`readSessionLaunchPortProvider\`。
- 导入边界基线：38 → 22。
EOF
)"

comment_and_close 273 "$(cat <<EOF
## 交付（\`$HEAD_SHA\`）

- read_session 去除对 bootstrap 的 M3 边；会话 Provider 迁至 \`read_session/di/session_providers.dart\`。
- 漫画显示标题解析下沉 \`shared/domain/comic/comic_display_title.dart\`。
- 导入边界基线：22 → 13。
EOF
)"

comment_and_close 274 "$(cat <<EOF
## 交付（\`$HEAD_SHA\`）

- library_admin 去除对 bootstrap 的 M3 边。
- 进入库排序时由 \`libraryReorderActiveStateProvider\` 驱动多选退出，去掉对 catalog 的跨 feature 调用。
- 导入边界基线：13 → 11。
EOF
)"

comment_and_close 275 "$(cat <<EOF
## 交付（\`$HEAD_SHA\`）

- named_metadata 去除对 bootstrap 的 M3 边；标签字典下载 Provider 迁至本 feature \`di/\`。
- 导入边界基线：11 → 5。
EOF
)"

comment_and_close 276 "$(cat <<EOF
## 交付（\`$HEAD_SHA\`）

- app_settings 去除对 bootstrap 的 M3 边；\`appUpdateServiceProvider\` 迁至 \`app_settings/di\`。
- \`bootstrap/di/services.dart\` 改为纯导出桶。
- 导入边界基线：5 → 1。
EOF
)"

comment_and_close 277 "$(cat <<EOF
## 交付（\`$HEAD_SHA\`）

- comic_trash 回收站页改用 \`shared/ui/layout/app_shell_navigation.dart\`。
- **M3 导入边界基线清零**（\`import_boundary_baseline.json\` 共 $BASELINE_COUNT 条）。
EOF
)"

if gh issue view 278 --json state --jq .state 2>/dev/null | grep -q OPEN; then
  comment_and_close 278 "$(cat <<EOF
## 交付（\`$HEAD_SHA\`）

- 仓储与端口 Provider 声明下沉 \`shared/di/data_providers.dart\`；\`dataProviderOverrides()\` 在 bootstrap 注入。
- 为 #271–#277 M3 迁移提供基础设施（已合入 \`dev\`）。
EOF
)"
fi

gh issue comment 260 --body "$(cat <<EOF
## M3 ratchet 基线已清零（\`$HEAD_SHA\`）

- \`app/test/gate/import_boundary_baseline.json\`：**$BASELINE_COUNT** 条（M1/M2 与 M3 ratchet 均为空）。
- #271–#277 已全部合入 \`dev\` 并推送。

### 仍待跟进（不阻塞 M3 清零）

- Gate **R1 扩展**（禁止 feature \`domain/\` → 本 feature \`data/\`）尚未实现；\`metadata_auto_backup_logic.dart\` 等见原 spec。
- Issue 正文中的「R6 零容忍」应改为 **M3 ratchet** 表述（与 Gate 一致）。

M1/M2 feature↔feature 与 M3 product→bootstrap ratchet 的 DoD 已达成；R1 扩展建议单独开票或在本 issue 续做。
EOF
)"

gh issue comment 217 --body "$(cat <<EOF
## 路线图节点：导入边界 ratchet 基线为空（\`$HEAD_SHA\`）

Wayfinder 消费方票 #271–#277 已完成；M3 基线条目 **$BASELINE_COUNT**。

关联 epic #260 见最新留言。R1 扩展与 \`deps.dart\` 总桶瘦身可作为后续工作，不计入当前 ratchet 基线。
EOF
)"

if [[ "$BASELINE_COUNT" == "0" ]]; then
  gh issue close 217 --comment "DoD「ratchet 基线为空」已达成（\`$HEAD_SHA\`）。R1 扩展等见 #260 留言。"
fi

echo "Done. Pushed dev; issues updated. #260 left open until R1/body sync if you prefer."
