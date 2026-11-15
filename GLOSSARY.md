# Glossary

Use these English terms in issues, PRs and code. Definitions describe product semantics; procedures belong in [engineering guides](docs/engineering/README.md), decisions in [ADRs](docs/adr/README.md), and user-facing capabilities in [README](README.md). Avoid entries identify misleading synonyms, not forbidden UI translations.

## Application and boundaries

**App data profile**: The local application data tree (database, preferences, logs and caches) tied to application identity. Release uses `default`; Debug/Profile use isolated `dev`. A profile is not a Library. ADR-0010.
_Avoid_: development Library, release Library, database environment.

**Application layer**: Optional pure Dart use-case orchestration in `features/*/application/`. It is unrelated to on-disk application data. ADR-0033/0051.
_Avoid_: application data directory, presentation/FRB logic in application.

**Feature public API**: Exported contracts, observable state and UI capabilities consumed by other modules, with concrete dependencies bound by the host. ADR-0034/0051.
_Avoid_: cross-feature deep imports, shared code importing feature public APIs.

## Libraries and resources

**Library**: A user's collection associated with one Library root, containing imported Comics and Folder series. Each has its own display name and sync configuration. Multiple Libraries coexist, with global status on Home and browsing scoped to a Library.
_Avoid_: bookshelf as a domain term, merged Library, global catalog browsing.

**Home page**: Default `/home` route with continue-reading, Recently added on Home, Home page counts, Reading activity stats and dismissible Home library alerts. Presentation belongs to home; counts/activity belong to reading_stats. It has no permanent global sync action. ADR-0020.
_Avoid_: current-Library dashboard, Home scan, Home dashboard.

**Home page counts**: Cross-Library catalog counts for Comics, Series and global Author/Parody/Character/Tag dictionaries, reflecting visibility after Comic trash. Distinct from reading behavior metrics; owned by reading_stats.
_Avoid_: read count, Reading activity stats.

**Home library alert**: Dismissible status for a particular Library: unreachable root, failed/stale sync or resources detected by a probe. An alert may offer sync for that Library.
_Avoid_: permanent Home scan button, notification center.

**Library resource probe**: Read-only root enumeration compared with the last successful Library resource snapshot to count added/changed/removed Resources. It does not parse archives, write catalog entities or acquire the library write lock. Sync follows user confirmation. ADR-0021.
_Avoid_: automatic sync, file watcher, lightweight scan.

**Library resource snapshot**: Persisted normalized location key, modified time, size and resource type from the end of the last successful sync. Failed/cancelled sync does not replace it; it is neither a backup nor Comic identity.
_Avoid_: scan cache, content hash index.

**Recently added on Home**: A cross-Library horizontal list of recently imported Comics ordered by catalog insertion time, labelled with source Library; opens details or a Read session.
_Avoid_: recommendations, discovery feed, For you.

**Local library**: A Library rooted in a local directory; imported Resources can be read offline.
_Avoid_: local bookshelf, disk collection as a separate domain type.

**Remote library**: A Library rooted in WebDAV, discovered and read through streaming Resource access without caching a whole Comic to disk.
_Avoid_: official cloud account, online bookshelf.

**Library root**: A Library's unique local directory or WebDAV root URL; discovery and reconciliation are relative to it.
_Avoid_: Saved path in new designs, mount point.

**Saved path**: Retired name for a Local library root. The old Path UI/API is removed; only legacy schema/migrations retain the name. Library creation uses Library form through Home or the shell flyout. ADR-0014.
_Avoid_: Selected Paths page, extending Saved path to remote URIs.

**Comic**: An independently readable work in a Library, corresponding to one Resource. Its ID derives from the normalized resource location. Dart Comic is an owner projection entity with invariants, draft application and metadata diffs; Rust owns transactional writes. ADR-0041.
_Avoid_: item/work as an ambiguous replacement, Dart transaction aggregate.

