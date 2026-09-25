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
| `ui/` | Shared widgets/theme and feature modules (`features/*/view_models/`, `features/shell/di/`). |
| `src/rust/` | FRB generated — do not hand-edit. |

Import canonical paths from `app/lib/`. Do not add Flutter sources at the repo root or under removed legacy roots (`presentation/`, `model/`, `repository/`, `services/`, `usecases/`, `database/`).

## UI architecture (MVVM)

Presentation layer follows **MVVM with Riverpod** (ADR-0017). State management is **Riverpod 3 only** (`flutter_riverpod`, `hooks_riverpod`, `riverpod_annotation`) — not the legacy `package:provider`.

| Layer | Path | Role |
|-------|------|------|
| View | `ui/features/**/views/`, `ui/core/widgets/` | Render; `ref.watch` ViewModel/Facade; fire commands via Notifier or callbacks |
| ViewModel | `ui/features/**/view_models/` | UI state, Repository/Service orchestration, command API |
| Model | `domain/models/`, `domain/repositories/` | Entities and repository interfaces |

**Hard rules**

- **View must not call Repository** — no `*RepoProvider` in `views/` or `ui/core/widgets/`. Shared widgets use constructor callbacks; feature pages delegate to ViewModel.
- **ViewModel lives under `view_models/`** — `state/` directories are gone (e.g. `shell/view_models/current_library_notifier.dart`, `settings/view_models/diagnostic_mode_notifier.dart`); `test/project_layout_test.dart` fails if one reappears under `ui/features/`.
- **Complex pages** may keep internal intent→derive chains; expose a **Facade Provider** to the page root. Leaf widgets may still `select` fine-grained fields.

**Class naming**

| Suffix | Use |
|--------|-----|
| `{Noun}Notifier` | Mutable UI state (`SettingsNotifier`) |
| `{noun}ViewModel` provider | Read-only aggregate (`readerPageViewModel`) |
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
| `ui/core/widgets/**` | **Strict:** file name = primary public type in `snake_case` (`theme_preference_row.dart` ↔ `ThemePreferenceRow`). |
| `ui/features/**/widgets/**` | **Loose:** feature prefix allowed; stay consistent within the feature. |
| Barrel files (`widgets.dart`, `providers.dart`) | Export-only; file name need not match a type. |

### UI payload types

- **Stateful UI:** sealed `{Noun}State` consumed by widgets.
- **Plain data bundle** (no persistence / wire format): prefer `typedef` + record per [Lightweight data shapes](#lightweight-data-shapes).
- `*Dto` suffix: FRB / JSON / serialization boundaries only — not general UI pass-through types.

