# Coding Style

Project-specific conventions for UI widgets and lightweight data shapes. Agents should follow these when writing or refactoring code.

## Project layout

Monorepo (`app/` Flutter, `core/` Rust): see `docs/agents/rust-core.md`. Dart layers under `app/lib/`:

| Path | Role |
|------|------|
| `core/` | Cross-cutting utilities (`logging` + `AppLog`, l10n, path/format helpers). |
| `domain/models/` | Entities and value objects. |
| `domain/repositories/` | Repository interfaces. |
| `domain/library/` | Filter / projection plus sync / refresh / deletion coordinators (FRB orchestration, not a second business core). |
| `domain/reading/` | Read session types and coordinators. |
| `domain/ports/` | UI-facing ports (clipboard, page source). |
| `data/repositories/` | Thin FRB adapters. No Drift. |
| `data/adapters/` | Mapper / guard / FRB call adapters. |
| `data/services/` | Dart-only services (app update, tag dictionary download). |
| `shared/` | Cross-feature Dart: `domain/`, `di/`, `ui/`, `util/` (not under `features/`). |
| `features/*/` | Vertical slices: `data/`, `domain/`, `di/`, `presentation/` (`views/`, `view_models/`, feature-only `widgets/`). |
| `features/bootstrap/` | App entry, routing, **composition root** (`ApplicationShell` injects shell slots). |
| `src/rust/` | FRB generated — do not hand-edit. |

Import canonical paths from `app/lib/`. Do not add Flutter sources at the repo root or under removed legacy roots (`presentation/` at repo root, `model/`, `repository/`, `services/`, `usecases/`, `database/`).

### Shared UI layers (ADR-0027)

Presentation MVVM (below) coexists with a **four-layer shared UI model**. Physical roots:

| Layer | Path | May import `features/`? |
|-------|------|-------------------------|
| **Shell** | `shared/ui/shell/` | **No** — layout chrome only; feature chrome via bootstrap slots |
| **Layout** | `shared/ui/layout/` | **No** — breakpoints, catalog/detail templates, sliver math |
| **Component** | `shared/ui/widgets/` | **No** — primitives, dialog **shells**, form controls without feature ViewModels |
| **Interaction** | `shared/ui/interaction/` | **No** — input mapping helpers that must not depend on a single feature |
| **Theme** | `shared/ui/theme/` | **No** |

**Feature composition** (`features/*/presentation/`) owns pages, domain dialogs (update, library form, metadata editor), `*Host` wrappers, and anything that `ref.watch`es a feature Notifier.

**Composition root** (`ApplicationShell` in bootstrap) wires shell feedback (e.g. diagnostic banner), sidebar builders (`LibrariesAppSidebar` via `AppShellSidebarSlot`), and other cross-feature chrome — not `ResponsiveAppShell` itself.

**Dependency gate:** `test/gate/shared_ui_no_feature_import_test.dart` scans `shared/ui/widgets`, `layout`, and `shell` for `package:.../features/` imports. Allowlist file must stay **empty** in steady state; fix violations by moving code or injecting callbacks — do not grow the allowlist for convenience.

**Placement rules when adding UI**

- Shared component needs feature data → **constructor callbacks** or a feature `*Host` widget; never import feature providers inside `shared/ui/**`.
- Dialog shows feature-specific copy or orchestration → `features/<feature>/presentation/views/dialogs/` (may still use `HentaiDialog` / `AdaptiveFormSurface` from shared).
- Catalog toolbar, facet multi-select, author surfaces → `library_browse` (or the owning feature), not `shared/ui/widgets/`.
- Cover decode priority / reader image provider → pass `ProviderListenable` or builder from feature into shared `ComicCoverContent` / `AppComicImage`.

**Large widgets**

- Prefer **one public type per file** under `shared/ui/widgets/**` (strict name match).
- When a control grows past ~400–500 lines, split with **`part` / `part of`** in the same library (keep a single import path for callers). Example pattern: main file exports public API; `*_state.dart` / `*_menu.dart` or tab `part` files hold private types.
- Do not split solely to satisfy line count if it fragments cohesive behavior without improving navigation — split at natural seams (menu overlay vs field state vs tab pane).

## UI architecture (MVVM)

Presentation layer follows **MVVM with Riverpod** (ADR-0017). State management is **Riverpod 3 only** (`flutter_riverpod`, `hooks_riverpod`, `riverpod_annotation`) — not the legacy `package:provider`.

| Layer | Path | Role |
|-------|------|------|
| View | `features/*/presentation/views/**`, `shared/ui/{widgets,layout,shell}/` | Render; `ref.watch` ViewModel/Facade; fire commands via Notifier or callbacks |
| ViewModel | `features/*/presentation/view_models/` | UI state, Repository/Service orchestration, command API |
| Model | `domain/models/`, `domain/repositories/` | Entities and repository interfaces |

**Hard rules**