**Comic identity**: Identity anchored to a normalized local path or WebDAV resource URL, not content hashes. Moving/renaming changes `comicId`; Path migration preserves continuity when eligible. ADR-0001/0013.
_Avoid_: content ID, file fingerprint identity.

**Path migration**: Rekeying an existing Comic/Series after a verified location change while preserving its user state; explicit readable Local root changes retain eligible relative-path continuity. Unique matches of previously recorded full-content fingerprints also permit automatic continuity; weak fingerprints and ambiguous copies do not, and records without prior content evidence cannot be matched retroactively (ADR-0001/0013/0054/0055).
_Avoid_: content-hash identity, unconditional rename preservation, Metadata refresh.

**Comic deletion**: Historical umbrella for the user-driven trash-then-purge lifecycle. Use the specific stage in new text. Sync orphan cleanup and Library removal delete records, not Resources. ADR-0012/0023.
_Avoid_: automatic disk deletion, removal implying local files are always retained.

**Comic trash**: Hide a Comic from all browse/search/Series/history surfaces and prevent reading while retaining records, metadata, locks, history and Resource for restore. Local/Remote behavior is the same. Sync never resurrects it; a vanished Resource may still be orphan-cleaned. ADR-0023.
_Avoid_: operating-system recycle bin, archive, simple visibility toggle.

**Comic restore**: Restore visibility/readability of a trashed Comic together with its retained metadata/history. ADR-0023.
_Avoid_: restoring a deleted file.

**Comic purge**: Explicit permanent removal of an already-trashed Comic. Local purge validates paths and deletes its Resource before clearing records; missing Resources count as success, disk deletion failure leaves records trashed. Remote purge removes records only. It is never automatic. ADR-0012/0023.
_Avoid_: automatic cleanup, system recycle-bin emptying.

**Resource**: Original local file/directory or WebDAV file that may be discovered and imported as a Comic. Parsing before import is independent of Comic identity/user metadata; sync, refresh, reading and thumbnails share Resource access rules.
_Avoid_: file when directory/remote support matters, asset.

**Resource access**: Uniform listing, stat and read-only streaming of Resources under a Library root, implemented by filesystem or WebDAV adapters.
_Avoid_: UI-specific protocol branches, cloud SDK, VFS as the domain name.

**Scan**: Root traversal and Resource discovery/registration/parsing. User-triggered Scan and Library sync refer to the same operation; domain documentation prefers Library sync.
_Avoid_: import/index when reconciliation semantics matter.

**Library sync**: Reconcile a selected Library with its root: discover/add, merge unlocked metadata, perform eligible Path migration and remove remaining orphans. Unreachable remote roots preserve existing records. Removing a Library clears its Comic/Series records. Core invalidates affected reading sessions and shares the library write seam with Metadata refresh and local-root migration.
_Avoid_: refresh, generic synchronization without mirror/removal semantics.

**Supported resource formats**: Per-Library Resource format categories included in the next sync. Disabling a category excludes those Resources and makes corresponding catalog Comics orphans on that sync.
_Avoid_: browse media filter, global import-format setting.

**Resource format category**: Selection groups `folder` (`dir`), `pdf`, `epub`, `archive` (zip/cbz/rar/cbr/7z/cb7), expanded to resource types by core. Remote libraries do not initially import folders.
_Avoid_: raw extension list as the preference model.

**Scan on startup**: Per-Library switch for one incremental sync after application startup, independent of Scan interval.
_Avoid_: retired global autoScan preference, generic automatic scan.

**Scan interval**: Per-Library incremental sync schedule: disabled/hourly/every_6_hours/every_12_hours/daily/weekly. Its anchor is application startup or enabling/changing the interval; scheduling runs only while the application runs.
_Avoid_: cron, global scan interval.

**Pinned library**: Library listed before unpinned Libraries on Home and the shell flyout. New Libraries start pinned at the end of the pinned group. ADR-0009.
_Avoid_: favorite Library, sticky-header semantics.

