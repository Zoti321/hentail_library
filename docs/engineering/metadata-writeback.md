# Resource metadata embedding

ADR-0057 defines the product decisions. The implementation issues under [#549](https://github.com/Zoti321/hentail_library/issues/549) track delivery; an interface or codec alone does not imply automatic source-writing support.

## Ownership

Rust `resource_metadata` owns the portable metadata projection, sparse write intent, automatic work lifecycle and format Adapters. Existing Comic and dictionary owners retain user-edit validation and register durable intent with committed changes. Local mutation is separate from read-only Resource access. Flutter `resource_metadata` exposes writeback capability/status; `media` composes inspection and existing editing through owner public APIs. Home owns navigation only. Library form and Media edit one Library property.

## Portable extension version 1

The stable namespace is `https://github.com/Zoti321/hentail_library/ns/metadata`. The extension payload is a UTF-8 JSON object with integer `version: 1` and object `fields`. Field names match the existing Comic metadata field table: `title`, `description`, `published_at`, `content_rating`, `authors`, `tags`, `languages`, `parodies`, `characters`.

`title` is a string; `description` is string or null; `published_at` is signed UTC epoch milliseconds or null; `content_rating` is `unknown`, `safe` or `r18`; `authors`, `tags`, `parodies` and `characters` are ordered string arrays. Despite its legacy field name, `languages` is one string or null in this extension. Null and empty lists explicitly encode cleared values; an absent property makes no claim and falls back to the format's standard field.

The extension contains portable display values, not database identities, locks, Author links/profiles, Series management state or reading state. Exact array values avoid separator ambiguity. Preserve unrecognized envelope properties and field properties on sparse updates. A supported valid field overrides its standard projection; malformed fields fall back independently, and malformed/unsupported envelopes fall back completely on read. Writers refuse malformed or unsupported existing envelopes instead of destroying them.

New metadata and enablement backfill use a full snapshot. Incremental updates replace only the union of changed fields; replacing the snapshot must not discard earlier dirty-field intent. An unchanged field is distinct from a dirty field whose value is null/empty. Extension clear values do not change the catalog's existing field-lock/nonempty scan-merge policy.

## Native projections

ComicInfo uses the 2.1 draft field set. Project title/summary to `Title`/`Summary`, date to `Year`/`Month`/`Day`, role-free Authors to comma-separated `Writer`, Tags to `Tags`, Characters to `Characters`, and known languages to BCP-47 codes in `LanguageISO`. Preserve other creator-role fields. R18 can project to `Adults Only 18+`; `safe` does not certify a child age band and projects to `Unknown`, with its exact classification in the extension. Parodies have no equivalent Series/StoryArc meaning and stay in the extension. The extension is a namespaced `Metadata` element whose escaped text is the JSON envelope; extended documents are not claimed to validate against the unmodified ComicInfo XSD.

EPUB projects title, creator, description, publication date, language and subject through the package's declared-version-appropriate Dublin Core metadata. Tags may project as subjects, but exact Tags and otherwise unrepresentable Parodies/Characters/rating stay in the extension. Keep publication date distinct from EPUB modification time. Preserve package identifiers and refinements. EPUB 2 stores the escaped JSON envelope in a `meta` content attribute whose name is the extension namespace. EPUB 3 declares `hl` in the package prefix vocabulary and uses `meta property="hl:metadata"`; it updates the document's `dcterms:modified`. Signed/protected packages and unsafe removal of refined metadata are rejected.

PDF projects to document XMP `dc:title`, ordered `dc:creator`, `dc:description`, `dc:subject` and `dc:language` where applicable. Do not relabel publication date as file creation time. Other fields use the application extension in a namespaced `hl:Metadata` property. XMP is authoritative on read; changed title/description/authors/tags also update the overlapping legacy Info Title/Subject/Author/Keywords values as UTF-16 strings. Incremental output retains the source bytes as its prefix; the page tree and decoded content are verified before replacement. Signed/encrypted documents and PDF/A requiring unsupported conformance handling are rejected. Unrelated XMP properties and Info keys remain intact.

## Current capabilities

Local directories, ZIP/CBZ, 7Z/CB7, EPUB 2/3 and ordinary PDF are implemented. Native RAR/CBR writing remains unavailable; see [RAR feasibility](rar-metadata-writing.md). Windows host tests do not constitute Android/iOS/macOS/Linux device validation. The feature is disabled per Library until the user affirmatively enables original-file changes.

Canonical language codes are Chinese `zh`, Japanese `ja`, English `en`, Korean `ko`, Spanish `es`. `Other` and unrecognized languages require exact extension preservation rather than fabricated BCP-47 tags. Standard date projections may be less precise than epoch milliseconds; the extension carries the exact value. XML carriers escape XML-special text, including JSON characters that become markup. Existing unknown metadata and namespaces remain intact.

## Verification

Public Rust use cases with real temporary Resources and the shared database harness own end-to-end correctness. Codec tests check lossless field intent and format-specific compatibility. Dart tests check presentation and adapters rather than repeat business flows. Source-writing acceptance includes retained page/content bytes/order, original preservation on failure, interruption recovery, revision races and resource observation/Reader reconciliation.
