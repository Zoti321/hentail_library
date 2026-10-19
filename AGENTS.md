# Hentai Library

Monorepo: **`app/`** Flutter · **`core/`** Rust (FRB).  
Setup: `./scripts/setup-dev.sh` · PR gate: `./scripts/run-gate.sh` · Human onboarding: `README.md` · Contributor map: `CONTRIBUTING.md`.

**Glossary** — domain terms, terminology, edit ADR → `GLOSSARY.md` + `docs/adr/`.  
**Read session pages** → `GLOSSARY.md` **Page image fidelity** only.

**Product scope** (capabilities, platforms) → `README.md` § 核心功能 / 支持平台.

**Flutter UI** (shell, tokens, components) → `design-system/hentai-library/MASTER.md` (+ `pages/*` per route). Same tree: design planning, Agent UI spec, ui-ux-pro-max `--persist` output (ADR-0029); token **values** live in `app/lib/shared/ui/theme/`.

**Dart layout & imports** (features/shared/core, MVVM) → ADR-0017, ADR-0027; enforced by `app/test/gate/` + `project_layout_test.dart`.

**Rust** (sync, read, DB) → `core/`; see `docs/adr/README.md` (ADR-0002 and related).

**Tests & CI** → `docs/engineering/gate.md`; tier names ADR-0018; workflows `.github/workflows/gate.yml`.

**Issues** · **logs export** · **tag dictionary JSON** → `docs/engineering/maintainer.md`.

Do not use `docs/archive/` as current spec.