**Unpinned library**: Library with `pinned = false`, following the pinned group. Drag reorder may move it between groups; it is not hidden/collapsed.
_Avoid_: secondary Library, hidden Library.

**Library sidebar order**: User order within each pinned/unpinned group. Library listing returns pinned first, then group order; unrelated to Series member order/locks.
_Avoid_: Series sortOrder, unspecified Library sorting.

**Library reorder mode**: Retired sidebar-wide mode. Home now supports long-press drag reorder without a separate mode; the exit command remains for exclusion with browse selection/sorting state.
_Avoid_: current sorting page, standalone pin toggle.

## Organization and metadata

**Series**: Named ordered Comic collection within one Library, maintained from immediate parent folders by sync. A Comic belongs to at most one Series; after successful rebuild, every resolvable parent yields a Folder series, including the Library root. Members use natural filename order unless a manually saved floating-point order is locked; unlocking restores filename order on the next sync. Status/planned volumes have metadata locks. Rust owns membership/order writes.
_Avoid_: album, cross-Library collection.

**Folder series**: Series derived from a Comic's immediate parent directory, including root-level Comics. Identity derives from normalized local/remote `folder_path` within its Library.
_Avoid_: title inference, automatic title grouping.

**Library root series**: Folder series whose folder path equals its Library root.
_Avoid_: pinned Series, separate isRoot entity.

**Prefer library root series**: Default-enabled browse preference exposed in Settings: place the root Series first if it survives filtering; retain current ordering/grouping for the rest.
_Avoid_: pin Series, a Series grouping mode.

**Group by serialization status**: Flat Series ordering in status blocks: ongoing, completed, hiatus, cancelled, unknown, with the current sort inside each block. Independent of filtering/sorting; default grouping is none.
_Avoid_: serialization filter, collapsible headings.

**Group by series**: Default flat Comics grouping: root-Series members first, other Folder series by ascending name, unassigned Comics last; preserve current Comic sort within blocks. No headers/collapse, and independent of Prefer library root series.
_Avoid_: expand by Series, Series mode list.

**Default library display target**: Application preference selecting Comics (default) or Series on entering Library browsing, distinct from a temporary tab change.
_Avoid_: homepage tab, default interface.

**App preference**: Application-wide preferences persisted by Dart SharedPreferences, including theme/locale, reading options, updates, Healthy mode, root-Series preference, Smart facet match and default browse target. app_settings owns storage schema/defaults/clamps; Reader owns reading enums/semantics. They communicate through primitive ReadingPreferencesRecord with total decode fallback/reporting and exhaustive encode, with one readingPreferencesControllerProvider write entry. ADR-0016/0046.
_Avoid_: Library property, settings.json, AppSetting DTO as a domain term.

**Library browse preference**: Shared-across-Libraries browse state: filters, sort/group settings and page size, persisted in SharedPreferences. Author filters store stable IDs; name facets store names. Usually edited in browse, with the root-Series preference exposed in Settings.
_Avoid_: per-Library database settings, Library property.

**Library property**: Configuration attached to one Library and persisted through FRB/Rust SQLite: root/display name, startup/interval sync, formats, pinning and sidebar order.
_Avoid_: application preference, Library settings form.

**Settings list–detail**: Responsive Settings navigation: wide screens show a primary settings list and selected category detail, defaulting to the first item; narrow screens navigate from a full-width list into detail. The app sidebar is hidden. Back exits Settings on wide screens and returns to the list from narrow detail.
_Avoid_: app navigation rail, nested global sidebar.

**Tag**: Global named descriptive metadata attached to Comics and usable for filtering. Independent of Author, Parody, Character and Language.
_Avoid_: all metadata facets collectively called Tags.

**Tag dictionary import**: Idempotent import of a JSON name array or `{ "tags": [...] }` into the global dictionary: trim/discard empty names, skip exact-name matches, preserve existing Tags and do not attach Comics. ADR-0011.
_Avoid_: EhTagTranslation integration, Comic metadata import.

