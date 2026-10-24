# Hentai Library

Monorepo: **`app/`** Flutter · **`core/`** Rust (FRB).  
Setup: `./scripts/setup-dev.sh` · PR gate: `./scripts/run-gate.sh` · Human onboarding: `README.md` · Contributor map: `CONTRIBUTING.md`.

**Glossary** — domain terms, terminology, edit ADR → `GLOSSARY.md` + `docs/adr/`.  
**Read session pages** → `GLOSSARY.md` **Page image fidelity** only.

**Product scope** (capabilities, platforms) → `README.md` § 核心功能 / 支持平台.

**Flutter UI** (shell, tokens, components) → `design-system/hentai-library/MASTER.md` (+ `pages/*` per route). Same tree: design planning, Agent UI spec, ui-ux-pro-max `--persist` output (ADR-0029); token **values** live in `app/lib/shared/ui/theme/`.

**Dart layout & imports** (features/shared/core, MVVM) → ADR-0017, ADR-0027; Wayfinder 终态以 `app/test/gate/` + ADR-0027 为准，并由 `project_layout_test.dart` 等门禁强制执行。

**Rust** (sync, read, DB) → `core/`; see `docs/adr/README.md` (ADR-0002 and related).

**Tests & CI** → `docs/engineering/gate.md`; tier names ADR-0018; workflows `.github/workflows/gate.yml`.

**Issues** · **logs export** · **tag dictionary JSON** → `docs/engineering/maintainer.md`.

## Agent skills

### Issue tracker

GitHub Issues via `gh` (default); local `.scratch/<feature>/issues/` only when `gh` cannot reach GitHub. See `docs/agents/issue-tracker.md`.

### Triage labels

Canonical state + category roles; label strings match GitHub. See `docs/agents/triage-labels.md`. Maintainer workflow: `/triage` skill.

### Domain docs

Single-context: `GLOSSARY.md` + `docs/adr/`. See `docs/agents/domain.md`.
