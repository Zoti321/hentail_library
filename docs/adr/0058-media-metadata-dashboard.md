# ADR-0058: Media metadata dashboard

## Status

Accepted. Supersedes the Media page inspection/filtering scope in ADR-0057; Resource metadata embedding policies remain unchanged.

## Context

The initial Media page repeated the Comic catalog as a paginated per-resource status list. The user needs an overview of file metadata writing and explicitly defers individual Comic details. Its timed query dependency also replaced already visible content with loading UI.

## Decision

Deliver a Home-linked dashboard containing aggregate visible Local Resource counts, automatic writing state counts and per-Library opt-in settings. Defer resource lists, state filters, pagination, metadata details and editing from this page. Retain existing Comic editing elsewhere.

Rust queries aggregate counters without loading individual Comic metadata. Healthy-mode visibility and trash exclusion apply to Resource counts; Library totals include empty Local libraries. A disabled Library classifies its Resources as disabled regardless of retained job state.

Use the existing application page scaffold, theme and Settings components with M3E filled cards and expressive segmented lists. Background refresh retains content and scroll position; failed refresh retains last counts with visible feedback. Library opt-in state does not reload on every job status notification. Overview polling pauses while the application is inactive.

## References

- ADR-0053, ADR-0057.
- [Material cards](https://m3.material.io/components/cards/overview), [expressive lists](https://m3.material.io/components/lists/overview).
- [Google Reply adaptive design sample](https://github.com/android/compose-samples/tree/main/Reply).