**Author**: Credited entity with a stable ID, mutable unique case-sensitive display name and optional links/details. Artists, circles and original creators share this type; legacy name-only data becomes an unverified Author. ADR-0024.
_Avoid_: name-only string identity, separate Circle entity, Author profile as the domain name.

**Verified author**: Author with at least one Creative platform link. Indicates in-app information completeness, not external official verification.
_Avoid_: verified platform account, official badge.

**Author alias**: Platform display name differing from the Author's current display name; comparison/deduplication is case-sensitive. Derived from platform profiles, ordered by Creative platform priority and comma-joined; equal names are omitted.
_Avoid_: manually maintained nickname dictionary.

**Creative platform**: Closed priority order Pixiv, X, Patreon, FANBOX, Discord for author verification, aliases and image resolution. Other links are excluded.
_Avoid_: any social platform, Other contributing to verification.

**Author link**: User-entered external URL, with platform inferred from its hostname. Multiple links are allowed; recognized creative links contribute to verification/images, Other links are navigation only.
_Avoid_: OAuth binding, platform login, manually chosen platform.

**Author image**: Independently resolved avatar/background: use platform profile images by Creative platform priority, then the natural-order first visible Comic's cover across Libraries (respecting its selected cover page), otherwise empty. Details use high-resolution bitmaps; thumbnails are interim only. Show an image-loading indication after a URL is known, not while profile discovery is still pending. ADR-0025.
_Avoid_: cover preview, Author thumbnail.

**Parody**: Original work/IP referenced by a Comic, allowing multiple values or a literal original-work value. Unrelated to Folder series.
_Avoid_: Series, legacy work kind.

**Character**: Character name attached to a Comic for display/filtering, separate from Tag and Author.
_Avoid_: character Tag, legacy actor kind.

**Named metadata facet**: Filterable Comic metadata: Tag/Parody/Character use name dictionaries and replace-all junctions; Author uses stable identity/junctions; Language is a closed JSON-list exception. Author and name-dictionary pipelines remain separate.
_Avoid_: metadata field when facet identity matters, tag family.

**Named facet attachment count**: Number of currently visible Comics attached to a facet across Libraries (by stable identity for Author), including zero for unused entries; used in candidate ordering and metadata chips.
_Avoid_: session reference count, popularity, ref_count.

**Pinyin-assisted name match**: Client-side name filtering: Latin input matches case-insensitive substrings or toneless full/initial pinyin; Han input uses display-name substrings only. Applies to facet selection and Author/Tag management search, not exact facet-token catalog search.
_Avoid_: fuzzy/full-text search engine, pinyin catalog index.

**Smart facet match**: Default-enabled application preference improving metadata-form candidate order, never auto-selecting or inventing names. Author signals use whole dictionary names as case-insensitive substrings in title, filename without extension and relative parent path segments; independent matching sources raise rank, identical title/filename count once, and brackets are not specially parsed. Other name facets use attachments of sibling Comics in the same non-root Folder series. Signal matches precede attachment count and show their source; the toggle lives in Settings only.
_Avoid_: automatic tagging, suggested values written without selection.

**Comic catalog query**: Shared Library/search query: Dart assembles filter intent; core owns SQL predicates and typed facet helpers.
_Avoid_: duplicate Flutter WHERE implementation, in-memory matches.

**Language**: A single Comic text-language value, canonically Chinese, Japanese, English, Korean, Spanish or Other; absence means unknown. Localize known names for display and preserve unrecognized imported values; unrelated to interface locale. ADR-0057.
_Avoid_: UI language, translation language, free-form Tag.

**Content rating**: User-set unknown/safe/r18 Comic classification. Path-based automatic detection is retired. Healthy mode filters visibility without changing the rating.
_Avoid_: automatic r18 path marking, age filter as stored rating.

