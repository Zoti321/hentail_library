# Page Override: Home

**Route:** `/home` · **Widget:** `HomePage`  
**Overrides:** `MASTER.md`  
**ADR:** [0020-home-page-multi-library-entry](../../docs/adr/0020-home-page-multi-library-entry.md)

---

## Purpose

**Global reader entry + multi-library situational summary.** First screen after launch.

Not a Current library dashboard. Not a scan control panel.

| In scope on Home | Lives elsewhere |
|------------------|-----------------|
| Continue reading (global Top N) | Full Reading history → `/history` |
| Recently added on Home (cross-library) | Catalog browse/filter → Library page |
| Home library alert (sync/health prompts) | Library sync overflow → sidebar Library row |
| All-libraries aggregate stats (optional) | Metadata management → `/metadata` |
| Empty onboarding (add Library) | Library form, settings |

## Layout

| Tier | Width | Behavior |
|------|-------|----------|
| Compact | `<600` | Single column; menu ghost button in header |
| Medium | `600–1023` | Wider inner max-width; pinned header |
| Expanded | `≥1024` | Full sidebar + centered content column |

- Use `PageContentWidthAlign` + `homeContentHorizontalPadding` / `homeInnerContentMaxWidth` — do not invent widths.
- **Pinned header:** measure via `_headerMeasureKey` → `HomePinnedHeaderDelegate`; preserve this pattern when editing header.
- Background: `cs.hentai.winBackground`.
- **Section order (top → bottom):** pinned header → time greeting (body) → **Home library alert stack** (if any) → continue reading → recently added → aggregate stats (or empty onboarding hero when no Library / zero Comics globally).
- Content sections below header use **`deferredSectionsReady`** post-frame — avoid blocking first paint.

## Components

### Header (`HomePageHeaderSection`)

- **Title**「首页」+ compact **drawer opener** only.
- **No** scan button, **no** Current library chip, **no** global search in v1.

### Home library alert stack

- One card/banner per alert; stack vertically with `tokens.spacing.md` gap.
- Severity via semantic tokens: `colorScheme.hentai.warning` / `error` border or icon tint — not color-only (include icon + text).
- **Primary action:** per-library「扫描此库」→ `LibraryManagementActions.scanLibrary(libraryId)` → `ScanProgressDialog`.
- **Secondary:**「稍后」dismisses until next app session or until sync outcome changes (persist dismiss key per alert kind + libraryId in App preference or equivalent).
- **Read-only row** when shell silent sync running: reuse `LibraryScanShellFeedback` strip — do not duplicate progress UI on Home body.

Alert kinds (v1):

| Kind | Trigger (conceptual) | Copy tone |
|------|----------------------|-----------|
| Remote unreachable | Last sync failed with connectivity/auth | 无法连接 · 建议检查网络或凭证 |
| Sync failed | Last sync error (non-reachability) | 同步失败 · 查看并重试 |
| Stale sync | Success timestamp older than Library `Scan interval` implied window | 距上次同步已 N 天 · 建议同步 |
| Pending resources | Library resource probe: added + changed count > 0 (ADR-0021) | 发现 N 个新/变更 Resource · 建议同步 |

Use exact counts from probe when ADR-0021 shipped; until then stale-sync copy only.

### Continue reading

- Horizontal strip; existing `ReadingHistoryCard` + `HorizontalWheelScrollListener`.
- Section title + **「查看全部 →」** link to `/history`.
- Global Reading history; respect Healthy mode when enabled.

### Recently added on Home

- Horizontal strip; cover + title + **Library display name** (secondary, `textSecondary`).
- Top **8** items, cross-library, ordered by Comic record `created_at` desc.
- Tap → Comic detail or Read session (match continue-reading behavior).

### Aggregate stats (non-empty library)

- **All-libraries** comic count, series count, tag count, author count.
- **Tag / Author cards:** navigate to `/metadata` (correct tab).
- **Comic / Series cards:** display-only in v1 (All libraries browse is placeholder — no dead-end navigation).

### Empty onboarding (`_EmptyLibraryHero` revision)

- Trigger: **zero Libraries** OR **zero Comics globally**.
- Primary: add Local library · Secondary: add Remote library.
- Hint: 建库后可在侧栏对该 Library 执行 Library sync.
- **No** scan CTA on hero.

## Interactions

- Per-library scan from alert only — never a header/global scan.
- Transitions: shell nav page (no fade-through).
- Hover on stat cards: existing lift animation; cursor click only where navigation exists.

## Motion & density

- Match MASTER: `easeOutCubic`, **180–220 ms** hover/lift on cards.
- Alert enter: fade + slight Y (≤8px), **200 ms**; honor reduced motion → instant show.
- Horizontal strips: wheel scroll on desktop; touch drag on mobile — no autoplay carousel.

## Anti-Patterns (This Page)

- ❌ Blocking entire page on section providers before showing header
- ❌ Material `FloatingActionButton` for scan
- ❌ Removing pinned header without replacing scroll-offset behavior
- ❌ Current library name/count in header or hero
- ❌ Global「扫描漫画库」button in header (supersedes pre-ADR-0020 home.md)
- ❌ Claiming file-level detection without backend support
- ❌ Duplicating full History grid or Library catalog on Home

## Accessibility

- Alert actions: visible label + icon; dismiss control has semantic「稍后」.
- Horizontal strips: keyboard-scrollable region or focusable items in tab order.
- Decorative section icons: exclude from semantics when title text present.

## Page Checklist

- [ ] Header pins correctly after measure; **no** scan button
- [ ] Empty onboarding when no Library or zero global Comics; **no** scan on hero
- [ ] Home library alert scan opens progress dialog for **that** libraryId
- [ ] Continue reading links to `/history`
- [ ] Recently added shows Library display name
- [ ] Compact shows drawer opener; expanded does not duplicate nav
- [ ] Stats are all-libraries scoped; Tag/Author navigate to metadata
