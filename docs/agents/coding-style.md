# Coding Style

Project-specific conventions for UI widgets and lightweight data shapes. Agents should follow these when writing or refactoring code.

## Project layout

**Target monorepo** (see `docs/agents/rust-migration.md`):

| Path | Role |
|------|------|
| `app/lib/core/` | Cross-cutting Dart utilities (logging, l10n, path/format helpers). |
| `app/lib/domain/` | Domain models (`models/`). Use cases are removed after Rust migration; library query **projection** (`library/`) may remain for UI filter building. |
| `app/lib/data/` | Repositories (thin FRB adapters). No Drift, no `services/comic/` after migration. |
| `app/lib/ui/` | Shared widgets/theme and feature modules. |
| `core/crates/core/` | Rust: SeaORM, scan, sync, reader, thumbnail, series inference. |
| `core/crates/flutter/` | FRB glue (`#[frb]` API). |

**Legacy (pre-migration):** layers under repo-root `lib/` — same roles as `app/lib/` above.

Import canonical paths from `app/lib/` once the monorepo move lands. Do not add files under removed legacy roots (`presentation/`, `model/`, `repository/`, `services/`, `usecases/`, `database/`, `module/` at `lib/` root).

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
- `SelectedPathsListCard` → `ConsumerWidget`
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

### Completed renames (reference)

| Former | Current |
|--------|---------|
| `librarySeriesRepo` | `seriesRepo` |
| `libraryTagRepo` | `tagRepo` |
| `libraryAuthorRepo` | `authorRepo` |
| `settings_theme_row.dart` / `ThemePreferenceRow` | `theme_preference_row.dart` |
| `rename_tag_dialog.dart` / `TagNameEditorDialog` | `tag_name_editor_dialog.dart` |
| `ComicCoverDisplayData` | `ComicCoverImage`（`comic_cover_image.dart`） |
| `HistoryGridItemDto`（freezed） | `HistoryGridItem`（typedef record + `historyGridItem()`） |
| `PageRequest` class | `PageRequest` typedef record + `pageRequest()` |
| `comicCoverDisplayDataOrPrevious` | `comicCoverImageOrPrevious` |
| `MyToggleSwitch` / `my_toggle_switch.dart` | `ToggleSwitch` / `toggle_switch.dart` |
| `DebouncedActionRunner` / `debounced_action_runner.dart` | `Debouncer` / `debouncer.dart` |
| `MetadataPanelHeightCalculator` | `metadataPanelCardHeight()` + `kMetadataPanelHeightDefaultConfig` |