**Comic metadata form**: Validated/normalized editable draft for title, summary, release date, rating and facets/languages. Save only values changed from the opening snapshot and automatically lock those fields; unchanged drafts do not write. Locks may also be toggled without value changes; report validation per field.
_Avoid_: metadata DTO, generic Comic form.

**Comic aggregate write set**: Comic row, metadata/field locks and facet junctions committed in one Rust transaction. Core owns partial updates, merging and atomicity; Dart only projects values and computes draft diffs. ADR-0002/0026/0041.
_Avoid_: ComicAggregate class in Dart, frontend transaction.

**Needs metadata**: No user metadata other than title: no facet attachments, languages, summary or release date, and rating unknown. Derived from current values regardless of provenance or field locks, not editing history.
_Avoid_: untagged, unedited, unstaged.

**Catalog selection mode**: Temporary cross-page Comics-tab multi-selection supplying IDs for bulk patch; excludes Library/Series reorder modes. Clears on Library/filter/sort/route changes and is absent from search.
_Avoid_: bulk patch itself, generic batch mode.

**Comic metadata bulk patch**: Sparse update of selected fields for Comics in one Library. Multi-value fields add/remove/replace; scalars replace/clear. Core merges per Comic and locks written fields; existing locks do not block user writes. Enter from Library selection or Series member shortcuts. ADR-0022.
_Avoid_: batch refresh, single-Comic form, Library sync.

**Series metadata form**: Validated draft for name/status/planned volumes. Planned volumes retain raw text (empty clears, positive integer sets). Save changed values only and auto-lock them; locks can change independently; validation is per field.
_Avoid_: SeriesForm DTO, Series metadata entity.

**Library form**: Validated creation/edit draft for required display name, local/WebDAV root, remote credentials (blank edit password preserves it), allow-HTTP and sync/formats settings. Local roots cannot equal/nest each other. Changing a readable local root preserves libraryId and migrates relative Comic/Series paths; an unreadable root is saved without immediate migration. No automatic sync or unchanged-draft write; all creation uses this form. ADR-0014.
_Avoid_: bare directory selection as creation, Library settings form.

**Metadata field lock**: Per-field protection from sync/refresh overwrite. Unlocked values are replaced only by parsed nonempty values; absent scan values never clear data. User-changed saved fields auto-lock; independent lock/unlock does not trigger sync/refresh. Series member ordering follows the same policy. Core centralizes merging. ADR-0006/0007.
_Avoid_: read-only flag, freeze, lock preventing explicit user edits.

**Metadata refresh**: Reparse a Comic, Series members or Library through Resource access and merge under field locks. Update Comic physical metadata without rebuilding thumbnails; Series refresh may update an unlocked folder name but not status/planned volumes/member order. Skip/report individual failures and retain writes on cancellation. Unreachable remote roots preserve data. Core shares a global single-flight library write lock with sync, failing immediately when busy. UI shows busy/completion summary, not live progress. No orphan cleanup or membership rebuilding.
_Avoid_: UI catalog reload, Library sync, rescan.

**Resource metadata embedding**: Persisting in-app Comic metadata into its original Local Resource for use outside the application. Distinct from Metadata refresh, which reads Resource metadata into the catalog, and Metadata backup, which creates a separate restore snapshot.
_Avoid_: Metadata refresh, Library sync, metadata backup as synonyms for source modification.

**Media page**: A Home-linked view of Local Comic metadata and automatic Resource metadata embedding state, scoped by Library and embedding status. Its initial scope excludes Library management and Comic trash; it does not imply live comparison with source metadata. ADR-0057.
_Avoid_: global Library manager, metadata dictionary management, manual export queue.

**Metadata backup**: JSON snapshot of Comic user metadata, locks and orphan dictionary entries (`.hlmeta.json` / `.hlmeta.json.gz`), manually or automatically exported for external storage/restoration.
_Avoid_: database backup, Resource snapshot.

**Metadata backup import**: Manual restore matching comic_id, then normalized_path, then library_id+relative_path. Matched entries overwrite metadata and force all field locks; missing/ambiguous entries are skipped. Enter through Settings.
_Avoid_: implicit restore, dry-run as user-facing terminology.