- **View must not call Repository** — no `*RepoProvider` in `views/` or `shared/ui/widgets/`. Shared widgets use constructor callbacks; feature pages delegate to ViewModel.
- **ViewModel lives under `view_models/`** — `state/` directories are gone (e.g. `library_admin/presentation/view_models/current_library_notifier.dart`, `app_settings/presentation/view_models/diagnostic_mode_notifier.dart`); `test/project_layout_test.dart` fails if one reappears under `features/`.
- **Complex pages** may keep internal intent→derive chains; expose a **Facade Provider** to the page root. Leaf widgets may still `select` fine-grained fields.

**Class naming**

| Suffix | Use |
|--------|-----|
| `{Noun}Notifier` | Mutable UI state (`SettingsNotifier`) |
| `{noun}ViewModel` provider | Read-only aggregate（页面根聚合用 Facade Provider，如 `readerPageFacadeProvider`，见上文 Complex pages） |
| `{Noun}Controller` | Pagination catalog or long-running orchestration only (`ScanLibraryController`, `LibraryComicsCatalogController`) |

## Widget state

Prefer stateless widget variants. Avoid Flutter's built-in stateful widgets unless there is a concrete reason hooks or Riverpod cannot cover the case.

**Preferred (in order of fit):**

| Widget | When to use |
|--------|-------------|
| `StatelessWidget` | Pure presentation; no local state, no `ref` |
| `HookWidget` | Local ephemeral UI state (`useState`, `useAnimationController`, `useTextEditingController`, etc.) |
| `ConsumerWidget` | Read Riverpod providers; no local hook state |
| `HookConsumerWidget` | Both local hook state and Riverpod |

**Avoid by default:**

- `StatefulWidget` / `State<T>`
- `ConsumerStatefulWidget` / `ConsumerState<T>`

**Acceptable exceptions** (document in a short comment if non-obvious):

- Third-party APIs that require a `State` subclass (e.g. some animation or overlay integrations)
- `TickerProvider` / `SingleTickerProviderStateMixin` when hooks are impractical for that widget tree
- Legacy code not yet migrated — prefer migrating when touching the file

**Examples already in this repo:**

- `ReaderPage` → `HookConsumerWidget`
- `ComicCard` → `ConsumerWidget`
- `ParsedResource` flow widgets → prefer the table above over new `StatefulWidget`s

## Lightweight data shapes

For simple structural data used only to pass values between functions or layers — no JSON persistence, no `copyWith`, no generated equality — prefer Dart **records** with a `typedef` alias.

```dart
typedef ComicMeta = ({String title, List<String> authors, int? pageCount});
typedef ParsedResource = ({String path, ResourceType type, ComicMeta meta});
```

**Use a record / typedef when:**

- The shape is a plain bundle of fields
- It is not stored in the database or sent over the wire
- Immutability via reconstruction (`(a: x, b: y)`) is enough

**Use a class (often `freezed`) when:**

- The type needs `fromJson` / `toJson` or other serialization
- You need `copyWith`, deep equality, or pattern matching across many variants
- The type is a domain entity or persisted model (`Comic`, `Series`, UI state objects, etc.)

Do not introduce `freezed` or hand-written classes solely to group two or three fields for a single function return or parse step.

## Naming conventions

### Riverpod providers

Name providers by **layer** and **responsibility**:

| Pattern | Role | Examples |
|---------|------|----------|
| `{domain}Repo` | Data repository; shared across features. **No** `library` prefix. | `comicRepo`, `seriesRepo`, `tagRepo` |
| `{feature}{Noun}` | Feature-scoped state or query | `libraryComicDetail`, `libraryQueryIntent`, `comicCover` |
| `{feature}{Noun}Controller` | Paged lists, catalogs | `libraryComicsCatalogController` |
| `{domain}Cache` / `{domain}Coordinator` | Cross-cutting infra | `comicCoverThumbnailCache`, `thumbnailEventCoordinator` |

Rules:

- State types: `{Noun}State` (e.g. `ComicCoverState`). Provider function: `{noun}` → `{noun}Provider`.
- Notifier class: `{Noun}` — avoid `Manager` / `Runner` unless the type truly orchestrates multiple subsystems.
- Do **not** prefix repositories with `library` (e.g. prefer `seriesRepo` over `librarySeriesRepo`).

### File ↔ type names

| Location | Rule |
|----------|------|
| `shared/ui/widgets/**` | **Strict:** file name = primary public type in `snake_case` (`theme_preference_row.dart` ↔ `ThemePreferenceRow`). |
| `features/*/presentation/**/widgets/**` | **Loose:** feature prefix allowed; stay consistent within the feature. |
| Barrel files (`widgets.dart`, `providers.dart`) | Export-only; file name need not match a type. |

### UI payload types

- **Stateful UI:** sealed `{Noun}State` consumed by widgets.
- **Plain data bundle** (no persistence / wire format): prefer `typedef` + record per [Lightweight data shapes](#lightweight-data-shapes).
- `*Dto` suffix: FRB / JSON / serialization boundaries only — not general UI pass-through types.

