# Hentai Library

Monorepo: **`app/`** Flutter · **`core/`** Rust (FRB).  
Setup: `./scripts/setup-dev.sh` · PR gate: `./scripts/run-gate.sh` · Human onboarding: `README.md` · Contributor map: `CONTRIBUTING.md`.

**Glossary** — domain terms, terminology, edit ADR → `GLOSSARY.md` + `docs/adr/`.  
**Read session pages** → `GLOSSARY.md` **Page image fidelity** only.

**Product scope** (capabilities, platforms) → `README.md` § 核心功能 / 支持平台.

**Flutter UI — production** (shell, tokens, components) → `app/lib/shared/ui/theme/` + `shared/ui/widgets/`; structure ADR-0027, theme ADR-0028. Do not treat Figma or `design-system/` as the live spec for shipping routes unless an ADR says otherwise.

**Flutter UI — MD3E Lab** (`app/lib/md3e/`, `integrate/md3e`) → **Widgetbook** (`app/widgetbook/`, `flutter run -t widgetbook/main.dart`) + `material_3_expressive` official docs; patterns/pages live in `md3e/`. Visual acceptance for Lab is Widgetbook, not Figma frames.

**design-system/** → **cleared** (2026-11-01): only `.gitkeep` and `example.png` remain; `hentai-library/MASTER.md`, `pages/*`, `research/` were removed (recoverable from git history). No UI spec lives here; see ADR-0030. ADR-0029 charter is superseded for any future visual refresh unless a new ADR reintroduces a doc source.

**Dart layout & imports** (features/shared/core, MVVM) → ADR-0017、ADR-0027、**ADR-0033**（feature `application/`）、**ADR-0034**（cross-feature 仅 `features/*/public/**`）；Wayfinder 终态以 `app/test/gate/` 为准，并由 `project_layout_test.dart` 等门禁强制执行。

**Rust** (sync, read, DB) → `core/`; see `docs/adr/README.md` (ADR-0002 and related).

**Tests & CI** → `docs/engineering/gate.md`; tier names ADR-0018; workflows `.github/workflows/gate.yml`.

**Issues** · **logs export** · **tag dictionary JSON** → `docs/engineering/maintainer.md`.

**Git workspace (agents)** — 未经用户明确允许，不要为改代码而新建 `git worktree` 或额外分支；在当前 clone 与用户指定的分支上工作即可。

## Agent skills

### Issue tracker

GitHub Issues via `gh` (default); local `.scratch/<feature>/issues/` only when `gh` cannot reach GitHub. See `docs/agents/issue-tracker.md`.

### Triage labels

Canonical state + category roles; label strings match GitHub. See `docs/agents/triage-labels.md`. Maintainer workflow: `/triage` skill.

### Domain docs

Single-context: `GLOSSARY.md` + `docs/adr/`. See `docs/agents/domain.md`.