**Metadata backup import preview**: Read-only use of the same matching plan to report restore/missing/ambiguous counts and examples before confirmation. Writes nothing, including orphan dictionary entries.
_Avoid_: committing import, dry-run in user copy.

**Healthy mode**: Application-wide browse filter hiding r18 Comics from Library/search/history without altering stored Content rating.
_Avoid_: youth/safety mode, rating mutation.

## Design and UI

**Module ownership**: Complete visual/interaction behavior belongs to the design system; product workflows, domain presentation and collaboration belong to feature owners/shared product UI. For domain contracts, the producer owns them unless importing it violates a forbidden edge, creates a public cycle or is required by shared code. Shared domain vocabulary, application signatures, UI contracts and provider tokens use their corresponding shared layers, with implementations bound in composition. ADR-0045/0051/0053.
_Avoid_: most consumers determine ownership, all Ports in shared, unspecified shared component.

**Design system**: The application's complete visual/interaction system: theme/tokens, layout/motion, keyboard/focus/accessibility, component state and complex inputs. Uses presentation data/callbacks rather than business queries/navigation. Application dependencies stay within `app/lib/design-system/`; sole public entry is `design_system.dart`. ADR-0053.
_Avoid_: style collection only, every shared UI element, M3E wrapper layer only, root documentation archive.

**MD3E design system**: Material 3 Expressive direction of the production UI, assembled through the single buildAppTheme source. Design-system components use M3E color roles and the violet brand seed; product adapters remain with shared UI/features.
_Avoid_: parallel Baseline theme, new skin without naming the system.

**Tone-based color system**: Seed-derived color-role system based on HCT perceptual tone and role tone differences, not a fixed hex palette.
_Avoid_: toneBased surface-pair API, HCT color space alone.

**Dynamic color**: Platform wallpaper/accent color used as the seed of tone-based theme assembly; enabling it disables manual palette selection.
_Avoid_: MCU dynamic scheme variant, Monet as the cross-platform domain name.

**Reader color extension**: Focused Reader theme extension whose immersive canvas remains dark even in light application themes; accent roles follow the current shell ColorScheme.
_Avoid_: HentaiColorScheme, making the reading canvas follow shell brightness.

**Baseline UI**: Historical Fluent-oriented UI/theme, replaced as the production shell by MD3E Cutover. Residual names/components do not imply two active production systems.
_Avoid_: current legacy shell, parallel production skin.

**MD3E preview page**: Whole-page mock-data/Widgetbook composition for visual acceptance, separate from a production route with a ViewModel.
_Avoid_: production feature view, route page.

**MD3E Lab**: Historical pre-Cutover development stage. The production `app/lib/md3e/` package is retired; previews remain under `app/widgetbook/`.
_Avoid_: current production Lab module, active dual UI tracks.

**MD3E Pilot**: Completed stage connecting one feature (initially Settings) to MD3E components/theme with real data/navigation; retained for historical ADRs/PRs.
_Avoid_: beta skin.

**MD3E Cutover**: Feature-by-feature replacement of Baseline UI with MD3E and consolidation to one theme. The main cutover is complete; remaining preview/historical names do not reopen dual tracks. ADR-0031.
_Avoid_: unspecified large refactor.

**MD3E pattern**: UI composition named for a product scenario, communicating through ordinary data/callbacks without importing domain or feature code.
_Avoid_: feature orchestration, Figma frame as implementation truth.

**ViewObject**: Aggregate immutable screen presentation data, named `*ViewObject`, consumed by route pages/display layouts. Not a transport DTO or a state/command ViewModel.
_Avoid_: Entry for a screen aggregate, View, Dto, ViewModel.

**Route page**: Production route-bound `*Page` Widget that consumes a ViewModel and assembles real data into presentation inputs.
_Avoid_: Md3ePage in new production code, View as the route class suffix, preview shell called Page.

**Display layout**: Presentation/preview `*Layout` Widget consuming ViewObject data to assemble visuals. Distinct from reading layout modes and the general layout layer. Menu fragments may retain `*Entry`; boundary payloads use `*Dto`.
_Avoid_: View as the display-shell suffix, Page without a production route.

## Reading

**Reader**: Product module `features/reader/`: page IO, viewport/chrome, settings, Series volume navigation and Read session orchestration. ADR-0038; names in [reader-ddd-lexicon.md](docs/engineering/reader-ddd-lexicon.md).
_Avoid_: read_session module, Reading module ambiguous with history/stats.

**Read session**: Lifecycle opened by comicId (plus options such as incognito), with no separate standalone/Series modes or seriesId input. Progress belongs only to Reading history. Exit returns to the Comic detail page. Remote Resources stream without whole-book disk caching. Entity/orchestration belong to Reader. ADR-0005/0038.
_Avoid_: Standalone read, Series read, Comic read, Read session as the module name.

**Series reading context**: Optional core-derived seriesId/name/ordered Comic IDs/current index for volume navigation. Not a session mode or progress record. Absent when no Series applies; Flutter formats member titles using the existing indexed Comic title convention.
_Avoid_: Series session, Series reading mode.

**Reading history**: Global per-Comic last-read time/page across Libraries, used when reopening. Switching volumes flushes the current Comic's progress and opens the target at page one. Incognito sessions neither read nor write history. Clearing history leaves activity statistics intact.
_Avoid_: Series progress, Reading activity stats.

**Reading progress (history list)**: Current history page divided by catalog Comic page count; total pages are not a persisted history field.
_Avoid_: independent history page-count storage.

**Reading activity stats**: Lifetime Finished comic count and Reading duration, persisted by reading_stats and shown on Home, independent of catalog counts/history.
_Avoid_: Home page counts, history statistics.

**Finished comic**: A Comic whose non-incognito session first reaches its last catalog page (page count must be positive). The distinct-Comic mark is sticky across later page-count changes; visibility excludes trashed/missing Comics, restore re-enables retained marks, purge/Library deletion removes them, and Path migration rekeys them. Existing completed history can backfill marks. No ten-second requirement or manual mark-as-read action.
_Avoid_: viewed Comic, manual mark as read.

**Reading duration**: Foreground time from non-incognito sessions qualifying at ten seconds; once qualified, all elapsed reading time including the first ten seconds counts. Stop on exit/background. Lifetime accumulated duration is neither backfilled nor reduced by trash/purge; no daily aggregation, idle cap or user reset in the initial scope.
_Avoid_: estimated reading time, Time to Read, remaining duration.

**Scroll layout**: Continuous vertical Reader layout.
_Avoid_: Webtoon as a work classification or ambiguous mode name.

**Paged layout**: Reader layout advancing through discrete pages rather than continuous scrolling.
_Avoid_: single-page-only mode.

**Page image fidelity**: Preserve source bitmap appearance in a Read session. Keep GPU sampling fixed at `FilterQuality.medium` for stable downsampling; do not change quality for scrolling/idle state, sharpen/beautify, or switch to high at rest (moire risk in screened artwork). Viewport/memory-constrained decoding such as cacheWidth is allowed. This rule overrides Reader performance-tuning advice and excludes catalog covers/thumbnails.
_Avoid_: scroll quality reduction, idle quality boost, FilterQuality.high for page images, enhanced/sharpened reading.

**Page image copy**: Copy a page bitmap from a Read session to the system clipboard, distinct from Comic covers/thumbnails or saving/exporting files.
_Avoid_: share image, export page, save image.

**Auto-play mode**: Persisted application preference for end-spread behavior after a full interval: single Comic, Comic loop, Series play, Series loop (default: single Comic). The enabled switch is session-only. Series capability derives from Series reading context and does not create a new session model.
_Avoid_: single/Series session modes, Series read.
